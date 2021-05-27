function display_DNimage(rawImage, kglobal, klocal, noise_level)
    X = size(rawImage,2);
    Y = size(rawImage,1);
    num_frames = size(rawImage,3);
    output = zeros([Y X num_frames]);

    step = 2; 
    patchsize =5;
    sw = 6; % radius of search window
    
    addpath('/data/vig1/ykim/Brain_C13/DenoiseEPI_master/GL-HOSVD/');
    addpath('/data/vig1/ykim/Brain_C13/Codes/gl-hosvd-master/HOSVD/');

    output =glhosvd_flexible(rawImage, noise_level, kglobal, klocal, patchsize, step, sw); 
    h1 = figure(101);
    for i=1:num_frames
    subplot(6,4,i)
    imagesc(output(:,:,i)); axis off
    title(['DN: TF #' num2str(i)]);
    end
    h1.Position= [900 700 650 700];

end
