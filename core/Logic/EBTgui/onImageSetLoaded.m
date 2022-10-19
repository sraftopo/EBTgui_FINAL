% This function is raised when an image set (CT sequence) is loaded, in order
% to define global variables that are related to the CT data
function onImageSetLoaded()

    EBTSceneController = GetGlobalVar('EBTSceneController');

    CTImageSet = EBTSceneController.CTImageSet;

    SetGlobalVar('CTWindow', CTImageSet.mWindowWidth);
    SetGlobalVar('CTLevel', CTImageSet.mWindowCenter);
    SetGlobalVar('InitialCTLevel', CTImageSet.mWindowCenter);
    SetGlobalVar('InitialCTWindow', CTImageSet.mWindowWidth);
    SetGlobalVar('MinSlice',1);
    SetGlobalVar('MaxSlice', CTImageSet.mNumberOfImages);
    SetGlobalVar('CurrentSlice',uint16(CTImageSet.mNumberOfImages/2));

    % update multiview settings
    MaxAxialSlice = GetGlobalVar('MaxAxialSlice');
    maxAxialCTSlice = CTImageSet.mNumberOfImages;
    if maxAxialCTSlice > MaxAxialSlice
        SetGlobalVar('MaxAxialSlice',maxAxialCTSlice);
    end

    MaxCoronalSlice = GetGlobalVar('MaxCoronalSlice');
    maxCoronalCTSlice = size(CTImageSet.mImagesData,1);
    if maxCoronalCTSlice > MaxCoronalSlice
        SetGlobalVar('MaxCoronalSlice',maxCoronalCTSlice);
    end

    MaxSagittalSlice = GetGlobalVar('MaxSagittalSlice');
    maxSagittalCTSlice = size(CTImageSet.mImagesData,2);
    if maxSagittalCTSlice > MaxSagittalSlice
        SetGlobalVar('MaxSagittalSlice',maxSagittalCTSlice);
    end

    % If the ViewPosition global var has not been defined, set it to
    % the center of the currently loaded dataset
    if(isempty(GetGlobalVar('ViewPosition')))
        ViewPosition.Axial = uint16(CTImageSet.mNumberOfImages/2);
        ViewPosition.Sagittal = uint16(GetGlobalVar('MaxSagittalSlice')/2);
        ViewPosition.Coronal = uint16(GetGlobalVar('MaxCoronalSlice')/2);
        SetGlobalVar('ViewPosition',ViewPosition);
    end

    SetGlobalVar('ShowCT',1);
end
