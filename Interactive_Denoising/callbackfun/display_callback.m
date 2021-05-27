function display_callback(h_obj, event)
    global met_dyn
    global met_num
    global display_slice
    global scale_factor
    global loc_rawdata
    global im
    
    m = str2double(get(met_num,'String')); 
    s = str2double(get(display_slice,'String')); 
    scale = str2double(get(scale_factor,'String')); 
    im = squeeze(met_dyn(:,:,s,:,m));   
    im = permute(im,[1 2 4 3]);
    numTF = size(im,4);

    % Display data
    montage(im,'DisplayRange', [0 max(im(:))/scale], 'Size', [4 ceil(numTF/4)], ...
        'Parent', loc_rawdata); colormap default;
end