clearvars; clc; close all
addpath(genpath('./GL_HOSVD'));
addpath(genpath('./kinetic_fitting'));
addpath(genpath('./Imagescn'));
addpath(genpath('./data'));

%% Load metabolic phantom (ground truth)
load 'simulation_PyrLacDynamics.mat';
tpts = size(pyr_dyn,4); % #timepoints
nslice = size(pyr_dyn,3); % slice
x_dim = size(pyr_dyn,2); % matrix x-dim 
y_dim = size(pyr_dyn,1); % matrix y-dim
matrix_size = size(pyr_dyn);
brainmask = kPL>0;

%% Add noise to pyr and lac
stdev = 0.3; % Noise characteristics
rnd_noise = normrnd(0, stdev,matrix_size); % Generate random noise
pyr_noisy = pyr_dyn + rnd_noise;
rnd_noise = normrnd(0, stdev, matrix_size); % Generate random noise
lac_noisy = lac_dyn + rnd_noise;

%% Denoising
% Denoising w/ GL-HOSVD
kglobal = 0.4; klocal = 0.8;
patchsize = 5; 
step = 2; 
sw = 6; % radius of search window
%
pyr_dnGL = zeros(matrix_size);
lac_dnGL = zeros(matrix_size);
for i =1:nslice
        tmp = squeeze(pyr_noisy(:,:,i,:));
        pyr_dnGL(:,:,i,:) =glhosvd_flexible(tmp, stdev, kglobal, klocal, patchsize, step, sw);
        tmp = squeeze(lac_noisy(:,:,i,:));
        lac_dnGL(:,:,i,:) =glhosvd_flexible(tmp, stdev, kglobal, klocal, patchsize, step, sw);
end

% Show images
display_slice = 3;
figure('Name', 'True Lac'),
lac = squeeze(lac_dyn(:,:,display_slice,:));
imagescn(lac, [0 max(lac(:))*1.2]); colormap default
figure('Name', 'Noisy Lac'),
lac_noise_added = squeeze(lac_noisy(:,:,display_slice,:));
imagescn(lac_noise_added, [0 max(lac(:))*1.2]); colormap default
figure('Name', 'Lac GL-HOSVD denoising'),
lac_GLHOSVD = squeeze(lac_dnGL(:,:,display_slice,:));
imagescn(lac_GLHOSVD, [0 max(lac(:))*1.2]); colormap default

%% Kinetic analysis
% flip angle
pa_flip = 20; % flip angle pyruvate (deg)
lac_flip = 30; % flip angle lactate (deg)
flips = [pa_flip/180*pi*ones(1,tpts); lac_flip/180*pi*ones(1,tpts)];
% acquisition parameters
t_offset = 2; % delay (s)
TR = 3; %temporal resolution (s)
% fixed parameters
params_fix.R1P = 1/30; 
params_fix.R1L = 1/25; 
% fitting parameters 
params_est.kPL = 0.017; 

% Voxel-by-voxel kPL fitting - for a single slice (display_slice)
name{1} = 'noisy'; name{2} = 'dnGL'; 
for k =1:2
       pyr_data = eval(['pyr_' name{k}]); 
       lac_data = eval(['lac_' name{k}]);      
        for ii = 1:y_dim
           for jj = 1:x_dim
                met1 = double(squeeze(pyr_data(ii,jj,display_slice,:)));
                met2 = double(squeeze(lac_data(ii,jj,display_slice,:)));
                S_data = [met1';met2'];
                [params_fit, Sfit_lac, ufit, error_metrics]  = ...
                fit_pyr_kinetics(S_data, TR, flips, params_fix, params_est,[], 0); % kPL model alone
                traces{ii,jj} = [squeeze(Sfit_lac)'; ufit];
                kpl_fit(ii,jj) = params_fit.kPL;
                kpl_fit_err(ii,jj) = error_metrics.kPL.err; %95% confidence interval
            end
        end
        results.(name{k}).kPLfit = kpl_fit .* brainmask(:,:,display_slice) ;
        results.(name{k}).traces = traces ;
        results.(name{k}).kPL_err = kpl_fit_err .* brainmask(:,:,display_slice) ;
end

%%  results
figure,
subplot(131)
imagesc(squeeze(kPL(:,:,display_slice)), [0 0.02]); colormap default; colorbar; axis off
title('Ground truth kPL');
subplot(132)
imagesc(results.noisy.kPLfit, [0 0.02]); colormap default; colorbar; axis off
title('Noise-added kPL');
subplot(133)
imagesc(results.dnGL.kPLfit, [0 0.02]); colormap default; colorbar; axis off
title('GLHOSVD denoised kPL');
