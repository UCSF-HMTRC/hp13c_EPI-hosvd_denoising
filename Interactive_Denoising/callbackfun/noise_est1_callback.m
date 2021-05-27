function noise_est1_callback(h_obj, event)
    global ndata
    global raw_noise_std 
    global noisemask
    global im
    global window
    global asnr
    
[snr asnr noise_avg raw_noise_std ndata noisemask] = noise_est1(permute(im,[1 2 4 3]), 0);
% p_noise_cal_result = [0.33 0.40 0.1 0.03]; 
p_noise_cal_result = [0.02 0.09 0.3 0.03]   ;

    noise_raw= uicontrol('Parent', window,...
            'Style', 'text',...
            'FontSize',12,...
            'Units', 'normalized',...
            'String', ['Pre-DN > Noise level (std): ' num2str(raw_noise_std,'%.3f')], ...
            'Position', p_noise_cal_result);      
end
