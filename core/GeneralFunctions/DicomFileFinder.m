function [ outResult, completeFileList, errormsg] = DicomFileFinder( varargin )
errormsg = [];
%Define search modality
if(nargin) > 0
   searchModality = varargin{1}; 
else
    searchModality = {'CT'};
end

%Get search path from input
if(nargin) > 1
    inputPath = varargin{2};
else
    inputPath = '';
end

guiHandle = 0;
if(nargin) > 2
    guiHandle= varargin{2};
end

loadingBarHandle = 0;
if(nargin) > 3
    loadingBarHandle = varargin{3};
end

%FINDANDCATEGORIZEDICOM Summary of this function goes here
%   Detailed explanation goes here
       listOfPatients = {};
       listOfCTfiles  = {};
       listOfMRfiles  = {};
       listOfRDfiles  = {};
       listOfRPfiles  = {};
       listOfRSfiles  = {};
       completeFileList = {};
       
startFolder = pwd;

% IDENTIFY SEARCH PATH
if strcmp(inputPath,'')
   % inputPath = pwd;
end


    %First check to see if the given path contains data
    if strcmp(inputPath,'')
        path = uigetdir(GetGlobalVar('LastSearchPath'),['Please, select the directory where  ', searchModality{1}, ' files are stored located']);
    else
        path = inputPath;
    end
    if isequal(path, 0)
        outResult = 0; 
        cd(startFolder);
        return
    end
    
    SetGlobalVar('LastSearchPath',path)
    set( gcf, 'Pointer', 'watch' ); drawnow;
    
    %SEARCH FOR FILES WITHIN THIS PATH   
    cd(path);
    [stat, struct] = fileattrib('*.*');

    if isequal(stat,0) 
        outResult = 0;
        cd(startFolder);
        return;
    else
        
        %Number of total files in the selected folder
        totalFilesInFolder = size(struct,2);
        %%%disp(['--- ' num2str(totalFilesInFolder) ' files were found in the selected directory ---']);
        if totalFilesInFolder>1000;
            cd(startFolder);
