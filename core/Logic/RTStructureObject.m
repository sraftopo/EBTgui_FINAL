classdef RTStructureObject < handle
    %RTStructureObject Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fLoaded;            %Flag indicating loading result
        mFilename;          %RTDose filename
        mStudyInstanceUID;  %Study instance uid
        mInfo;              %RTDose info (dicom header)
        
        mROIs;
        mVOIs;
        mVOIsVolumes;
        mNumOfVOIs;
        mVoisProperties;
        
        
    end
    
    methods
        %----------------------------------------
        %Constructor
        function obj = RTStructureObject(filepath)
            
            
            obj.fLoaded = obj.ImportRTStructure(filepath);
            
        end
        
        
        %------------------------------------------------------------------
        % Read RTDOSE exported file and create RTDOSE coordinates
        % The RTDOSEresampled cube (it contains dose values for is CTvoxel)
        % is also calculated. 
        %------------------------------------------------------------------
        function out = ImportRTStructure(obj, filepath)
            
                       
            %Out flag = 0 if something goes wrong, otherwise 1
            out = 0;
            
            %If a path is not provided, open a selection file dialog
            if strcmp(filepath,'');
                [filename,filepath] = uigetfile({'*.dcm';'*.*'},'Please select the RT Structure file for this CT image set',GetGlobalVar('LastSearchPath'),'MultiSelect', 'off');

                 %If a file has been selected
                 if ischar(filename) && ischar(filepath)
                   try
                       set( gcf, 'Pointer', 'watch' ); drawnow;
                       
                       newRTSTRUCTUREinfo = DicomInfoCustom(fullfile(filepath,filename));
             
                       
                   catch ex
                       ErrorLog('RTStructureObject:readRTDose',ex);
                       return;
                   end
                 else return;
                 end
                 obj.mFilename = [filepath filename];
            else
            %If a filepath has been provided, directly load rtdose file
                try
                    set( gcf, 'Pointer', 'watch' ); drawnow;
                    
                    newRTSTRUCTUREinfo = DicomInfoCustom(filepath);
                   
                catch ex
                    ErrorLog('RTStructureObject:ImportRTStructure',ex);
                    return;
                end
                obj.mFilename = filepath;
            end
            
            
            %Check modality
            if strcmp(newRTSTRUCTUREinfo.Modality, 'RTSTRUCT') ~= 1                
                msg = ('You have selected an invalid DICOM modality!');
                MessageBox(msg,'Warning');
                return;
                
            end
            
            %TODO : ENABLE STUDY CROSS CHECKING?
            if 1 == 0
                if (strcmp(newRTSTRUCTUREinfo.StudyInstanceUID,obj.StudyInstanceUID)) 
                  %out = 1;
                else
                    MessageBox('The selected file does not belong to the current study. Please choose another RTDOSE file.','Warning');
                    return;
                end
            end

          
            %Generate rtdose info and coordinates
            try
                
                obj.mInfo = newRTSTRUCTUREinfo;
                obj.mStudyInstanceUID = obj.mInfo.StudyInstanceUID;
          
                obj.ExtractDelineatedStructuresFromRTSS();
                obj.CalculateVOIindexedCoordinates();
                
                

                obj.mNumOfVOIs = 0;
                expectedNumberOfVOIs  = numel(fieldnames(obj.mVOIs));

                for i = 1:expectedNumberOfVOIs
                   VOIname = strcat('VOI_',int2str(i));
                   try 
                       obj.mVoisProperties(i).name = obj.mVOIs.(VOIname).ROIName;
                       obj.mVoisProperties(i).visible = 1;
                       obj.mVoisProperties(i).color = obj.mVOIs.(VOIname).ROIDisplayColor;                       
                       obj.mNumOfVOIs = obj.mNumOfVOIs + 1;
                   catch
                        obj.mVOIs = rmfield( obj.mVOIs,VOIname);
                   end
                end
                
            catch
                out = -1;
                obj.fLoaded = -1;
                return;
            end
            
            obj.fLoaded = 1;
            out = 1;
           
        end
        
        % ----------------------------------------------------------------------------------------------
        % take RTSS and extract into a structure only the contour 3D coordinates and default color for 
        % the delineated VOIs and not for the applicators 
        % ----------------------------------------------------------------------------------------------
        function ExtractDelineatedStructuresFromRTSS(obj)
            
            RTSS = obj.mInfo;
                      
            % extract the fields from StructureSetROISequence    
            voiCandidates = fieldnames(RTSS.StructureSetROISequence);
            numberOfVOICandidates = numel(voiCandidates);
            obj.mROIs = cell(numberOfVOICandidates+1,9);
            obj.mROIs = {'ItemNumber','ROIName','ROINumber','RTROIInterpretedType','Color','ContourData(mm)','indexedContourData','Volume(mm)'};
          
            
            for i = 1:numberOfVOICandidates
                try
                    tempItemName = voiCandidates{i};
                    tempName = RTSS.StructureSetROISequence.(tempItemName).ROIName;
                    tempNumber = RTSS.StructureSetROISequence.(tempItemName).ROINumber;
                    tempRTROIInterpretedType = 'No observation type in Elements?'; %RTSS.RTROIObservationsSequence.(tempItemName).RTROIInterpretedType;
                    tempROIDisplayColor = RTSS.ROIContourSequence.(tempItemName).ROIDisplayColor;
                    
                    % If the loop reaches here, it means that basic
                    % information has been temporarily grabbed, so save it         

                    obj.mROIs{i+1,1} = tempItemName;
                    obj.mROIs{i+1,2} = tempName;
                    obj.mROIs{i+1,3} = tempNumber;
                    obj.mROIs{i+1,4} = tempRTROIInterpretedType;
                    obj.mROIs{i+1,5} = tempROIDisplayColor;
                    
                    % Objects of the RTSS as stored as Item_1, Item_2 etc
                    % Since however, these are only VOIs, we use a
                    % different notation for the ones that we want (VOI_1
                    % etc.)      
                    itemName = strcat('Item_',int2str(i));  
                    VOIname = strcat('VOI_',int2str(i));
                    obj.mVOIs.(VOIname).ROINumber = RTSS.StructureSetROISequence.(itemName).ROINumber;
                    obj.mVOIs.(VOIname).ROIName = RTSS.StructureSetROISequence.(itemName).ROIName;
                  
                catch ex
                    disp('Unable to read all ROIs');
                    disp(ex.message);
                    break;
                end                
            end

          numberOfVOIs = numel(fieldnames(obj.mVOIs));
          % search and find some properties of the delineated VOIs                
          for i = 1 : numberOfVOIs
              
           % Again, items are stored as VOI_i in us, and Item_i in RTSS
            VOIname = strcat('VOI_',int2str(i));              
            try
                NumberOfContourPoints = 0; 
                for j = 1:numel(fieldnames(RTSS.ROIContourSequence))
                    itemName = strcat('Item_',int2str(j));
                    if ~isempty(cell2mat( strfind(fieldnames(RTSS.ROIContourSequence.(itemName)),'ReferencedROINumber')))
                    if obj.mVOIs.(VOIname).ROINumber == RTSS.ROIContourSequence.(itemName).ReferencedROINumber
                        obj.mVOIs.(VOIname).ROIDisplayColor = RTSS.ROIContourSequence.(itemName).ROIDisplayColor;
                        % Check if this RTSS item has a contour sequence
                        if ~isempty(cell2mat( strfind(fieldnames(RTSS.ROIContourSequence.(itemName)),'ContourSequence')))

                          NumberOfContourPoints = 0;                              
                          for k = 1:numel(fieldnames(RTSS.ROIContourSequence.(itemName).ContourSequence))

                             itemName2 = strcat('Item_',int2str(k));
                             obj.mVOIs.(VOIname).ContourGeometricType = ...
                                RTSS.ROIContourSequence.(itemName).ContourSequence.(itemName2).ContourGeometricType;
                             NumberOfContourPoints = NumberOfContourPoints + RTSS.ROIContourSequence.(itemName).ContourSequence.(itemName2).NumberOfContourPoints;

                          end

                        end
                    end
                    end
                end

                obj.mVOIs.(VOIname).TotalNumberOfContourPoints = NumberOfContourPoints;

            catch ex
