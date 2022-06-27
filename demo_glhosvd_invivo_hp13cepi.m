clearvars; clc; close all
addpath(genpath('./GL_HOSVD'));
addpath(genpath('./Imagescn'));
addpath(genpath('./data'));

load invivo_hp13c_EPI;
% coil-combined 2D EPI data
pyr_dyn = hp13c(:,:,:,:,1);
lac_dyn = hp13c(:,:,:,:,2);
bic_dyn = hp13c(:,:,:,:,3);
X = size(pyr_dyn,2); Y=size(pyr_dyn,1); Z=size(pyr_dyn,3); T=size(pyr_dyn,4);
numFreqs  =3;

%% GL-HOSVD denoising
% Denoising parameters
kglobal = 0.4; klocal = 0.8;
patchsize = 5; 
step = 2; 
sw = 6; % radius of search window
[denoised, raw] = glhosvd_InVivo(hp13c, bmask, kglobal, klocal, patchsize, step, sw);
results.denoised = denoised;
results.raw = raw;

slice = 4;
zf = 4;
figure('Name', ['Pyruvate: slice-' num2str(slice)]);
tmp = imresize((squeeze(raw.pyr.data(:,:,slice,:))),zf);
tmp(:,:,21:40) = imresize((squeeze(denoised.pyr.data(:,:,slice,:))),zf);
imagescn(tmp,[0 round(max(tmp(:)),1)/5],[2 20]);    colormap hot
maxvalue(1,1) = round(max(tmp(:)),1)/5;
figure('Name', ['Lactate: slice-' num2str(slice)]);
tmp = imresize((squeeze(raw.lac.data(:,:,slice,:))),zf);
tmp(:,:,21:40) = imresize((squeeze(denoised.lac.data(:,:,slice,:))),zf);
imagescn(tmp,[0 round(max(tmp(:)),1)],[2 20]);    colormap hot
maxvalue(2,1) = round(max(tmp(:)),1);
figure('Name', ['Bicarbonate: slice-' num2str(slice)]);
tmp = imresize((squeeze(raw.bic.data(:,:,slice,:))),zf);
tmp(:,:,21:40) = imresize((squeeze(denoised.bic.data(:,:,slice,:))),zf);
imagescn(tmp,[0 round(max(tmp(:)),1)],[2 20]);    colormap hot
maxvalue(3,1) = round(max(tmp(:)),1);

%% Kinetic analysis
% flip angle
pyr_flip = 20; % flip angle pyruvate (deg)
lac_flip = 30; % flip angle lactate (deg)
bic_flip = 30; % flip angle bicarbonate (deg)
flips = [pyr_flip/180*pi*ones(1,T); lac_flip/180*pi*ones(1,T); bic_flip/180*pi*ones(1,T)];
% acquisition parameters
t_offset = 2; % delay (s)
TR = 3; %temporal resolution (s)

% fitting parameters 
params_est.kPL = 0.015; 
params_est.kPB = 0.0075; 
params_est.R1P = 1/30; 
params_est.R1L = 1/25; 
params_est.R1B = 1/25;
% fixed parameters
params_fix.a = 0;  
name{1} = 'raw'; name{2} = 'denoised'; 
for k = 1:2
      tmp = eval(name{k});
      results.(name{k}).traces = cell(Y,X,Z);
      results.(name{k}).kpl_fit = zeros(Y,X,Z);
      results.(name{k}).kpb_fit = zeros(Y,X,Z);
      results.(name{k}).kpl_fit_err = zeros(Y,X,Z);
      results.(name{k}).kpb_fit_err = zeros(Y,X,Z);
