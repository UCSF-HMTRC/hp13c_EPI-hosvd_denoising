function display_dyn_callback(h_obj, event)
    global y_cord
    global x_cord
    global loc_dyn_traces
    global ndata
    global output
    global dn_asnr
    global asnr
    global window
    
    xc= str2double(get(x_cord,'String')); 
    yc = str2double(get(y_cord,'String')); 
%   
    % 1x3 voxels
    xc_list = xc:xc+1;
    yc_list = yc:yc;
    
    ctr = 1;
    for xx = 1:length(xc_list)
        for yy = 1:length(yc_list)
                raw(:,ctr) = squeeze(ndata(yc_list(yy),xc_list(xx),:));
                denoised(:,ctr)= squeeze(output(yc_list(yy),xc_list(xx),:));
                asnr_raw(:,ctr) = asnr(yc_list(yy),xc_list(xx));
                asnr_dn(:,ctr) = dn_asnr(yc_list(yy),xc_list(xx));
                ctr = ctr + 1;
        end
    end
    
    % Display data
    tt = (1:length(raw));    
    p = plot(loc_dyn_traces, tt, raw, tt, denoised); 
    color_list = get(gca,'colororder');
    for i = 1:size(p,1)/2
        p(i).LineWidth = 1; p(i+size(p,1)/2).LineWidth = 1;
        p(i).LineStyle = ':'; p(i+size(p,1)/2).LineStyle = '-';
        p(i).Marker = 's'; p(i+size(p,1)/2).Marker = 's';
        p(i).Color = color_list(i,:); p(i+size(p,1)/2).Color = color_list(i,:);
        p(i).MarkerFaceColor ='w'; p(i+size(p,1)/2).MarkerFaceColor = color_list(i,:);
        legend_text{i} = ['Orig: x(' num2str(xc_list(i)) ') y(' num2str(yc_list(1)) ')'];
        legend_text{i+size(p,1)/2} = ['DN: x(' num2str(xc_list(i)) ') y(' num2str(yc_list(1)) ')'];
    end   
    set(loc_dyn_traces, 'XLim', [0 21],'FontSize',12);
    lgd = legend(loc_dyn_traces, legend_text);
    lgd.Location = 'bestoutside';
    loc_dyn_traces.XLabel.String = 'Time frame';
    loc_dyn_traces.YLabel.String = 'Intensity (a.u.)';  
    title(loc_dyn_traces,'Signal dynamics');
    loc_dyn_traces.NextPlot = 'replacechildren';
    
    %% asnr
    asnr_label= uicontrol('Parent', window,...
        'Style', 'text',...
        'FontSize',12,...
        'Units', 'normalized',...
        'String', ['Pre-DN> SNR(auc) = ' num2str(asnr_raw(1), '%.f') ' / ' num2str(asnr_raw(2), '%.f')], ...
        'Position', [0.85 0.125 0.14 0.06]); 
    hold on;
asnr_label= uicontrol('Parent', window,...
        'Style', 'text',...
        'FontSize',12,...
        'Units', 'normalized',...
        'String', ['Post-DN> SNR(auc) = ' num2str(asnr_dn(1), '%.f') ' / ' num2str(asnr_dn(2), '%.f')], ...
        'Position', [0.85 0.06 0.14 0.06]); 

 end