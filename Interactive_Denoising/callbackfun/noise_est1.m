function [snr asnr noise_avg noise_std ndata noise_mask] =  noise_est1(data, dn, mask)

    X = size(data,2); Y = size(data,1);
    num_frames = size(data,3);
    auc = sum(data,3);
    
 %     hh.Position = [500 500 200 200];
    if nargin < 3
        % AUC images
        hh=figure; imagesc(auc); axis off; colormap default    
        title('Draw an signal ROI to exclude in noise estimation and hit enter');
        p = drawfreehand('LineWidth',2,'Color','cyan');
        pause
        %     
        background= ones(Y,X) - createMask(p);
       
        close(hh) 
        noise_mask = ones(Y,X) .* background;
        noise_mask(:,1,:) = 0;
        noise_mask(:,end,:) = 0;
   
    elseif nargin == 3
        noise_mask = mask;
    end
    
    %% ---- noise estimation
    noise = data .* repmat(noise_mask,[1 1 num_frames]);
    tmp = noise(noise~=0);

    noise_avg = mean(tmp);
    noise_std= std(tmp);
    if dn == 0
        ndata  = data - noise_avg;
        snr = ndata/noise_std;
        asnr=sum(ndata ,3)/(sqrt(num_frames)*noise_std);
    elseif dn == 1
        snr = data/noise_std;
        asnr = sum(data ,3)/(sqrt(num_frames)*noise_std);
        ndata = data;
    end
end
