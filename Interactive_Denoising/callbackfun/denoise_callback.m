function denoise_callback(h_obj, event)
    global klocal
    global kglobal
    global patch_size
    global step_size
    global window_size
    global output
    global scale_factor
    global loc_DNdata
    global raw_noise_std 
    global ndata
    global im
    
    k_global = str2double(get(kglobal,'String')); 
    k_local = str2double(get(klocal,'String')); 
    patchsize = str2double(get(patch_size,'String'));  
    stepsize = str2double(get(step_size,'String'));  
    windowsize = str2double(get(window_size,'String'));  
    scale = str2double(get(scale_factor,'String')); 
   
    X = size(ndata,2); Y = size(ndata,1); numTF = size(ndata,3);
    output = zeros(Y,X,numTF); 
    output =glhosvd_flexible(squeeze(ndata), raw_noise_std, k_global, k_local, patchsize, stepsize, windowsize);
    output = permute(output,[1 2 4 3]);
 
    % Display data
    montage(output, 'DisplayRange', [0 max(im(:))/scale], 'Size', [4 ceil(numTF/4)], ...
        'Parent',loc_DNdata); colormap default;  
    noise_est2_callback(output, event)
    display_auc_callback(output, event)
%     display_dyn_callback(output,event)
end
