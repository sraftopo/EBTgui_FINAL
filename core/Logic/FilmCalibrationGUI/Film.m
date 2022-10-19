classdef Film < handle
    %FILM2 Summary of this class goes here
    %   Detailed explanation goes here
 
% ----------------------------------------------------------------------- %        
    properties
        
        mData;                % the scanned film in RGB     
        mDPI;                 % the resolution of the scanned film in dpi
        mBit;                 % The number of bits per color
        mFilmCoordinates;     % The x,y coordinates of the film data
        mPath;                % The path of the film data
        mFilename;            % The name of the film data
        mFilmDosimetryMethod; % Film Dosimetry method (Devic - SingleChannel,Micke - MultiChannel) 
        mOD;                  % The optical density map (Micke - MultiChannel) 
        mDR;                  % The change in reflectance map (Devic - SingleChannel)
        
    end
% ----------------------------------------------------------------------- %        

 
    methods
        
% ----------------------------------------------------------------------- %
        function obj = Film(filename)
            if ~isempty(filename)
                obj.mFilename = filename;
            end
        end
% ----------------------------------------------------------------------- %        
        
        
        
% ----------------------------------------------------------------------- %        
        function out = ReadFilmData(obj,fullpath)
               out = 0;
               if isempty(fullpath)
                    [fname, pathname] = uigetfile('*.tif', 'Pick a tif film file');
                    fullpath = fullfile(pathname,fname);
               end

                   obj.mPath = fullpath;

                   a = imread(fullpath);
                   obj.mData.Red = double(a(:,:,1));
                   obj.mData.Green = double(a(:,:,2));
                   obj.mData.Blue = double(a(:,:,3));
                   obj.mData.Total = a;

                   b = imfinfo(fullpath);
                   obj.mDPI.x = b.XResolution;
                   obj.mDPI.y = b.YResolution;
                   obj.mBit = b.BitDepth ;

                   out = 1;
        end
% ----------------------------------------------------------------------- %        
        
        
        
% ----------------------------------------------------------------------- %        
        function CreateFilmCoordinates(obj,fullpath)
           
               ps = 25.4/obj.mDPI.x;   % in cm

               obj.mFilmCoordinates.x = (0:(size(obj.mData.Red,2)-1))* ps ;
               obj.mFilmCoordinates.y = (0:(size(obj.mData.Red,1)-1))* ps ;
               
               obj.mFilmCoordinates.xind = (1:(size(obj.mData.Red,2))) ;
               obj.mFilmCoordinates.yind = (1:(size(obj.mData.Red,1))) ;
         
        end
% ----------------------------------------------------------------------- %        


    end
    
end

