classdef RTDoseObject < handle
    %RTDOSEOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fLoaded;            %Flag indicating loading result
        mFilename;          %RTDose filename
        mRTDoseCoordinates; %RTDose coordinates
        mStudyInstanceUID;  %Study instance uid
        mInfo;              %RTDose info (dicom header)
        mDoseCube;          %The actual dose values (cube)
        mDoseGridScaling;   %Dose grid scaling
        
        CTToDoseCubeIndexedCoordinates;
        DoseCubeToCTIndexedCoordinates;
        mInterpolatedDoseCube;
    end
    
    methods
        %----------------------------------------
        %Constructor
        function obj = RTDoseObject(filepath)
            
            obj.mDoseGridScaling = 1.0;
            
            obj.fLoaded = obj.ImportRTDose(filepath);
        end
        
        
        %------------------------------------------------------------------
        % Read RTDOSE exported file and create RTDOSE coordinates
        % The RTDOSEresampled cube (it contains dose values for is CTvoxel)
        % is also calculated. 
        %------------------------------------------------------------------
        function out = ImportRTDose(obj, filepath)
            
                       
            %Out flag = 0 if something goes wrong, otherwise 1
            out = 0;
 
            
            %If a path is not provided, open a selection file dialog
            if strcmp(filepath,'');
                [filename,filepath] = uigetfile({'*.dcm';'*.*'},'Please select the RTDose file from TPS',GetGlobalVar('LastSearchPath'),'MultiSelect', 'off');
               
                 %If a file has been selected
                 if ischar(filename) && ischar(filepath)
                   try
                       set( gcf, 'Pointer', 'watch' ); drawnow;
                       newRTDOSEinfo = DicomInfoCustom(fullfile(filepath,filename));
                   catch ex
                       errorReport('RTDoseObject:readRTDose',ex);
                       return;
                   end
                 else return;
                 end
                 obj.mFilename = [filepath filename];
            else
            %If a filepath has been provided, directly load rtdose file
                try
                    set( gcf, 'Pointer', 'watch' ); drawnow;
                    newRTDOSEinfo = DicomInfoCustom(filepath);
                catch ex
                    errorReport('RTDoseObject:readRTDose',ex);
                    return;
                end
                obj.mFilename = filepath;
            end
            
            
            %Check modality
            if strcmp(newRTDOSEinfo.Modality, 'RTDOSE') ~= 1                
                msg = ('You have selected an invalid DICOM modality!');
                MessageBox(msg,'Warning');
                return;
                
            end
            
            %TODO : ENABLE STUDY CROSS CHECKING?
            if 1 == 0
                if (strcmp(newRTDOSEinfo.StudyInstanceUID,obj.StudyInstanceUID)) 
                  %out = 1;
                else
                    MessageBox('The selected file does not belong to the current study. Please choose another RTDOSE file.','Warning');
                    return;
                end
            end

            try
                
                
            %Generate rtdose info and coordinates
            obj.mInfo = newRTDOSEinfo;
            obj.mStudyInstanceUID = obj.mInfo.StudyInstanceUID;
            obj.mDoseGridScaling = obj.mInfo.DoseGridScaling;
            obj.mDoseCube = DicomReadCustom(obj.mInfo);
            obj.mDoseCube = uint32((double(squeeze(obj.mDoseCube))*obj.mInfo.DoseGridScaling)/obj.mDoseGridScaling);
            obj.mDoseGridScaling = obj.mInfo.DoseGridScaling;
            % allocate memory for better performance
            obj.mRTDoseCoordinates.x = zeros(obj.mInfo.Columns,1);
            obj.mRTDoseCoordinates.y = zeros(obj.mInfo.Rows,1);
            obj.mRTDoseCoordinates.z = zeros(obj.mInfo.NumberOfFrames,1);
           
            if (size(obj.mDoseCube,2) ~= obj.mInfo.Columns) || ...
                    (size(obj.mDoseCube,1) ~= obj.mInfo.Rows)|| ...
                    (size(obj.mDoseCube,3) ~= obj.mInfo.NumberOfFrames)
               out = -1;
               return; 
            end
            
            % parse pixel spacing to create the rtdose coordinate frame 
            ps = obj.mInfo.PixelSpacing;

            %create RTDOSE coordinate system (units in mm as in dicom format)
            for i=1:double(obj.mInfo.Columns)
                obj.mRTDoseCoordinates.x(i,1) = double(obj.mInfo.ImagePositionPatient(1)) + (i-1)*ps(1);
            end
            for i=1:double(obj.mInfo.Rows)
                obj.mRTDoseCoordinates.y(i,1) = double(obj.mInfo.ImagePositionPatient(2)) + (i-1)*ps(2);
            end
            for i=1:double(obj.mInfo.NumberOfFrames)
                %FIX : OFFSET CAN BE RELATIVE
                obj.mRTDoseCoordinates.z(i,1) = double(obj.mInfo.ImagePositionPatient(3)) + ...
                                               double(obj.mInfo.GridFrameOffsetVector(i));
            end
                   
           
%            If a primary image set has been loaded, then create indexed
%            rtdose coordinates
           EBTSceneController = GetGlobalVar('EBTSceneController');
           if EBTSceneController.fCTImageSet == 1
               obj.mRTDoseCoordinates.xind = ((obj.mRTDoseCoordinates.x - EBTSceneController.CTImagePositionPatient(1))/ EBTSceneController.CTVoxelSize(1)) + 1;
               obj.mRTDoseCoordinates.yind = ((obj.mRTDoseCoordinates.y - EBTSceneController.CTImagePositionPatient(2))/ EBTSceneController.CTVoxelSize(2)) + 1 ;
               obj.mRTDoseCoordinates.zind = ((obj.mRTDoseCoordinates.z - EBTSceneController.CTImagePositionPatient(3))/ EBTSceneController.CTVoxelSize(3)) + 1 ;              
           end
                    
           out = 1;
           
%            [xxx, yyy, zzz] = meshgrid(obj.mRTDoseCoordinates.x,obj.mRTDoseCoordinates.y,obj.mRTDoseCoordinates.z);
%            [xx, yy, zz] = meshgrid(EBTSceneController.CTImageSet.ImageCoordinates.x,EBTSceneController.CTImageSet.ImageCoordinates.y,EBTSceneController.CTImageSet.ImageCoordinates.z);
%            obj.mInterpolatedDoseCube = interp3(xxx,yyy,zzz,double(obj.mDoseCube), xx,yy,zz,'linear',NaN);
% %            

            catch ex
               out = -1;
               return;  
           end
           
        end
        
            
    end
    
end


       