%             er = msgbox('The selected directory contains many files. Please select an inner directory to narrow your search','Warning');
%                 set(er,'units','pixels');
%                 pos = get(er,'position');
%                 hMainGuiPos = get(getappdata(0,'hMainGui'),'position');
%                 hLoadGuiPos  = [hMainGuiPos(1) + ((hMainGuiPos(3)-790)/2), hMainGuiPos(2) + ((hMainGuiPos(4)-560)/2), 790, 500];
%                 msgPos = [hMainGuiPos(1) + ((hMainGuiPos(3)-pos(3))/2), hMainGuiPos(2) + ((hMainGuiPos(4)-pos(4))/2), pos(3),pos(4)];
%                 set(er,'position',msgPos);
%             waitfor(er);
            outResult = -1;
            errormsg = 'The selected directory contains many files. Please narrow your search';
            return;
           %%%disp('Warning : scanning through such large number of files might take some time...'); 
        end


    %INITIALIZE SEARCH OPTIONS
    customAttrs{1,1} = 'PatientID';
    customAttrs{2,1} = 'PatientName';
    customAttrs{3,1} = 'StudyInstanceUID';
    customAttrs{4,1} = 'SeriesInstanceUID';
    customAttrs{5,1} = 'Modality';
    customAttrs{6,1} = 'StudyDescription';
    customAttrs{7,1} = 'SeriesDescription';
    customAttrs{8,1} = 'SOPInstanceUID';
    
    for i = 1:size(customAttrs,1);
       [g n] = dicomlookup( customAttrs{i,1});
       customAttrs{i,2} = g;
       customAttrs{i,3} = n;
    end


    %h = waitbar(0,'Scanning directory for DICOM files...');
    %Loop through all files in the selected folder
    progressArray = ones(20,790); %%%WARNING : VALUE 760 MIGHT CHANGE ACCORDING TO ARRAYSIZE
    progressHalf = 560;
    completeFileList = cell(totalFilesInFolder,9);   
    totalDCMfiles = 0;
    
    if loadingBarHandle ~= 0 && guiHandle ~= 0 
        set(guiHandle,'visible','on');
        bar = imshow(progressArray,  'Parent', loadingBarHandle);
        set(bar,'EraseMode','normal'); 
        text(2,12,'Scanning directory for dicom files...','Parent',loadingBarHandle,'units','pixels','HorizontalAlignment','left','Color',[1, 0.694, 0.392],'FontSize',12.0);  
    end

	%---------------------------------------------------------------------------------------------------------
	for currentDCMfile = 1:totalFilesInFolder
	%---------------------------------------------------------------------------------------------------------  

            if GetGlobalVar('cancelLoading')==1
                outResult = 0;
                cd(startFolder);
                return;
            else
               p = uint16(progressHalf*currentDCMfile/totalFilesInFolder);
               progressArray(1:20,1:p) = 0; 
               %imshow(progressArray);
               if loadingBarHandle ~= 0 
                    set(bar,'CData',progressArray)
                    drawnow;
               end
            end
        try
	%---------------------------------------------------------------------------------------------------------    


        %Read dicom file info (if the file is dicom)
        try
            if (~isdicom(struct(currentDCMfile).Name)); continue; end;
            currentDCMInfo = dicominfo(struct(currentDCMfile).Name);             
        catch ex   
        	continue;
        end

        %Parse modality
        Modality = getField(currentDCMInfo,'Modality');
            
        %If modality does not belong to DESIRED file type, continue
        if Modality < 0;          
            continue; 
        elseif (max(strcmp(Modality,searchModality))~=1) 

            continue; 

        end
            
            PatientID = num2str(getField(currentDCMInfo,'PatientID'));
            if PatientID<0;         continue; end
            SeriesInstanceUID = getField(currentDCMInfo,'SeriesInstanceUID');
            if SeriesInstanceUID<0; continue; end
            SOPInstanceUID = getField(currentDCMInfo,'SOPInstanceUID');
            if SOPInstanceUID<0; continue; end
            StudyInstanceUID = getField(currentDCMInfo,'StudyInstanceUID');
            if StudyInstanceUID<0;  continue; end
            PatientName = getField(currentDCMInfo.PatientName,'FamilyName');
            if PatientName<0;      PatientName = 'No description available';  end  
            StudyDescription = getField(currentDCMInfo,'StudyDescription');    
            if StudyDescription<0; 
            	a = regexp(struct(currentDCMfile).Name, '\', 'split');
            	desc = a(1,end);
            	StudyDescription = char(desc); 
            	%StudyDescription = 'No description found'
            end            
            SeriesDescription = getField(currentDCMInfo,'SeriesDescription');
            if SeriesDescription<0; 
            	a = regexp(struct(currentDCMfile).Name, '\', 'split');
            	desc = a(1,end);
            	SeriesDescription = char(desc); 
            	%SeriesDescription = 'No description found'
            end         
        
            if strcmp([completeFileList{:,9}],SOPInstanceUID)==0
                totalDCMfiles = totalDCMfiles+1;
                completeFileList{totalDCMfiles,1} = PatientID;
                completeFileList{totalDCMfiles,2} = SeriesInstanceUID;
                completeFileList{totalDCMfiles,3} = StudyInstanceUID;
                completeFileList{totalDCMfiles,4} = PatientName;
                completeFileList{totalDCMfiles,5} = Modality;
                completeFileList{totalDCMfiles,6} = struct(currentDCMfile).Name;
                completeFileList{totalDCMfiles,7} = StudyDescription;
                completeFileList{totalDCMfiles,8} = SeriesDescription;
                completeFileList{totalDCMfiles,9} = SOPInstanceUID;
                completeFileList{totalDCMfiles,10} = currentDCMInfo;
            else
                disp(['Multiple : ', SOPInstanceUID]);
            end
            
        catch ex  
             %In debug mode, an error "Could not open file for reading"
             %might occur. It happens when subfolders exist. Ignore it.
             if(isempty(findstr(ex.message, 'open file for reading')))
                if(GetGlobalVar('DEBUG_MODE')); 
                    disp(ex.message); 
                end;
                errorReport('DicomFileFinder',ex);
             end
             
        end
        

    end
 
	%--------------------------------------------------------------------------------------------------------- 
  
  
    %close(h);
    end
   
    %Reorganize list to remove empty rows
    completeFileList( all(cellfun(@isempty,completeFileList),2), : ) = [];
    
    
    %Return to working path with success = 1
    cd(startFolder);
    if totalDCMfiles > 0
        outResult = 1;
    else
        outResult = -1;
        errormsg = 'No dicom files of the selected modality were found in this directory';
    end
    

    
    function result = getField(info, field)
        result = -1;
        try
            result = info.(field);
        catch ex            
           % errorReport('findAndCategorizeDicom:147',ex);
        end
    end

end
