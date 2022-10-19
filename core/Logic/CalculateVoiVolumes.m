function [VoiVolumesResults] = CalculateVoiVolumes(varargin)
%CALCULATEVOIVOLUMES Calculate the total volume of each roi belonging to astructure set
%   This function only works while the RTsafe analysis tool is open, and a set
%   of CT images as well as a set of RTStructures has been loaded. Otherwise
%   it displays an error and returns.
%   It supports 3 different methods for point in polygon calculations.
%
%   % WARNING : THE DEFAULT METHOD IS 3 (inpoly)
%   %   - SAME RESULTS AS WITH 2 + BEST ACCURACY/PERFORMANCE RATIO
%   %   - MATCHES VOLUME CALCULATION RESULTS FROM ECLIPSE (VARIAN)
%   %   - IT IS THE SAME AS THE POINT IN DOSE METHOD USED IN DVH
%
%   Authors: Vasileios Lahanas, Eleftherios Pappas
%
%   Copyright (C) 2016, The RTsafe Developers Team 
%

VoiVolumesResults = [];
if ~isempty(varargin)
    PointInPolyMethod = varargin{1};
else
    PointInPolyMethod = 3;
end

try
    
    EBTSceneController = GetGlobalVar('EBTSceneController');
    if isempty(EBTSceneController)
       disp('Error : Unable to Find Scene Controller');
       return;
    end

    if EBTSceneController.fRTStructureSet ~= 1
       disp('Error : No RTStructure Loaded');
       return;
    end

    %Get the list of voi names
    voiNames = fieldnames(EBTSceneController.RTStructureSet.mVOIs);


    if size(voiNames,1) == 0
        disp('Error : No VOIS found');
        return;
    end

    %Calculate single voxel volume in mm^3
    VoxelVolume = EBTSceneController.CTImageSet.mImagesInfos{1,1}.PixelSpacing(1)* ...
                  EBTSceneController.CTImageSet.mImagesInfos{1,1}.PixelSpacing(2)* ...
                  EBTSceneController.CTImageSet.SliceDistance;
%                 SceneController.CTImageSet.mImagesInfos{1,1}.SliceThickness;

    %Find ct image set dimensions
    sizeX = size(EBTSceneController.CTImageSet.mImagesData,2);
    sizeY = size(EBTSceneController.CTImageSet.mImagesData,1);
    sizeZ = size(EBTSceneController.CTImageSet.mImagesData,3);


    VoiVolumesResults = cell(size(voiNames,1),2);
    %Loop in all vois based on name-index combination
    for voi = 1:size(voiNames,1)

        switch PointInPolyMethod
            case 1
                %------------------------------------------------------------------
                %Create a mask of zeros, equal to the size of ct
                VoiMask = zeros(size(EBTSceneController.CTImageSet.mImagesData));

                %Get voi contour data (indexed
                contourData = EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).indexedContourData;

                %Find min and max z indices to speed-up computations
                minZcontour = floor(min(contourData(:,3)));
                maxZcontour = ceil(max((contourData(:,3))));   

                %Loop through all z slices of ct
                for z = 1:sizeZ      
                    %If contour data exist within this slice
                    if z >= minZcontour && z <= maxZcontour            
                        %Find the indices of voi point coordinates corresponding to
                        %ct coordinates
                        ind = find(uint32(contourData(:,3))== uint32(z));
                        if ~isempty(ind)
                            %Since a single voi can have multiple polygons within
                            %the same slice, check column 4 of contour data which
                            %indicates the polygon id
                            countourInSlice = contourData(ind,:);                  
                            for flag = 1:max(countourInSlice(:,4));     
                                %Create a mask for each polygon and refresh VoiMask
                                %cube with ones within the area of this mask
                                ind2 = find(countourInSlice(:,4) == flag);         
                                if numel(ind2)>0
                                         ContourSetInSlice = countourInSlice(ind2,1:3); 
                                         mask = poly2mask(ContourSetInSlice(:,1),ContourSetInSlice(:,2),sizeY,sizeX);
                                         VoiMask(:,:,z) = mask(:,:);
                                end
                            end
                        end
                    end
                end

                %Finally, the sum of ones within the VoiMask correspond to the
                %number of CT voxels occupied by this voi. Consequently, a simple
                %multiplication by the voxel volume provides the volume of the voi
                %in mm^3
                EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVolume = ...
                    double(sum(VoiMask(:)))*VoxelVolume;
                EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVoxels = ...
                    double(sum(VoiMask(:)));
        
        
            %------------------------------------------------------------------
            
            % % % %    AN ALTERNATIVE SOLUTION, SIGNIFICANTLY SLOWER
            % % % %    This solution produces slighlty different results and should be
            % % % %    investigated 
        case {2, 3}
             S = 1:numel(EBTSceneController.CTImageSet.ImageCoordinates.z);  % slices => z coordinate
             if EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).hasContourData == 1

                                voxelsInsideVoiCounter = 0;

                                for k = find(S == floor(min(EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).indexedContourData(:,3)))): ...
                                        find(S == ceil(max(EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).indexedContourData(:,3))))

                                    ind = find(round(EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).indexedContourData(:,3)) == S(k));
                                    if ~isempty(ind)

                                        countourInSlice = EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).indexedContourData(ind,:);

                                        for flag = 1:max(countourInSlice(:,4));

                                            ind2 = find(countourInSlice(:,4) == flag);
                                            if numel(ind2)>0

                                               ContourSetData = countourInSlice(ind2,1:3);
                                               indXmin = floor(min(ContourSetData(:,1))) ;
                                               indXmax = ceil(max(ContourSetData(:,1))) ;
                                               indYmin = floor(min(ContourSetData(:,2)));
                                               indYmax = ceil(max(ContourSetData(:,2))) ;
                                               [xx,yy] = meshgrid(indXmin:indXmax,indYmin:indYmax);
                                                if PointInPolyMethod == 2
                                                      [in, on] = inpolygon(xx,yy,ContourSetData(:,1),ContourSetData(:,2));
                                                      mask = in + on;
                                                elseif PointInPolyMethod == 3
                                                      mask = inpoly([xx(:),yy(:)],[ContourSetData(:,1),ContourSetData(:,2)]);
                                                end

                                               voxelsInsideVoiCounter = voxelsInsideVoiCounter + sum(mask(:));
                                               
                                               clear mask   xx yy indXmin indXmax indYmin indYmax in on
                                            end

                                        end

                                    end

                                end

                               EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVolume = voxelsInsideVoiCounter * ...
                                                               VoxelVolume;

                                EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVoxels = ...
                                    voxelsInsideVoiCounter;

%                                SceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVolumeGamma = voxelsInsideVoiCounter2 * ...
%                                                                VoxelVolume;
% 
%                                 SceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVoxelsGamma = ...
%                                     voxelsInsideVoiCounter2;
             end
         
 
        end
        
        %------------------------------------------------------------------   
        VoiVolumesResults{voi,1} = EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).ROIName;
        VoiVolumesResults{voi,2} = EBTSceneController.RTStructureSet.mVOIs.(voiNames{voi}).VoiVolume /1000.0;
        
        

    end
    

    
catch ex
    
   disp(['Unknown Error : ' ex.message]); 
   try
       MessageBox(['Unknown Error : ' ex.message],'Error in VOIs volume calculation');
   end
   
end