%              obj.mVOIs.(VOIname) = [];
               disp(['Could not read voi ' VOIname]); 
               disp(ex.message); 
            end
          end
            
            % read the contour data of the delineated VOIs      
            for i=1:numel(fieldnames(obj.mVOIs))

                try

                    VOIname = strcat('VOI_',int2str(i));
                    if obj.mVOIs.(VOIname).TotalNumberOfContourPoints > 0
                        obj.mVOIs.(VOIname).hasContourData = 1;
                        ContourData = zeros(obj.mVOIs.(VOIname).TotalNumberOfContourPoints,4);
                        for j = 1:numel(fieldnames(RTSS.ROIContourSequence))

                            itemName = strcat('Item_',int2str(j));
                            
                            if ~isempty(cell2mat( strfind(fieldnames(RTSS.ROIContourSequence.(itemName)),'ReferencedROINumber')))
                            if obj.mVOIs.(VOIname).ROINumber == RTSS.ROIContourSequence.(itemName).ReferencedROINumber

                                if ~isempty(cell2mat( strfind(fieldnames(RTSS.ROIContourSequence.(itemName)),'ContourSequence')))
                                    flag = 0;
                                    nn = 1;
                                    for k = 1:numel(fieldnames(RTSS.ROIContourSequence.(itemName).ContourSequence))

                                        itemName2 = strcat('Item_',int2str(k));
                                        NumberOfContourPoints = RTSS.ROIContourSequence.(itemName).ContourSequence.(itemName2).NumberOfContourPoints;
                                        zPosition(k) = RTSS.ROIContourSequence.(itemName).ContourSequence.(itemName2).ContourData(3);

                                        if k > 1 && zPosition(k) ~= zPosition(k-1)
                                            flag = 1;
                                        elseif k == 1
                                            flag = 1; 
                                        else
                                            flag = flag + 1;
                                        end


                                        ContourData(nn:nn+NumberOfContourPoints-1,1:3)  = ...
                                                  reshape(RTSS.ROIContourSequence.(itemName).ContourSequence.(itemName2).ContourData, [],NumberOfContourPoints)';

                                        ContourData(nn:nn+NumberOfContourPoints,4) = flag;
                                            nn = nn + NumberOfContourPoints;


                                    end

                                    obj.mVOIs.(VOIname).ContourData = unique(ContourData(1:obj.mVOIs.(VOIname).TotalNumberOfContourPoints,:),'rows','stable');
                                    clear ContourData  
                                end

                            end
                            end

                        end                
                    else
                        obj.mVOIs.(VOIname).hasContourData = 0;    
                    end
                
                catch ex
                   obj.mVOIs.(VOIname).hasContourData = 0;    
                   disp(['Could not read contour data for roi ' VOIname]); 
                   disp(ex.message); 
                end
                
            end
            
             clear VOIname i j k n nn itemNane itemName2
        end
        
        % ----------------------------------------------------------------------------------------------
        % calculates the coordinates of each VOI contourData in the indexed
        % coordinate system for plotting purposes
        % ----------------------------------------------------------------------------------------------
         function CalculateVOIindexedCoordinates(obj,CTinfo)
             
             EBTSceneController = GetGlobalVar('EBTSceneController');
             CTImageSet = EBTSceneController.CTImageSet;
             
             ImagePositionPatient = zeros(CTImageSet.mNumberOfImages,3);
             for i = 1:CTImageSet.mNumberOfImages
                 ImagePositionPatient(i,:) = double(CTImageSet.mImagesInfos{i,1}.ImagePositionPatient)';
             end
             
             for i=1:numel(fieldnames(obj.mVOIs))
                 
                VOIname = strcat('VOI_',int2str(i)); 
                
                if obj.mVOIs.(VOIname).hasContourData == 1
                  obj.mVOIs.(VOIname).indexedContourData(:,1) = 1 + (obj.mVOIs.(VOIname).ContourData(:,1) - ImagePositionPatient(1,1))./CTImageSet.mImagesInfos{1,1}.PixelSpacing(1);
                  obj.mVOIs.(VOIname).indexedContourData(:,2) = 1 + (obj.mVOIs.(VOIname).ContourData(:,2) - ImagePositionPatient(1,2))./CTImageSet.mImagesInfos{1,1}.PixelSpacing(2);
                  obj.mVOIs.(VOIname).indexedContourData(:,3) = 1 + (obj.mVOIs.(VOIname).ContourData(:,3) - ImagePositionPatient(1,3))./CTImageSet.SliceDistance;
                  
                  obj.mVOIs.(VOIname).indexedContourData(:,4) = obj.mVOIs.(VOIname).ContourData(:,4);
                end
                
            end
            
         end
        
            
    end
    
end


       

