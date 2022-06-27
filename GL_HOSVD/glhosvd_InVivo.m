function [denoised, raw] = glhosvd_InVivo(data, bmask, kglobal, klocal, patchsize, step, sw)
% Patch size variation
addpath('./gl-hosvd/');

% data: [x, y, z, t, Met] Met 1: pyr; Met 2: lac

Nt = size(data,4);
Nx = size(data,2); Ny = size(data,1); Nz = size(data,3);

% noise mask
% create mask for noise estimation that removes first and last columns of data
noise_mask = zeros(Nx, Ny, Nz);
for slice = 1:Nz
    noise_mask(1:Ny,1,slice) = 1;
    noise_mask(1:Ny,Nx,slice) = 1;
end    
noise_mask(noise_mask==1)=2;
noise_mask(noise_mask<1)=1;
noise_mask(noise_mask>1)=0;
% noise_mask = noise_mask.*(1-bmask);
noise_mask(2:Ny-1,4:Nx-3,:) = 0;

%% (1) Pyruvate
% ---- noise estimation ---- %
im = data(:,:,:,:,1);
pyr_noise = im(:,:,:,Nt) .* noise_mask; % use the last timeframe scans (make sure that no HP signal is left)
tmp = pyr_noise(pyr_noise~=0);
raw.pyr.noise = [mean(tmp); std(tmp)];
im = im - mean(tmp);
raw.pyr.snr = max(max(max(max(im .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
raw.pyr.aucsnr = sum(im,4)/std(tmp)/sqrt(Nt); % not removing the background
raw.pyr.data = im;
% ---- start image denoising---- %
    for s=1:Nz
        ims(:,:,s,:) =glhosvd_flexible(squeeze(im(:,:,s,:)),std(tmp), kglobal, klocal, patchsize, step, sw);  
    end
    denoised.pyr.data = ims;
    pyr_noise = ims(:,:,:,20) .* noise_mask;
    tmp = pyr_noise(pyr_noise~=0);
    denoised.pyr.noise = [mean(tmp); std(tmp)];
    denoised.pyr.snr = max(max(max(max(ims .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
    denoised.pyr.aucsnr = sum(ims,4)/std(tmp)/sqrt(Nt);

% (2) Lactate
% ---- noise estimation ---- %
clear im
im = data(:,:,:,:,2);
lac_noise = im(:,:,:,1) .* noise_mask; % use the first timeframe scans (make sure that no HP signal appears in the first scans)
tmp = lac_noise(lac_noise~=0);
raw.lac.noise = [mean(tmp); std(tmp)];
im = im - mean(tmp);
raw.lac.snr = max(max(max(max(im .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
raw.lac.aucsnr = sum(im,4)/std(tmp)/sqrt(Nt); % not removing the background
raw.lac.data = im;
% ---- start image denoising---- %
    for s=1:Nz
        ims(:,:,s,:) =glhosvd_flexible(squeeze(im(:,:,s,:)),std(tmp), kglobal, klocal, patchsize, step, sw);  
    end
    denoised.lac.data = ims;
    lac_noise = ims(:,:,:,1) .* noise_mask;
    tmp = lac_noise(lac_noise~=0);
    denoised.lac.noise = [mean(tmp); std(tmp)];
    denoised.lac.snr = max(max(max(max(ims .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
    denoised.lac.aucsnr = sum(ims,4)/std(tmp)/sqrt(Nt);
% (3) Bicarb
% ---- noise estimation ---- %
clear im
im = data(:,:,:,:,3);
bic_noise = im(:,:,[1:3 7:8],1) .* noise_mask(:,:,[1:3 7:8]); % use the first timeframe scans (make sure that no HP signal appears in the first scans),...
% the 4th slice images are excluded because of the urea phantom signal appearing in this slice.
tmp = bic_noise(bic_noise~=0);
raw.bic.noise = [mean(tmp); std(tmp)];
im = im - mean(tmp);
raw.bic.snr = max(max(max(max(im .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
raw.bic.aucsnr = sum(im,4)/std(tmp)/sqrt(Nt); % not removing the background
raw.bic.data = im;
% ---- start image denoising---- %
    for s=1:Nz
        ims(:,:,s,:) =glhosvd_flexible(squeeze(im(:,:,s,:)),std(tmp), kglobal, klocal, patchsize, step, sw);  
    end
    bic_noise = ims(:,:,:,1) .* noise_mask;
    tmp = bic_noise(bic_noise~=0);
    denoised.bic.noise = [mean(tmp); std(tmp)];
    denoised.bic.snr = max(max(max(max(ims .* repmat(bmask,[1 1 1 Nt])))))/std(tmp);
    denoised.bic.aucsnr = sum(ims,4)/std(tmp)/sqrt(Nt);
     denoised.bic.data = ims;
end

