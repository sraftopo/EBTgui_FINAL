classdef RTImageSet < handle
    %RTIMAGESET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fLoaded;
        mFilePathsList;
        mImagesInfos;
        mImagesData;
        mModality;
        
        mImagesUnsortedIndexes;
        mImagesSortedIndexes;
        
        mNumberOfImages;
        mImagesWidth;
        mImagesHeight;
        mRescaleSlope;
        mRescaleIntercept;
        mWindowCenter;
        mWindowWidth;
        
        ImageCoordinates;
        
        ImageBounds;
        
        AspectFactor;
        SliceDistance;
    end
    
    methods
        
        %------------------------------------------------------------------
        function obj = RTImageSet(filelist, modality)
            
          
           obj.fLoaded = 0;
           obj.mModality = modality;
           obj.mFilePathsList = filelist(:,6); 
           obj.mNumberOfImages = size(obj.mFilePathsList,1);
           obj.mImagesInfos = cell(obj.mNumberOfImages,1);
           
           
           for fileCounter = 1:obj.mNumberOfImages
              fullFilePath = obj.mFilePathsList{fileCounter,1};
              obj.mImagesInfos{fileCounter,1} = filelist{fileCounter,10};
              obj.mImagesUnsortedIndexes{fileCounter,1} = obj.mImagesInfos{fileCounter,1}.ImagePositionPatient(3);
              obj.mImagesUnsortedIndexes{fileCounter,2} = fileCounter; 
           end
           
           
           %Read images here
           
            %Initialize and import raw patient data;
            try
                if GetGlobalVar('DEBUG_MODE') == 1; 
                disp(['Importing new data. Modality : ', obj.mModality]);
                end;
                obj.fLoaded = obj.GenerateImages();
            catch ex
                ErrorLogger('RTImageSet:RTImageSet',ex);
            end   
           
          
        end
        
        
        %------------------------------------------------------------------
        function out = GenerateImages(obj) 
            
            out = 0;
            
            %First, import all raw dicom headers with random order
            try

            
                %Then sort indices based on image position patient (z axis)
                obj.mImagesSortedIndexes = sortrows(obj.mImagesUnsortedIndexes,1);
                
               
                %Initialize image data array
                obj.mImagesWidth =  obj.mImagesInfos{1,1}.Columns;
                obj.mImagesHeight = obj.mImagesInfos{1,1}.Rows;                
                obj.mImagesData = zeros(obj.mImagesHeight,obj.mImagesWidth, obj.mNumberOfImages);
                
                
               %Axial bounds : total number of images
               obj.ImageBounds.AxialBounds = obj.mNumberOfImages;
               %Coronal bounds : x direction = width
               obj.ImageBounds.CoronalBounds = obj.mImagesWidth;
               %Sagittal bounds : y direction = height
               obj.ImageBounds.SagittalBounds = obj.mImagesHeight;
                
                
                for i = 1:obj.mImagesWidth
                    obj.ImageCoordinates.x(i,1) = obj.mImagesInfos{1,1}.ImagePositionPatient(1) + double((i-1))*obj.mImagesInfos{1,1}.PixelSpacing(1);  
                end
                for i = 1:obj.mImagesHeight
                    obj.ImageCoordinates.y(i,1) = obj.mImagesInfos{1,1}.ImagePositionPatient(2) + double((i-1))*obj.mImagesInfos{1,1}.PixelSpacing(2);  
                end
                
                try
                    obj.mRescaleSlope = obj.mImagesInfos{1,1}.RescaleSlope;
                catch
                    obj.mRescaleSlope = 1.0;                    
                end
                if isempty(obj.mRescaleSlope)
                    obj.mRescaleSlope = 1.0;
                end
                try
                	obj.mRescaleIntercept = obj.mImagesInfos{1,1}.RescaleIntercept;
                catch
                    obj.mRescaleIntercept = 0.0;                    
                end
                if isempty(obj.mRescaleIntercept)
                    obj.mRescaleIntercept = 0.0;
                end
                
                
                try
                    obj.mWindowCenter = obj.mImagesInfos{1,1}.WindowCenter;
                    obj.mWindowCenter = obj.mWindowCenter*obj.mRescaleSlope + obj.mRescaleIntercept;  
                catch
                    obj.mWindowCenter = [];
                end
                if size(obj.mWindowCenter,1) > 1
                    obj.mWindowCenter = obj.mWindowCenter(1);
                end
                try
                    obj.mWindowWidth = obj.mImagesInfos{1,1}.WindowWidth;
                    obj.mWindowWidth = obj.mWindowWidth*obj.mRescaleSlope;
                catch
                    obj.mWindowWidth = [];
                end
                if size(obj.mWindowWidth,1) > 1
                    obj.mWindowWidth = obj.mWindowWidth(1);
                end
                
                %Temp copy unsorted image infos
                tempInfoList = obj.mImagesInfos;
                
                %Perform sorting in image infos and load sorted image data
                %in the same loop
               
                for i = 1:obj.mNumberOfImages
                    obj.mImagesInfos{i,1}  = tempInfoList{obj.mImagesSortedIndexes{i,2},1};
                    obj.mImagesData(:,:,i) = double(dicomread(obj.mFilePathsList{obj.mImagesSortedIndexes{i,2},1}));
%                   obj.mImagesData(:,:,i) = obj.mImagesData(:,:,i)*obj.mImagesInfos{i,1}.RescaleSlope + obj.mImagesInfos{i,1}.RescaleIntercept;   
                    obj.mImagesData(:,:,i) = obj.mImagesData(:,:,i)*obj.mRescaleSlope + obj.mRescaleIntercept;    
%                     obj.ImageCoordinates.z(i,1) = obj.mImagesInfos{1,1}.ImagePositionPatient(3) + double((i-1))*obj.mImagesInfos{i,1}.SliceThickness; 
                    obj.ImageCoordinates.z(i,1) = obj.mImagesInfos{i,1}.ImagePositionPatient(3); 
                end
                
                obj.SliceDistance = obj.mImagesInfos{2,1}.ImagePositionPatient(3) - obj.mImagesInfos{1,1}.ImagePositionPatient(3);
               
                clear tempInfoList;
                
               
                
                if max(strcmp('CT', obj.mModality)) == 1
                    obj.mModality = 'CT';
                elseif max(strcmp('MR',obj.mModality)) == 1
                    obj.mModality = 'MR'; 
                end
                
                if isempty(obj.mWindowWidth)
                   obj.mWindowWidth= (max(obj.mImagesData(:)) - min(obj.mImagesData(:))); 
                end
                
                if isempty(obj.mWindowCenter)
                   obj.mWindowCenter = (max(obj.mImagesData(:)) + min(obj.mImagesData(:)))/2.0; 
                end
                
                if obj.mImagesInfos{1}.PixelSpacing(1) < obj.SliceDistance
                    obj.AspectFactor = [1 obj.mImagesInfos{1}.PixelSpacing(1)/obj.SliceDistance 1];
                else
                   obj.AspectFactor = [obj.SliceDistance/obj.mImagesInfos{1}.PixelSpacing(1) 1 1];
                end
                
                

            catch ex
                if GetGlobalVar('DEBUG_MODE') == 1; disp(ex.message);end;
                ErrorLogger('RTImageSet::ImportRawImageInfo',ex);
                return;
            end
            
            out = 1;
            
        end
        
       
        
        
    end
    
end

