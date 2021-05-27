function display_auc_callback(h_obj, event)
    global loc_rawdata_auc
    global im
    global output
    
    auc = sum(squeeze(im),3);
    % Display data
    imagesc(loc_rawdata_auc, auc); colormap default; hold on;
    title(loc_rawdata_auc,'AUC image');
%     axis image
%     p = get(gca, 'CurrentPoint');
%     x_cord = floor (p(1));
%     y_cord = floor(p(2));
%     
    display_dyn_callback(output, event)
 end