for kk=1:Z
        for ii = 1:Y
           for jj = 1:X
                    met1 = double(squeeze(tmp.pyr.data(ii,jj,kk,:)));
                    met2 = double(squeeze(tmp.lac.data(ii,jj,kk,:)));
                    met3 = double(squeeze(tmp.bic.data(ii,jj,kk,:)));           
                    S_data = [met1';met2';met3'];
                    if bmask(ii,jj,kk) == 1
                   [params_fit, Sfit, ufit, error_metrics]  = ...
                    fit_pyr_kinetics(S_data, TR, flips, params_fix, params_est,[], 0); % kPL model alone
                    results.(name{k}).traces{ii,jj,kk} = [squeeze(Sfit); ufit];
                    results.(name{k}).kpl_fit(ii,jj,kk) = params_fit.kPL;                
                    results.(name{k}).kpb_fit(ii,jj,kk) = params_fit.kPB;                
                    results.(name{k}).kpl_fit_err(ii, jj, kk) = error_metrics.kPL.err; %95% confidence interval
                    results.(name{k}).kpb_fit_err(ii, jj, kk) =  error_metrics.kPB.err; %95% confidence interval        
                    else
                    end
            end
        end
end
end

%% kPL & kPB: Apply SNR and error critera
snr_threshold = 3;
err_threshold = 0.3; % requirement: stdev/kpx < threshold 
for k=1:2
    tmp = eval(['results.' name{k}]); 
    % SNR
    SNRmask_kpl = (tmp.pyr.aucsnr > snr_threshold).* (tmp.lac.aucsnr > snr_threshold);
    SNRmask_kpb = (tmp.pyr.aucsnr > snr_threshold).* (tmp.bic.aucsnr > snr_threshold);
    % error criteria
    Errmask_kpl = (tmp.kpl_fit_err/2/1.96 < err_threshold * tmp.kpl_fit);
    Errmask_kpb =   (tmp.kpb_fit_err/2/1.96 < err_threshold * tmp.kpb_fit);
    maxlimit = 0.1; minlimit = 0.0005;
    kplmask = (tmp.kpl_fit > minlimit & tmp.kpl_fit < maxlimit) .*Errmask_kpl;
    kpbmask =(tmp.kpb_fit > minlimit & tmp.kpb_fit < maxlimit) .*Errmask_kpb;
    % Final kpl and kpb maps
    results.(name{k}).masked_kpl_fit = tmp.kpl_fit .* SNRmask_kpl .*kplmask .*bmask;
    results.(name{k}).masked_kpb_fit = tmp.kpb_fit .* SNRmask_kpb .*kpbmask .*bmask;
end

%% Results
display(['raw kPL (/s) = ' num2str(mean(results.raw.masked_kpl_fit(results.raw.masked_kpl_fit>0))) '+/-' ,...
    num2str(std(results.raw.masked_kpl_fit(results.raw.masked_kpl_fit>0)))]);
display(['denoised kPL (/s) = ' num2str(mean(results.denoised.masked_kpl_fit(results.denoised.masked_kpl_fit>0))) '+/-' ,...
    num2str(std(results.denoised.masked_kpl_fit(results.denoised.masked_kpl_fit>0)))]);
display(['raw kPB (/s) = ' num2str(mean(results.raw.masked_kpb_fit(results.raw.masked_kpb_fit>0))) '+/-' ,...
    num2str(std(results.raw.masked_kpb_fit(results.raw.masked_kpb_fit>0)))]);
display(['denoised kPB (/s) = ' num2str(mean(results.denoised.masked_kpb_fit(results.denoised.masked_kpb_fit>0))) '+/-' ,...
    num2str(std(results.denoised.masked_kpb_fit(results.denoised.masked_kpb_fit>0)))]);

nkpl = [sum(sum(sum(results.raw.masked_kpl_fit>0))) sum(sum(sum(results.denoised.masked_kpl_fit>0)))];
nkpb = [sum(sum(sum(results.raw.masked_kpb_fit>0))) sum(sum(sum(results.denoised.masked_kpb_fit>0)))];
display(['# of voxels with kPL: raw/denoised = ' num2str(nkpl(1)) '/' num2str(nkpl(2))]);
display(['# of voxels with kPB: raw/denoised = ' num2str(nkpb(1)) '/' num2str(nkpb(2))]);
%
figure('Name', 'kPL map: raw (top) vs denoised (bottom)');
tmp = results.raw.masked_kpl_fit;
tmp(:,:,Z+1:2*Z) = results.denoised.masked_kpl_fit;
imagescn(tmp, [0 0.04], [2 8]); colormap default; 
figure('Name', 'kPB map: raw (top) vs denoised (bottom)');
tmp = results.raw.masked_kpb_fit;
tmp(:,:,Z+1:2*Z) = results.denoised.masked_kpb_fit;
imagescn(tmp, [0 0.01], [2 8]); colormap default; 
