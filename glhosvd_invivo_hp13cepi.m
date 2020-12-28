clearvars; close all

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

raw.traces = cell(Y,X,Z);
raw.kpl_fit = zeros(Y,X,Z);  
raw.kpl_fit_err = zeros(Y,X,Z);  
raw.kpb_fit = zeros(Y,X,Z);  
raw.kpb_fit_err = zeros(Y,X,Z);  
for kk=1:Z
        for ii = 1:Y
           for jj = 1:X
                    met1 = double(squeeze(raw.pyr.data(ii,jj,kk,:)));
                    met2 = double(squeeze(raw.lac.data(ii,jj,kk,:)));
                    met3 = double(squeeze(raw.bic.data(ii,jj,kk,:)));           
                    S_data = [met1';met2';met3'];
                    if bmask(ii,jj,kk) == 1
                    [params_fit, Sfit, ufit, ~, error_kpl, error_kpb]  = ...
                    pyr_kinetics_fitting(S_data, TR, flips, params_fix, params_est,[], 0); % kPL model alone
                    raw.traces{ii,jj,kk} = [squeeze(Sfit); ufit];
                    raw.kpl_fit(ii,jj,kk) = params_fit.kPL;                
                    raw.kpb_fit(ii,jj,kk) = params_fit.kPB;                
                    raw.kpl_fit_err(ii, jj, kk) = error_kpl.err; %95% confidence interval
                    raw.kpb_fit_err(ii, jj, kk) = error_kpb.err; %95% confidence interval        
                    else
                    end
            end
        end
end
denoised.traces = cell(Y,X,Z);
denoised.kpl_fit = zeros(Y,X,Z);  
denoised.kpl_fit_err = zeros(Y,X,Z);  
denoised.kpb_fit = zeros(Y,X,Z);  
denoised.kpb_fit_err = zeros(Y,X,Z);  
for kk=1:Z
        for ii = 1:Y
           for jj = 1:X
                    met1 = double(squeeze(denoised.pyr.data(ii,jj,kk,:)));
                    met2 = double(squeeze(denoised.lac.data(ii,jj,kk,:)));
                    met3 = double(squeeze(denoised.bic.data(ii,jj,kk,:)));           
                    S_data = [met1';met2';met3'];
                    if bmask(ii,jj,kk) == 1
                    [params_fit, Sfit, ufit, ~, error_kpl, error_kpb]  = ...
                    pyr_kinetics_fitting(S_data, TR, flips, params_fix, params_est,[], 0); % kPL model alone
                    denoised.traces{ii,jj,kk} = [squeeze(Sfit); ufit];
                    denoised.kpl_fit(ii,jj,kk) = params_fit.kPL;                
                    denoised.kpb_fit(ii,jj,kk) = params_fit.kPB;                
                    denoised.kpl_fit_err(ii, jj, kk) = error_kpl.err; %95% confidence interval
                    denoised.kpb_fit_err(ii, jj, kk) = error_kpb.err; %95% confidence interval        
                    else
                    end
            end
        end
end

%% Apply SNR and error critera
snr_threshold = 3;
err_threshold = 0.3; % requirement: stdev/kpx < threshold 
% raw
% SNR
SNRmask_kpl = (raw.pyr.aucsnr > snr_threshold).* (raw.lac.aucsnr > snr_threshold);
SNRmask_kpb = (raw.pyr.aucsnr > snr_threshold).* (raw.bic.aucsnr > snr_threshold);
% error criteria
Errmask_kpl = (raw.kpl_fit_err/2/1.96 < err_threshold);
Errmask_kpb =   (raw.kpb_fit_err/2/1.96 < err_threshold);
maxlimit = 0.1; minlimit = 0.0005;
kplmask = (raw.kpl_fit > minlimit & raw.kpl_fit < maxlimit) .*Errmask_kpl;
kpbmask =(raw.kpb_fit > minlimit & raw.kpb_fit < maxlimit) .*Errmask_kpb;
% Final kpl and kpb maps
raw.masked_kpl_fit = kpl_fit .* SNRmask_kpl .*kplmask .*bmask;
raw.masked_kpb_fit = kpb_fit .* SNRmask_kpb .*kpbmask .*bmask;
mean(raw.masked_kpl_fit(raw.masked_kpl_fit>0))
mean(raw.masked_kpb_fit (raw.masked_kpb_fit >0))

% Denoised
% SNR
SNRmask_kpl = (denoised.pyr.aucsnr > snr_threshold).* (denoised.lac.aucsnr > snr_threshold);
SNRmask_kpb = (denoised.pyr.aucsnr > snr_threshold).* (denoised.bic.aucsnr > snr_threshold);
% error criteria
Errmask_kpl = (denoised.kpl_fit_err/2/1.96 < err_threshold);
Errmask_kpb =   (denoised.kpb_fit_err/2/1.96 < err_threshold);
maxlimit = 0.1; minlimit = 0.0005;
kplmask = (denoised.kpl_fit > minlimit & denoised.kpl_fit < maxlimit) .*Errmask_kpl;
kpbmask =(denoised.kpb_fit > minlimit & denoised.kpb_fit < maxlimit) .*Errmask_kpb;
% Final kpl and kpb maps
denoised.masked_kpl_fit = kpl_fit .* SNRmask_kpl .*kplmask .*bmask;
denoised.masked_kpb_fit = kpb_fit .* SNRmask_kpb .*kpbmask .*bmask;
mean(denoised.masked_kpl_fit(denoised.masked_kpl_fit>0))
mean(denoised.masked_kpb_fit (denoised.masked_kpb_fit >0))
%
figure,
imagescn(raw.masked_kpb_fit, [0 0.01]); colormap default; colorbar;
figure,
imagescn(denoised.masked_kpb_fit, [0 0.01]); colormap default; colorbar;

