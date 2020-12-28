function [params_fit, Sfit, ufit, objective_val, err_metrics, err_metrics2] = fit_pyr_kinetics_error(S, TR, flips, params_fixed, params_est, noise_level, plot_flag)
% fit_pyr_kinetics - Kinetic model fitting function for HP 13C MRI.
%
% Fits product signals, assuming origination from a single substrate
% In other words, pyruvate to lactate, bicarbonate and alanine.
% An input-less method is used, eliminating
% need to make any assumptions about the input function.
% This uses the following assumptions:
%   - uni-directional conversion from substrate to metabolic products (i.e.
%   pyruvate to lactate)
% It also allows for fixing of parameters. Based on simulations, our
% current recommendation is to fix pyruvate T1, as it doesn't impact kPX substantially.
%
% [params_fit, Sfit, ufit, objective_val] = fit_pyr_kinetics(S, TR, flips, params_fixed, params_est, noise_level, plot_flag)
%
% All params_* values are structures, including possible fields of 'kPL', 'kPB', 'kPA', (1/s),
% 'R1P', 'R1L', 'R1B', 'R1A' (1/s).
% INPUTS
%	S - signal dynamics [voxels, # of metabolites, # of time points]
%		Substrate (e.g. Pyruvate) should be the first metabolite, followed by each product
%   TR - repetition time per time point
%	flips - all flip angles [# of metabolites, # of time points x # of phase encodes]
%	params_fixed - structure of fixed parameters and values (1/s).  parameters not in
%       this structure will be fit
%   params_est (optional) - structure of estimated values for fit parameters pyruvate to metabolites conversion rate initial guess (1/s)
%       Also can include upper and lower bounds on parameters as *_lb and
%       *_ub (e.g. R1L_lb, R1L_ub)
%   noise_level (optional) - estimate standard deviation of noise in data
%       to use maximum likelihood fit of magnitude data (with Rician noise
%       distribution)
%   plot_flag (optional) - plot fits
% OUTPUTS
%   params_fit - structure of fit parameters
%   Sfit - fit curves
%   ufit - derived input function (unitless)
%   objective_val - measure of fit error
%
% EXAMPLES - see test_fit_HP_kinetics.m
%
% Authors: John Maidens,  Peder E. Z. Larson
%
% (c)2015-2018 The Regents of the University of California. All Rights
% Reserved.


size_S = size(S);  ndimsx = length(size_S)-2;
Nt = size_S(end); t = [0:Nt-1]*TR;
Nx = size_S(1:ndimsx);
Nmets = size_S(end-1);
if isempty(Nx)
    Nx = 1;
end

err_all = {'ub', 'lb', 'err', 'Rsq', 'CHIsq'};
params_all = {'kPL', 'kPB', 'kPA', ...
    'R1P', 'R1L', 'R1A', 'R1B', ...
    'S0_L', 'S0_B', 'S0_A', ...
    'Rinj', 'Tarrival', 'Tbolus'};
params_default_est = [0.01, 0.01, 0.01, ...
    1/30, 1/25, 1/25, 1/15, ...
    0, 0, 0, ...
    0.1, 0, 8];
params_default_lb = [-Inf, -Inf, -Inf, ...
    1/50, 1/50, 1/50, 1/150, ...
    -Inf, -Inf, -Inf, ...
    0, -30, 0];
params_default_ub = [Inf, Inf, Inf, ...
    1/10, 1/20, 1/10, 1/30 , ...
    Inf, Inf, Inf, ...
    Inf 30 Inf];

if nargin < 5 || isempty(params_fixed)
    params_fixed = struct([]);
end

if nargin < 6 || isempty(params_est)
    params_est = struct([]);
end

% Supports up to 3 metabolic products (e.g. alanine, lactate, bicarb)
switch Nmets
    case 2 % assume pyruvate & lactate
        params_fixed.kPA = 0;  params_fixed.S0_A = 0;  params_fixed.R1A = 1;
        params_fixed.kPB = 0;  params_fixed.S0_B = 0;  params_fixed.R1B = 1;
        
    case 3 % assume pyruvate & lactate & bicarbonate
        params_fixed.kPA = 0;   params_fixed.S0_A = 0;  params_fixed.R1A = 1;
end


I_params_est = [];
for n = 1:length(params_all)
    if ~isfield(params_fixed, params_all(n))
        I_params_est = [I_params_est, n];
    end
end
Nparams_to_fit = length(I_params_est);

for n = 1:Nparams_to_fit
    param_name = params_all{I_params_est(n)};
    if isfield(params_est, param_name)
        params_est_vec(n) = params_est.(param_name);
    else
        params_est_vec(n) = params_default_est(I_params_est(n));
    end
    if isfield(params_est, [param_name '_lb'])
        params_lb(n) = params_est.([param_name '_lb']);
    else
        params_lb(n) = params_default_lb(I_params_est(n));
    end
    if isfield(params_est, [param_name '_ub'])
        params_ub(n) = params_est.([param_name '_ub']);
    else
        params_ub(n) = params_default_ub(I_params_est(n));
    end
end


if nargin < 6 || isempty(noise_level)
    % no noise level provided, so use least-squares fit (best for Gaussian
    % zero-mean noise)
    fit_method = 'ls';
else
    % otherwise use maximum likelihood (good for Rician noise from
    % magnitudes)
    fit_method = 'ml';
end

if nargin < 7
    plot_flag = 0;
end

if plot_flag
    disp('==== Computing parameter map ====')
end

Sreshape = reshape(S, [prod(Nx), Nmets, Nt]);  % put all spatial locations in first dimension
if Nmets < 4
    Sreshape = cat(2, Sreshape, zeros([prod(Nx) 4-Nmets, Nt]));  % add zero data for unused metabolites
    flips = cat(1, flips, ones([4-Nmets, size(flips,2)]));
end
%                 sigma2 = nlparci(params_fit_vec(i,2),resid(2:2:end),'jacobi

[Sscale, Mzscale] = flips_scaling_factors(flips, Nt);

params_fit_vec = zeros([prod(Nx),Nparams_to_fit]);  objective_val = zeros([1,prod(Nx)]);
Sfit = zeros([prod(Nx),Nmets-1,Nt]); ufit = zeros([prod(Nx),Nt]);
err_vec=zeros([prod(Nx),5]);
err_vec2=zeros([prod(Nx),5]);

for i=1:size(Sreshape, 1)
    if prod(Nx) > 1 && plot_flag
        disp([num2str( floor(100*(i-1)/size(S, 1)) ) '% complete'])
    end
    % observed magnetization (Mxy)
    Mxy = reshape(Sreshape(i, :, :), [4, Nt]);
    
    if any(Mxy(:) ~= 0)
        
        % estimate state magnetization (MZ) based on scaling from RF pulses  
        Mz = Mxy./Sscale;
      
        % fit to data
        options = optimoptions(@fminunc,'Display','none','Algorithm','quasi-newton');
        lsq_opts = optimset('Display','none','MaxIter', 500, 'MaxFunEvals', 500);
        
        switch(fit_method)
            case 'ls'
                obj = @(var) difference_inputless(var, params_fixed, TR, Mzscale, Sscale, Mz, Nmets) ;  % perform least-squares in signal domain
                [params_fit_vec(i,:),objective_val(i),resid,~,~,~,J] = lsqnonlin(obj, params_est_vec, params_lb, params_ub, lsq_opts);
                
                tmp = J(:,1);
                         
                % extract 95% confidence interval on lactate timecourse
                sigma = nlparci(params_fit_vec(i,1:2),resid,'jacobian',J(:,1:2));
               
            
            case 'ml'
                obj = @(var) negative_log_likelihood_rician_inputless(var, params_fixed, TR, Mzscale, Mz, noise_level.*(Sscale).^2, Nmets);
                [params_fit_vec(i,:), objective_val(i)] = fminunc(obj, params_est_vec, options);
                
        end
        
       
        
        [Mzfit, ufit(i,:)] = trajectories_inputless(params_fit_vec(i,:), params_fixed, TR,  Mzscale, Mz(1,:));
        
        Sfit(i,:,:) = Mzfit(2:Nmets,:)  .* Sscale(2:Nmets, :);
        ufit(i,:) = ufit(i,:)  .* Sscale(1, :);
        
        % export goodness of fit parameters (ub, lb, total error, R^2, chi^2)
        err_vec(i,1)=sigma(1,2);
        err_vec(i,2)=sigma(1,1);
        err_vec(i,3)=sigma(1,2)-sigma(1,1);
        err_vec(i,4)=1-mean((S(i,2,:)-Sfit(i,2,:)).^2./S(i,2,:).^2);
        err_vec(i,5)=sum((S(i,2,:)-Sfit(i,1,:)).^2);
        
        % export goodness of fit parameters (ub, lb, total error, R^2, chi^2)
        err_vec2(i,1)=sigma(2,2);
        err_vec2(i,2)=sigma(2,1);
        err_vec2(i,3)=sigma(2,2)-sigma(2,1);
        err_vec2(i,4)=1-mean((S(i,2,:)-Sfit(i,2,:)).^2./S(i,2,:).^2);
        err_vec2(i,5)=sum((S(i,2,:)-Sfit(i,1,:)).^2);
        
        
        if plot_flag
            % plot of fit for debugging
            figure(99)
            subplot(2,1,1)
            plot(t, Mz, t, Mzfit,'--', t, ufit(i,:)./ Sscale(1, :), 'k:')
            xlabel('time (s)')
            ylabel('state magnetization (au)')
            subplot(2,1,2)
            plot(t, Mxy, t, squeeze(Sfit(i,:,:)),'--', t, ufit(i,:), 'k:')
            xlabel('time (s)')
            ylabel('signal (au)')
            title(num2str(params_fit_vec(i,:),2)) % don't display L0_start value
            %            legend('pyruvate', 'lactate', 'lactate fit', 'input estimate')
            drawnow, pause(0.5)
        end
    end
end


params_fit = struct([]);
nfit = 0;
for n = 1:length(params_all)-1  % don't output L0_start
    if ~isfield(params_fixed, params_all(n))
        nfit = nfit+1;
        params_fit(1).(params_all{n})= params_fit_vec(:,nfit);
    end
end

if length(Nx) > 1
    for n = 1:Nparams_to_fit-1 % don't output L0_start
        param_name = params_all{I_params_est(n)};
        params_fit.(param_name) = reshape(params_fit.(param_name), Nx);
    end
    
    
    Sfit = reshape(Sfit, [Nx, Nmets-1, Nt]);
    ufit = reshape(ufit, [Nx, Nt]);
    objective_val = reshape(objective_val, Nx);
    if plot_flag
        disp('100 % complete')
    end
end

%error metrics - kPL
err_metrics=struct([]);
nfit=0;
for n = 1:length(err_all)
    nfit=nfit+1;
    err_metrics(1).(err_all{n})= err_vec(:,nfit);
end

if length(Nx) > 1
    for n = 1:length(err_all)
        param_name = err_all{(n)};
        err_metrics.(param_name) = reshape(err_metrics.(param_name), [12,12,16]);
    end
end
%
%error metrics - kPB
err_metrics2=struct([]);
nfit=0;
for n = 1:length(err_all)
    nfit=nfit+1;
    err_metrics2(1).(err_all{n})= err_vec2(:,nfit);
end

if length(Nx) > 1
    for n = 1:length(err_all)
        param_name = err_all{(n)};
        err_metrics2.(param_name) = reshape(err_metrics2.(param_name), [12,12,16]);
    end
end
%}


end

function diff_products = difference_inputless(params_fit, params_fixed, TR, Mzscale, Sscale, Mz, Nmets)
Mzfit = trajectories_inputless(params_fit, params_fixed, TR,  Mzscale, Mz(1,:)) ;
temp_diff = (Mz - Mzfit) .* Sscale;
diff_products = temp_diff(2:Nmets,:);
diff_products = diff_products(:);
end

function [ l1 ] = negative_log_likelihood_rician_inputless(params_fit, params_fixed, TR, Mzscale, Mz, noise_level, Nmets)
%FUNCTION NEGATIVE_LOG_LIKELIHOOD_RICIAN Computes log likelihood for
%    compartmental model with Rician noise
% noise level is scaled for state magnetization (Mz) domain

N = size(Mzscale,2);

% compute trajectory of the model with parameter values
Mzfit = trajectories_inputless(params_fit, params_fixed, TR,  Mzscale, Mz(1,:)) ;

% compute negative log likelihood
l1 = 0;
for t = 1:N
    for k = 2:Nmets
        l1 = l1 - (...
            log(Mz(k, t)) - log(noise_level(k,t)) ...
            - (Mz(k, t)^2 + Mzfit(k, t)^2)/(2*noise_level(k,t)) ...
            + Mz(k, t)*Mzfit(k, t)/noise_level(k,t) ...
            + log(besseli(0, Mz(k, t)*Mzfit(k, t)/noise_level(k,t), 1))...
            );
    end
end
end

function [Mz_all, u] = trajectories_inputless( params_fit, params_fixed, TR, Mzscale , Mz_pyr )
% Compute product magnetizations using a uni-directional two-site model
% Uses substrate magnetization measurements, estimated relaxation and
% conversion rates

Nmets = size(Mzscale,1); N = size(Mzscale,2);
Mz_all = zeros(Nmets, N);
u = zeros(1,N);

params_all = {'kPL', 'kPB', 'kPA', ...
    'R1P', 'R1L', 'R1A', 'R1B', ...
    'S0_L', 'S0_B', 'S0_A'};

nfit = 0;
for n = 1:length(params_all)
    if isfield(params_fixed, params_all(n))
        eval([params_all{n} '= params_fixed.(params_all{n});']);
    else
        nfit = nfit+1;
        eval([params_all{n} '= params_fit(nfit);']);
    end
end

Mz_all(1,:) = Mz_pyr;
Mz_all(2,1) = S0_L;
Mz_all(3,1) = S0_B;
Mz_all(4,1) = S0_A;

A = [-R1P-kPL-kPB-kPA, 0, 0, 0
    +kPL, -R1L, 0, 0
    +kPB, 0, -R1B, 0
    +kPA, 0, 0, -R1A];

for It=1:N-1
    
    Mz_init = Mz_all(:,It) .* Mzscale(:, It);
    
    % estimate input, assuming this is constant during TR interval
    % This calculation could be improved for noise stability?
    u(It) = ( Mz_pyr(It+1) - Mz_init(1)*exp((- R1P - kPL - kPB - kPA)*TR) ) * (R1P + kPL + kPB + kPA) / (1 - exp((- R1P - kPL - kPB - kPA)*TR));
    
    xstar = - inv(A)*[u(It),0,0,0].';
    
    % solve next time point under assumption of constant input during TR
    Mz_all(:,It+1) = xstar + expm(A*TR) * (Mz_init - xstar);
    
    
end

end
