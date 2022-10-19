function [ out ] = ScaledImageFromViewParameters( data, slice, view, level, window )
%SCALEDIMAGEFROMVIEWPARAMETERS Summary of this function goes here
%   Detailed explanation goes here
    
   %Initialize output to zero
    out = 0;
    
    try
        
        %Get scale factors from level and window
        minPval = double(level - window/2);
        maxPval = double(level + window/2);
        RESCALE_FACTOR = 0;

        %Obtain the correct slice based on orientation
        switch view
            case Views.Axial                    

                scaledSlice = ScaleImage(double(data(:,:,slice) + RESCALE_FACTOR),...
                    window,minPval(1),maxPval(1),RESCALE_FACTOR);

            case Views.Coronal

                scaledSlice = ScaleImage(double(squeeze(data(slice,:,:))' + RESCALE_FACTOR),...
                    window,minPval(1),maxPval(1),RESCALE_FACTOR);

            case Views.Sagittal
                
                scaledSlice = ScaleImage(double(squeeze(data(:,slice,:))' + RESCALE_FACTOR),...
                    window,minPval(1),maxPval(1),RESCALE_FACTOR);
                
        end
        
        %Return scaled slice
        out = scaledSlice;  
        
    catch ex
        
       disp(ex.message); 
       
       %In case something goes wrong, return a plain 0, and allow
       %requesting functions to do basic error handling on their own
       out = 0;
    end
    
    
    
    function scaledImg = ScaleImage(varargin) 

        % img,Window,minPval,maxPval,RESCALE_FACTOR)

        % this function scales the pixel values of the input img in order to plot
        % image data using direct mapping  
        % note that only 8 bits (256) are used to plot image data

        img = varargin{1};
        Window = varargin{2};


        RESCALE_FACTOR = varargin{5};
        minPval = varargin{3} + RESCALE_FACTOR;
        maxPval = varargin{4} + RESCALE_FACTOR;

        img(img < (minPval)) = minPval ;
        img(img > (maxPval)) = maxPval;
        
        sc = (256-1)/(maxPval - minPval);
        
        if isinf(sc)
            sc = 0; 
        end
        
        scaledImg = round( sc*(img - (minPval)) + 1 );
            
    end

end

