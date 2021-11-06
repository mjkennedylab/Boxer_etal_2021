% GeneralAnalysis.imgLaplaceCutoff
% GeneralAnalysis.imgThreshold_fixedUserInput
% GeneralAnalysis.viewMaskOverlay
% GeneralAnalysis.cleanUpMask_manual_square

classdef Boxer_helperFunctions < handle
    properties
        test = [];
    end
    
    methods (Static)
        function img_lapl = imgLaplace(img_in,lsig,gsig)
            % gaussian filters image and then calculates laplacian
            % inputs:
            % img_in - dipimage or matrix image (converts to type dipimage)
            % lsig - kernal for laplacian. must be
            %           same dimension as img_in. example: [1 1 0] is
            %           transfrom in x and y but not time.
            % gsigma - optional input to set the gaussian kernal. must be
            %           same dimension as img_in. example: [1 1 0] is gaussian
            %           smoothing in x and y but not time.
            % outputs:
            % img_lapl - filtered dipimage. to convert to matlab array use
            %           single(img_out).
            if nargin<3
                gsig = ones(1,numel(size(img_in)));
                if nargin<2
                    lsig = ones(1,numel(size(img_in)));
                end
            end
            img_g = gaussf(img_in,gsig);
            img_lapl = dxx(img_g,lsig)+dyy(img_g,lsig);
        end
        function img_laplcutoff = imgLaplaceCutoff(img_in,lsig,gsig)
            if nargin<3
                gsig = ones(1,numel(size(img_in)));
                if nargin<2
                    lsig = ones(1,numel(size(img_in)));
                end
            end
            img_lapl = GeneralAnalysis.imgLaplace(img_in,lsig,gsig);
            img_laplcutoff = -img_lapl;
            img_laplcutoff(img_laplcutoff<0) = 0;
        end
        
        function [mask,threshval,C] = imgThreshold_fixedUserInput(img_in,image4selection)
            if ~isa(img_in,'dip_image')
                img_in = dip_image(img_in);
            end
            uiwait(msgbox('Select a representative background region','Title','modal'));
            if nargin<2
                image4selection = img_in;
            end
            h = dipshow(image4selection,'log');
            diptruesize(h,25);
            [~,C] = dipcrop(h);
            if ndims(img_in)==3
                reg = img_in(C(1,1):C(1,1)+C(2,1),C(1,2):C(1,2)+C(2,2),:);
            elseif ismatrix(img_in)
                reg = img_in(C(1,1):C(1,1)+C(2,1),C(1,2):C(1,2)+C(2,2));
            end
            threshval = max(reg);
            mask = threshold(img_in,'fixed',threshval);
            close(h);
        end
        function [h,overlayarr] = viewMaskOverlay(grayim,mask)
            if ~isa(grayim,'dip_image')
                try
                    grayim = dip_image(grayim);
                catch
                    warning('input must be an image matrix');
                    return;
                end
            end
            assert(ndims(grayim) == ndims(mask));
            grayim_minusmask = grayim.*~mask;
            mskfrm = max(grayim)*10*mask + grayim_minusmask;
            switch ndims(grayim)
                case 2
                    rch = cat(3,mskfrm,grayim);
                    gch = cat(3,grayim_minusmask,grayim);
                case 3
                    rch = cat(4,mskfrm,grayim);
                    gch = cat(4,grayim_minusmask,grayim);
            end
            bch = gch;
            overlayarr = joinchannels('rgb',rch,gch,bch);
            h = dipshow(overlayarr,'log');
        end
        function newmask = cleanUpMask_manual_square(underimg_in,mask_in,imviewsz)
            
            %        lb = label(mask_in);
            %         ov = overlay(underimgin,mask_in);
            %         h = dipshow(ov,'log');
            %         dipmapping(h,'global')
            %       h = dipshow(lb,'labels');
            %         while(ishandle(h))
            %             [a b] = dipcrop(h);
            %             mask_in(b(1,1):b(1,1)+b(2,1),b(1,2):b(1,2)+b(2,2),:) = 0;
            %             close(h);
            %             ov = overlay(underimgin,mask_in);
            %             h = dipshow(ov,'log');
            %             dipmapping(h,'global');
            %         end
            if nargin<3
                imviewsz = 150;
            end
            lb = label(logical(mask_in));
            underimg = dip_image(underimg_in);
            ov = dip_image(underimg);
            ov(lb~=0) = 0;
            g = dipfig('ov');
            try
                dipshow(ov,'log');
            catch
                dipshow(ov,'percentile');
            end
            diptruesize(g,imviewsz);
            clmp = bone(255);
            clmp(1,:) = [1 0 0];
            while(ishandle(g))
                try
                    [B,C] = dipcrop(g);
                    %                 v = dipgetcoords(g,1);
                catch
                    break;
                end
                gcfinfo = get(g,'UserData');
                if ndims(B)==3
                    
                    currtime = gcfinfo.curslice;
                    img2remove = lb(C(1,1):C(1,1)+C(2,1),C(1,2):C(1,2)+C(2,2),currtime);
                    lbs2remove = unique(single(img2remove));
                    
                elseif ismatrix(B)
                    img2remove = lb(C(1,1):C(1,1)+C(2,1),C(1,2):C(1,2)+C(2,2));
                    lbs2remove = unique(single(img2remove));
                end
                for ii = lbs2remove(lbs2remove~=0)'
                    lb(lb == ii) = 0;
                end
                ov = underimg;
                ov = dip_image(ov);
                ov(lb~=0) = 0
                diptruesize(gcf,imviewsz);
                try
                    dipmapping('log')
                catch
                    dipmapping('percentile')
                end
                dipmapping('colormap',clmp);
            end
            dipfig -unlink
            newmask = logical(lb);
        end
        
    end
end