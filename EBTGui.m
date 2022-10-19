function varargout = EBTgui(varargin)
% EBTGUI MATLAB code for EBTgui.fig
%      EBTGUI, by itself, creates a new EBTGUI or raises the existing
%      singleton*.
%
%      H = EBTGUI returns the handle to a new EBTGUI or the handle to
%      the existing singleton*.
%
%      EBTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EBTGUI.M with the given input arguments.
%
%      EBTGUI('Property','Value',...) creates a new EBTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EBTgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EBTgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EBTgui

% Last Modified by GUIDE v2.5 30-Jun-2018 13:09:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EBTgui_OpeningFcn, ...
                   'gui_OutputFcn',  @EBTgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before EBTgui is made visible.
function EBTgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EBTgui (see VARARGIN)

% Choose default command line output for EBTgui
handles.output = hObject;

setappdata(0,'hFilmGUI', gcf);
setGuiIcon(gcf);
InitializeEBTGui(handles);

%Create an empty instance of scene controller
EBTSceneController = EBTController();
SetGlobalVar('EBTSceneController',EBTSceneController);

SetGlobalVar('ViewMode',Views.Axial);
SetGlobalVar('FilmViewMode',FilmViews.Total);

%Store the main axes handle
SetGlobalVar('CTViewer',handles.axesCT);
SetGlobalVar('FilmViewer',handles.axesFilm);

%Get an instance of the current java frame
jFrame = get(handle(gcf), 'JavaFrame');
jFrame.showTopSeparator(false);

% Standard Java JSlider (20px high if no ticks/labels, otherwise use 45px)
jMainSlider = javax.swing.JSlider;
[handles.hScrollSlider, hContainer] = javacomponent(jMainSlider,[10,10,30,200]);
set(jMainSlider, 'Value',72, 'Orientation',jMainSlider.HORIZONTAL, 'MinorTickSpacing',5);
set(hContainer, 'units', get(handles.sliderPlaceholder, 'units'), 'parent', handles.uipanelviewing);
set(hContainer,'position', get(handles.sliderPlaceholder, 'position')); %note container size change

% Standard Java JSlider (20px high if no ticks/labels, otherwise use 45px)
jZoomSlider = javax.swing.JSlider;
[handles.hZoomSlider, hZoomContainer] = javacomponent(jZoomSlider,[10,10,30,200]);
set(jZoomSlider, 'Value',0.0,'Minimum',0.0,'Maximum',100.0, 'Orientation',jZoomSlider.VERTICAL, 'MinorTickSpacing',5);
set(hZoomContainer, 'units', get(handles.zoomPlaceholder, 'units'), 'parent', handles.uipanelviewing);
set(hZoomContainer,'position', get(handles.zoomPlaceholder, 'position')); %note container size change
% UIWAIT makes EBTgui wait for user response (see UIRESUME)
% uiwait(handles.EBTgui);
set(handles.togglebuttonTrippleChannel,'Enable','off');

% set(handles.btnLoadRTSS,'Enable','off');

% Update handles structure
guidata(hObject, handles);


%-------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = EBTgui_OutputFcn(hObject, eventdata, handles)

  varargout{1} = handles.output;



%-------------------------------------------------------------------------
function ResetGUI(handles)

    % Close DVH gui if it is open
    if ishandle(GetGlobalVar('hDVHGui'))
        close(GetGlobalVar('hDVHGui'));
    end

    % Close PROFILE 1D gui if it is open
    if ishandle(GetGlobalVar('hProfileComparisonGui'))
        close(GetGlobalVar('hProfileComparisonGui'));
    end

    % Close GAMMA 2D gui if it is open
    if ishandle(GetGlobalVar('hGammaIndexGui'))
        close(GetGlobalVar('hGammaIndexGui'));
    end   
    

    % Disable gui action buttons
    % These should only be those buttons that have nothing to do with loading data
    % as we don't want to disable loading
    set(handles.btnShowCT,'enable','off');
    set(handles.btnShowVois,'enable','off');
    set(handles.btnShowTPSIsodoses,'enable','off');
    set(handles.btnResetWindowLevel,'Enable','off');
    set(handles.btnColormap,'Enable','off');
    set(handles.pnReportButtons,'visible', 'off');

    % Reset lables for level/window, current slice and pixel values
    set(handles.lbCurrentSlice,'String','');
    set(handles.lbDoseMethod,'String','');
    set(handles.lbWindow,'String','');
    set(handles.lbCTValue,'String','');

    % Reset the panels
    ResetDoseCalculationPanels(handles);

    % Remove isodose levels controls
    toggleIsodoseControls(handles, 'off');

    % Reset the scene controller
    EBTSceneController = GetGlobalVar('EBTSceneController');
    EBTSceneController.Reset();
    SetGlobalVar('EBTSceneController', EBTSceneController);

    % Disable sliders and callbacks
    set(handles.hScrollSlider,'enable',0);
    set(handles.hZoomSlider,'enable',0);
    set(gcf,'WindowScrollWheelFcn',{@WindowScrollFcn, handles});
    set(handles.hScrollSlider,'StateChangedCallback',@(hObject, event) noCallback);
    set(gcf,'WindowButtonMotionFcn',@noCallback);
    set(gcf,'WindowButtonDownFcn',@noCallback);
    set(gcf,'WindowButtonUpFcn'  ,@noCallback);

    % Call the initialization function
    InitializeAnalysisTool(handles, false);

    % draw an empty image in both viewers
    imshow(0, 'Parent', handles.axesCT);
    imshow(0, 'Parent', handles.axesFilm);


%-------------------------------------------------------------------------
% --- Executes on button press in btnLoadFilmData.
function btnLoadFilmData_Callback(hObject, eventdata, handles)

  EBTSceneController = GetGlobalVar('EBTSceneController');

  % import film images for pre
  [out, message] = EBTSceneController.ImportFilmImages('Pre');

  if out == 0
      MessageBox(message, 'Error Message');
  else
      SetGlobalVar('EBTSceneController', EBTSceneController);
      [out, message] = EBTSceneController.ImportFilmImages('Post');

      if out == 0
          MessageBox(message, 'Error Message');
      else
          SetGlobalVar('EBTSceneController', EBTSceneController);
      end
  end
  UpdateEBTViewer(handles);



%-------------------------------------------------------------------------
% --- Executes on button press in LoadCTdata.
function LoadCTdata_Callback(hObject, eventdata, handles)

    EBTSceneController = GetGlobalVar('EBTSceneController');
    [result, error] = EBTSceneController.ImportPrimaryCTImages();

    %If images have been imported correctly, proceed in setting globals
    if result < 0
        MessageBox(error, 'Import Error');
    else

        %Check if the new data have correct bounds, otherwise notify and
        %exit
        if EBTSceneController.fCTImageSet == 1

            % execute onImageSetLoaded function to update CT-related globals
            onImageSetLoaded();

            % enable w/l reset button
            set(handles.btnResetWindowLevel, 'Enable', 'on');

            % update viewing
            UpdateEBTViewer(handles);
            % Enable gui buttons
            EnableGUI(handles);
            % Set callbacks
            set(gcf,'WindowButtonMotionFcn', @ShowCurrentPixelValue);
            changeLeftClickAction(handles,'ADJUST');
            set(handles.hScrollSlider,'StateChangedCallback',@(hObject, event) hScrollSlider_Callback(hObject, eventdata, handles));
            set(handles.hZoomSlider,'StateChangedCallback',@(hObject, event) hZoomSlider_Callback(hObject, eventdata, handles));
        end

    end

    updateViewAndBounds(handles);



%-------------------------------------------------------------------------
% --- Executes on button press in btnImportTPSRTDose.
function btnImportTPSRTDose_Callback(hObject, eventdata, handles)

    EBTSceneController = GetGlobalVar('EBTSceneController');
    [result, error] = EBTSceneController.ImportTPSRTDose();

    %If images have been imported correctly, proceed in setting globals
    if result < 0
        MessageBox(error, 'Import Error');
    else
        if result == 1 && EBTSceneController.fTPSRTDose == 1

            IsodoseProperties = GetGlobalVar('IsodoseProperties');
            NumberOfIsodoseLines = GetGlobalVar('NumberOfIsodoseLines');

            %WARNING: 5 IS LOCKED TO THE NUMBER OF ISODOSE LINES. IF THIS
            %NUMBER CHANGES, IT MUST BE REDEFINED
            for i = 1:NumberOfIsodoseLines
              set(handles.(['lbIsodose' num2str(i)]),'Visible','on','String',num2str(double(IsodoseProperties.Value(i))));
            end

            %Enable isodose gui controls and re-render scene
            set(handles.btnShowTPSIsodoses,'Enable','on');
            set(handles.btnShowTPSIsodoses,'Value',1);
            SetGlobalVar('ShowTPSIsodoses',1);

            % update global variables according to the new RTDose
            onRTDoseLoaded();

            if EBTSceneController.fMRImageSet == 1
                set(handles.btnProfileMatching,'Enable','on');
                set(handles.btnLoadProfile,'Enable','on');
                set(handles.toggleCalibrationBasedDoseCalculation,'Visible','on');
                set(handles.toggleMinMaxDoseCalculation,'Visible','on');
                set(handles.toggleProfileFitDoseCalculation,'Visible','on');
                set(handles.lbDoseCalculation,'Visible','on');
            end

            UpdateEBTViewer(handles);
            drawnow;
        end
    end


%-------------------------------------------------------------------------
% --- Executes on button press in btnLoadRTSS.
function btnLoadRTSS_Callback(hObject, eventdata, handles)

    % Import CT image set
    EBTSceneController = GetGlobalVar('EBTSceneController');
    [result, error] = EBTSceneController.ImportRTStructureSet();

    %If images have been imported correctly, proceed in setting globals
    if result < 0
        MessageBox(error, 'Import Error');
    else
        if result == 1
            set(handles.btnShowVois,'Value',1);
            set(handles.btnShowVois,'Enable','on');
            SetGlobalVar('ShowVois',1);
            UpdateEBTViewer(handles);
        end
    end


%-------------------------------------------------------------------------
% --- Executes on selection change in popupmenuFilmViewSelection.
function popupmenuFilmViewSelection_Callback(hObject, eventdata, handles)

    % Get current dropdown value
    selectedFilmValue = get(hObject,'Value');
    switch selectedFilmValue
        case FilmViews.Total
           SetGlobalVar('FilmViewMode', FilmViews.Total);
        case FilmViews.Red
           SetGlobalVar('FilmViewMode', FilmViews.Red);
        case FilmViews.Green
           SetGlobalVar('FilmViewMode', FilmViews.Green);
        case FilmViews.Blue
           SetGlobalVar('FilmViewMode', FilmViews.Blue);
    end

    UpdateEBTViewer(handles);


%-------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function popupmenuFilmViewSelection_CreateFcn(hObject, eventdata, handles)

  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end


%-------------------------------------------------------------------------
% --- Executes on selection change in popupmenuCTViewSelection.
function popupmenuCTViewSelection_Callback(hObject, eventdata, handles)

    % Get current dropdown value
    selectedValue = get(hObject,'Value');
    switch selectedValue
        case Views.Axial
           SetGlobalVar('ViewMode', Views.Axial);
        case Views.Coronal
           SetGlobalVar('ViewMode', Views.Coronal);
        case Views.Sagittal
           SetGlobalVar('ViewMode', Views.Sagittal);
    end
    updateViewAndBounds(handles);


%-------------------------------------------------------------------------
function updateViewAndBounds(handles)

    % Alternative approach is to directly get string
    % contents = cellstr(get(hObject,'String')) ;
    % contents{selectedValue};

    EBTSceneController = GetGlobalVar('EBTSceneController');

    try

    %Get the current modality, which is either CT or MR
    currentModality = GetGlobalVar('ShowCT');
    if (currentModality == 1) %CT
        viewBounds = EBTSceneController.CTImageSet.ImageBounds;
    else
        viewBounds = EBTSceneController.MRImageSet.ImageBounds;
    end

    viewModeValue = GetGlobalVar('ViewMode');

    %Update view mode
    switch viewModeValue

       case Views.Axial
           maxSlice     = viewBounds.AxialBounds; %GetGlobalVar('MaxAxialSlice');
           viewPosition =  GetGlobalVar('ViewPosition');
           currentSlice =  viewPosition.Axial;
           SetGlobalVar('ViewMode', Views.Axial);

       case Views.Coronal
           maxSlice     = viewBounds.CoronalBounds; %GetGlobalVar('MaxCoronalSlice');
           viewPosition =  GetGlobalVar('ViewPosition');
           currentSlice =  viewPosition.Coronal;
           SetGlobalVar('ViewMode', Views.Coronal);

       case Views.Sagittal
           maxSlice     = viewBounds.SagittalBounds; %GetGlobalVar('MaxSagittalSlice');
           viewPosition =  GetGlobalVar('ViewPosition');
           currentSlice =  viewPosition.Sagittal;
           SetGlobalVar('ViewMode', Views.Sagittal);
    end

        set(handles.hScrollSlider,'minimum',1);
        set(handles.hScrollSlider,'maximum',maxSlice);
        set(handles.hScrollSlider,'Value',currentSlice);
        SetGlobalVar('MaxSlice',maxSlice);
        SetGlobalVar('CurrentSlice',currentSlice);

        %Update scroll position label
        set(handles.lbCurrentSlice,'String',['Slice :',' ', num2str(currentSlice),'/', num2str(GetGlobalVar('MaxSlice'))]);

        %Re-render scene
        UpdateEBTViewer(handles);

    catch ex
        disp(ex.message);
    end
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%




% --- Executes during object creation, after setting all properties.
function popupmenuCTViewSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCTViewSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




%-------------------------------------------------------------------------%
function EnableGUI(handles)

    set(gcf,'WindowScrollWheelFcn',{@WindowScrollFcn, handles});
    set(handles.hScrollSlider,'minimum',GetGlobalVar('MinSlice'));
    set(handles.hScrollSlider,'maximum',GetGlobalVar('MaxSlice'));
    set(handles.hScrollSlider,'Value',GetGlobalVar('CurrentSlice'));
    set(handles.hScrollSlider,'enable',1);
    set(handles.hZoomSlider,'enable',1);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%



%--------------------------------------------------------------------------
function hScrollSlider_Callback(hObject, eventdata, handles)

    %Get current slider value
    val =  uint16(get(hObject,'Value'));

    %Update viewPosition (warning: this part of code is also executed when
    %scrolling has been performed with the mouse, since this callback is
    %invoked when setting the slider value manually)
    viewPosition = GetGlobalVar('ViewPosition');
    switch GetGlobalVar('ViewMode')
        case Views.Axial
            viewPosition.Axial = val;
        case Views.Coronal
            viewPosition.Coronal = val;
        case Views.Sagittal
            viewPosition.Sagittal = val;
    end
    SetGlobalVar('ViewPosition',viewPosition);
    set(handles.lbCurrentSlice,'String',['Slice :',' ', num2str(get(hObject,'Value')),'/', num2str(GetGlobalVar('MaxSlice'))]);

    SetGlobalVar('CurrentSlice',val);
    UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%




%--------------------------------------------------------------------------
function hZoomSlider_Callback(hObject, eventdata, handles)

		val = get(hObject, 'Value');
    zoomFactor = 1.0 - (0.4*double(val/100.0));
    SetGlobalVar('ZoomFactor', zoomFactor);
    UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%


% --- Executes during object creation, after setting all properties.
function hScrollSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hScrollSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in btnResetWindowLevel.
function btnResetWindowLevel_Callback(hObject, eventdata, handles)
% hObject    handle to btnResetWindowLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    EBTSceneController = GetGlobalVar('EBTSceneController');
    if GetGlobalVar('ShowCT')
        SetGlobalVar('CTWindow',GetGlobalVar('InitialCTWindow'));
        SetGlobalVar('CTLevel',GetGlobalVar('InitialCTLevel'));
        set(handles.lbWindow,'String',['W: ', num2str(GetGlobalVar('CTWindow')), ' L: ', num2str(GetGlobalVar('CTLevel'))]);
        UpdateEBTViewer(handles);
    end




function editTreasholdCT_Callback(hObject, eventdata, handles)
% hObject    handle to editTreasholdCT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTreasholdCT as text
%        str2double(get(hObject,'String')) returns contents of editTreasholdCT as a double
EBTSceneController = GetGlobalVar('EBTSceneController');

VoxelValue = str2double(get(hObject,'String'));
SetGlobalVar('VoxelValue',VoxelValue);

try
    [out, message, NUMCT] = EBTSceneController.FindCTslicesWithFiducials();
    if out == 1
            MessageBox(message, 'Error Message');
    end
catch
    MessageBox('Unable to set threshold. Have you imported the required data?', 'Error');
end
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%



% --- Executes during object creation, after setting all properties.
function editTreasholdCT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTreasholdCT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editThreasholdFilm_Callback(hObject, eventdata, handles)
% hObject    handle to editThreasholdFilm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editThreasholdFilm as text
%        str2double(get(hObject,'String')) returns contents of editThreasholdFilm as a double
EBTSceneController = GetGlobalVar('EBTSceneController');

PixelValue = str2double(get(hObject,'String'));
SetGlobalVar('PixelValue',PixelValue);

try
    [out, message, NUMFILM] = EBTSceneController.FindFilmFiducials();

    if out == 1
            MessageBox(message, 'Result');
    end
catch
   MessageBox('Unable to set threshold. Have you imported the required data?', 'Error');
end
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%



% --- Executes during object creation, after setting all properties.
function editThreasholdFilm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editThreasholdFilm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in btnShowTPSIsodoses.
function btnShowTPSIsodoses_Callback(hObject, eventdata, handles)
% hObject    handle to btnShowTPSIsodoses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnShowTPSIsodoses
    if get(hObject,'Value') == 1
        visible = 'on';
    else
        visible = 'off';
    end
    toggleIsodoseControls(handles, visible);
    drawnow;
    SetGlobalVar('ShowTPSIsodoses',get(hObject,'Value'));
    UpdateEBTViewer(handles);



%--------------------------------------------------------------------------
% Shows/hides isodose value controles
function toggleIsodoseControls(handles, val)

    NumberOfIsodoseLines = GetGlobalVar('NumberOfIsodoseLines');
    for i = 1:NumberOfIsodoseLines
       set(handles.(['lbIsodose' num2str(i)]),'Visible',val);
    end

%--------------------------------------------------------------------------
function lbIsodose5_Callback(hObject, eventdata, handles)
    UpdateIsodoseValue(hObject, handles, 5);
%--------------------------------------------------------------------------
function lbIsodose4_Callback(hObject, eventdata, handles)
    UpdateIsodoseValue(hObject, handles, 4);
%--------------------------------------------------------------------------
function lbIsodose3_Callback(hObject, eventdata, handles)
    UpdateIsodoseValue(hObject, handles, 3);
%--------------------------------------------------------------------------
function lbIsodose2_Callback(hObject, eventdata, handles)
    UpdateIsodoseValue(hObject, handles, 2);
%--------------------------------------------------------------------------
function lbIsodose1_Callback(hObject, eventdata, handles)
    UpdateIsodoseValue(hObject, handles, 1);
%--------------------------------------------------------------------------
function UpdateIsodoseValue(hObject, handles, isodose)

   IsodoseProperties = GetGlobalVar('IsodoseProperties');
    currentString = get(hObject, 'String');
    [newIsodoseValue, status] = str2num(currentString);
    if status == 0 || size(newIsodoseValue,2)>1
        if(strcmp('-',currentString)==1)
            IsodoseProperties.Status(isodose) = 0;
            IsodoseProperties.Value(isodose) = -isodose;
            SetGlobalVar('IsodoseProperties',IsodoseProperties);
            UpdateEBTViewer(handles);
            return;
        else
            set(hObject,'String',num2str(IsodoseProperties.Value(isodose)));
            return;
        end
       return
    else
        if newIsodoseValue >= 0.0 && newIsodoseValue <= 100.0
            if max(IsodoseProperties.Value(1:end ~= isodose) == newIsodoseValue) ~= 1

                IsodoseProperties.Status(isodose) = 1;
                IsodoseProperties.Value(isodose) = newIsodoseValue;
                SetGlobalVar('IsodoseProperties',IsodoseProperties);
                UpdateEBTViewer(handles);
            end
        else

        end

       set(hObject,'String',num2str(IsodoseProperties.Value(isodose)));
       return
    end
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%


% --- Executes on button press in btnEEAE.
function btnEEAE_Callback(hObject, eventdata, handles)
% hObject    handle to btnEEAE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
url = 'http://www.eeae.gr';
web(url, '-browser');


% --- Executes on button press in togglebtnDoseMappingMethods.
function togglebtnDoseMappingMethods_Callback(hObject, eventdata, handles)
% hObject    handle to togglebtnDoseMappingMethods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebtnDoseMappingMethods


% --- Executes on button press in togglebuttonSingleChannel.
function togglebuttonSingleChannel_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonSingleChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonSingleChannel
EBTSceneController = GetGlobalVar('EBTSceneController');

        % Load calibration data
        [FileName,PathName,FilterIndex] = uigetfile({'*.txt';'*.dat'},'Select a Calibration file','Multiselect','off');
        CurrentPath = pwd;
        if FileName > 0
           try

           cd(PathName)
           importedCalibration = importdata(FileName);
           EBTSceneController.CalibrationCoefficients.a = importedCalibration.data(1);
           EBTSceneController.CalibrationCoefficients.b = importedCalibration.data(2);
           EBTSceneController.CalibrationCoefficients.c = importedCalibration.data(3);
           EBTSceneController.fCalibration = 1;
           SetGlobalVar('EBTSceneController',EBTSceneController);
           message = 'Calibration Curve was successfully loaded';
           MessageBox(message, 'Error Message');

           catch ex
               MessageBox('TPS:478',ex);
           end
        end
        %%%%%%


    method = get(hObject,'Value');

    if method == 1
        set(handles.togglebuttonTrippleChannel,'Enable','off');
        handles.togglebuttonTrippleChannel.Value = 0;

    end

cd(CurrentPath);


% UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%




% --- Executes on button press in togglebuttonTrippleChannel.
function togglebuttonTrippleChannel_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonTrippleChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonTrippleChannel
EBTSceneController = GetGlobalVar('EBTSceneController');

method = get(hObject,'Value');

if method == 1
    set(handles.togglebuttonSingleChannel,'Enable','off');

end
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%


% --- Executes on button press in btnShowFilmIsodoses.
function btnShowFilmIsodoses_Callback(hObject, eventdata, handles)
% hObject    handle to btnShowFilmIsodoses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnShowFilmIsodoses
    if get(hObject,'Value') == 1
        visible = 'on';
    else
        visible = 'off';
    end

    drawnow;
    SetGlobalVar('ShowFilmIsodoses',get(hObject,'Value'));
    UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%



% --- Executes on button press in togglebuttonFilmDosemap.
function togglebuttonFilmDosemap_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonFilmDosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonFilmDosemap


% --- Executes on button press in togglebuttonCTdosemap.
function togglebuttonCTdosemap_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonCTdosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonCTdosemap


% --- Executes on button press in btnCalculateODmapDosemap.
function btnCalculateODmapDosemap_Callback(hObject, eventdata, handles)
% hObject    handle to btnCalculateODmapDosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EBTSceneController = GetGlobalVar('EBTSceneController');

% Calculate OD map
[out, message ] = EBTSceneController.CalculateFilmODmap();

if out == 0
    MessageBox(message, 'Error Message');
    return;
else
SetGlobalVar('EBTSceneController',EBTSceneController);

MessageBox(message, 'Success');

end

% Calculate Film Dosemap
[out, message ] = EBTSceneController.CalculateDosemap();

if out == 0
    MessageBox(message, 'Error Message');
else
SetGlobalVar('EBTSceneController',EBTSceneController);

MessageBox(message, 'Error Message');

end


    %If images have been imported correctly, proceed in setting globals
    if out == 0
        MessageBox(error, 'Import Error');
    else
        if out == 1 && EBTSceneController.fDosemapSingleChannel == 1

            %Enable isodose gui controls and re-render scene
            set(handles.btnShowFilmIsodoses,'Enable','on');
            set(handles.btnShowFilmIsodoses,'Value',1);
            SetGlobalVar('ShowFilmIsodoses',1);


            UpdateEBTViewer(handles);
            drawnow;
        end
    end


% --- Executes on button press in togglebutton3DCRT.
function togglebutton3DCRT_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton3DCRT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton3DCRT
EBTSceneController = GetGlobalVar('EBTSceneController');

if isempty(EBTSceneController.SingleChannel)
    MessageBox('Not enough data to perform this operation', 'Error');
    set(handles.togglebuttonIMRT_VMAT,'Enable','on');
    return;
end

method = get(hObject,'Value');

if method == 1
    set(handles.togglebuttonIMRT_VMAT,'Enable','off');
    handles.togglebuttonIMRT_VMAT.Value = 0;
end

% Film Normalization point
Dpr = 5;
Film.thresDose = 0.9* Dpr;

bw  = (EBTSceneController.SingleChannel.FilmDose > Film.thresDose);

figure, imshow(bw, [0 1]); impixelinfo;
bw1 = imclearborder(bw);      imshow(bw1); impixelinfo;
bw2 = bwareaopen(bw1,10);     imshow(bw2); impixelinfo;    % select an adequate threshold for
                                                                           % the No of pixels that a detected
                                                                           % area should have in order to keep
                                                                           % it!
[bw3film, ~] = bwlabeln(bw2);
imshow(bw3film); impixelinfo;  close;

statsFilmC = regionprops(bw3film,'Basic');
filmCenters = size(statsFilmC,1);
for i = 1:filmCenters
    Film.dose.centroids(i,:) = statsFilmC(i,1).Centroid ;
end


j = 1;
for i = 1:filmCenters

    if statsFilmC(i).Area < 20 % Delete big holes (no fiducials holes) and scanned image background

        a = statsFilmC(i).Centroid;
        DoseCentroids(j,:) = a;
        j = j + 1;

        clear a

    end

end

figure, plot(EBTSceneController.SingleChannel.FilmDose(round(statsFilmC.Centroid(1,2)),:));
h1 = imrect();
posRectDose = int32(getPosition(h1)); close;

FilmNORM = mean(EBTSceneController.SingleChannel.FilmDose(round(statsFilmC.Centroid(1,2)),posRectDose(1):posRectDose(1)+posRectDose(3)))


% RTdose Normalization point
Dpr = 5;
Film.thresDose = 0.8*Dpr;

bw  = (EBTSceneController.CT2FilmSlice_DOSE > Film.thresDose);  figure, imshow(bw, [0 1]); impixelinfo;
bw1 = imclearborder(bw);              imshow(bw1); impixelinfo;
bw2 = bwareaopen(bw1,1);             imshow(bw2); impixelinfo;    % select an adequate threshold for
                                                                           % the No of pixels that a detected
                                                                           % area should have in order to keep
                                                                           % it!
[bw3film, n] = bwlabeln(bw2);         imshow(bw3film); impixelinfo;

statsDoseC = regionprops(bw3film,'Basic');
filmCenters = size(statsDoseC,1); close;
for i = 1:filmCenters
    Film.dose.centroids(i,:) = statsDoseC(i,1).Centroid ;
end


j = 1;
for i = 1:filmCenters

    if statsDoseC(i).Area < 20 % Delete big holes (no fiducials holes) and scanned image background

        a = statsDoseC(i).Centroid;
        DoseCentroids(j,:) = a;
        j = j + 1;

        clear a

    end

end



figure, plot(EBTSceneController.CT2FilmSlice_DOSE(round(statsFilmC.Centroid(1,2)),:));
h1 = imrect();
posRectDose = int32(getPosition(h1)); close;

RTdoseNORM = mean(EBTSceneController.CT2FilmSlice_DOSE(round(statsFilmC.Centroid(1,2)),posRectDose(1):posRectDose(1)+posRectDose(3)))

diff = ((RTdoseNORM - FilmNORM)/FilmNORM)*100

EBTSceneController.Normalization.NormalizedFilmDoseFINAL = (EBTSceneController.SingleChannel.FilmDose./FilmNORM)*100 ;
EBTSceneController.Normalization.NormalizedRTdoseFINAL = (EBTSceneController.CT2FilmSlice_DOSE./RTdoseNORM)*100 ;

% UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%



% --- Executes on button press in togglebuttonIMRT_VMAT.
function togglebuttonIMRT_VMAT_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonIMRT_VMAT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonIMRT_VMAT
EBTSceneController = GetGlobalVar('EBTSceneController');

if isempty(EBTSceneController.SingleChannel)
    MessageBox('Not enough data to perform this operation', 'Error');
    set(handles.togglebutton3DCRT,'Enable','on');
    return;
end

method = get(hObject,'Value');

if method == 1
    set(handles.togglebutton3DCRT,'Enable','off');
    handles.togglebutton3DCRT.Value = 0;
end

% Get profile
[xIndices, yIndices,profValues,xEndPoints,yEndPoints] = improfile;

figure, plot(EBTSceneController.SingleChannel.FilmDose(:,round(yEndPoints)));
h1 = imrect();
posRectDose = int32(getPosition(h1)); close; clear h1;

EBTSceneController.Normalization.FilmNORM = mean2(EBTSceneController.SingleChannel.FilmDose(round(yEndPoints),posRectDose(1):posRectDose(1)+posRectDose(3)))

figure, plot(EBTSceneController.CT2FilmSlice_DOSE(:,round(yEndPoints)));
h1 = imrect();
posRectDose = int32(getPosition(h1)); close; clear h1;

EBTSceneController.Normalization.RTdoseNORM = mean2(EBTSceneController.CT2FilmSlice_DOSE(round(yEndPoints),posRectDose(1):posRectDose(1)+posRectDose(3)))

EBTSceneController.Normalization.diff = ((EBTSceneController.Normalization.RTdoseNORM - EBTSceneController.Normalization.FilmNORM)/...
    EBTSceneController.Normalization.FilmNORM)*100 ;

EBTSceneController.Normalization.NormalizedFilmDoseFINAL = (EBTSceneController.SingleChannel.FilmDose./EBTSceneController.Normalization.FilmNORM)*100 ;
EBTSceneController.Normalization.NormalizedRTdoseFINAL = (EBTSceneController.CT2FilmSlice_DOSE./EBTSceneController.Normalization.RTdoseNORM)*100 ;
SetGlobalVar('EBTSceneController',EBTSceneController);

% UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%




% --- Executes on button press in GammaMap.
function GammaMap_Callback(hObject, eventdata, handles)
% hObject    handle to GammaMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Calculate Film Dosemap
EBTSceneController = GetGlobalVar('EBTSceneController');
if isempty(EBTSceneController.Normalization)
    MessageBox('Not enough data to perform this operation', 'Error');
    set(handles.togglebuttonIMRT_VMAT,'Enable','on');
    return;
end

% Select rectangular to perform comparison
isCallbackDisabled = GetGlobalVar('DisableCallbacks');

if ~isempty(isCallbackDisabled)
    hRect = GetGlobalVar('RectRoiComparisonHandle');
    if ~isempty(hRect)
       delete(hRect);
    end
    SetGlobalVar('DisableCallbacks', []);
    openGammaIndexGui();
    return;
end


SetGlobalVar('DisableCallbacks', 1);
EBTSceneController = GetGlobalVar('EBTSceneController');
Film = EBTSceneController.Normalization.NormalizedFilmDoseFINAL;
FilmSize = size(Film);
xSize = FilmSize(1)/7;
ySize = FilmSize(2)/7;
hRect = imrect(handles.axesFilm, [xSize, ySize, 2*xSize, 2*ySize]);
SetGlobalVar('RectRoiComparisonHandle', hRect);
addNewPositionCallback(hRect,@(p) onComparisonRectUpdate(p,hObject, handles));


function onComparisonRectUpdate(position, rect, handles)

EBTSceneController = GetGlobalVar('EBTSceneController');
Film = EBTSceneController.Normalization.NormalizedFilmDoseFINAL;
RTDose = EBTSceneController.Normalization.NormalizedRTdoseFINAL;
position = floor(position);
iStart = position(1);
jStart = position(2);
iEnd = iStart + position(3);
jEnd = jStart + position(4);
iRange = iStart:iEnd;
jRange = jStart:jEnd;
xRange = EBTSceneController.CTImageSet.ImageCoordinates.x(jRange);
yRange = EBTSceneController.CTImageSet.ImageCoordinates.y(iRange);

FilmDoseForGammaIndex = Film(jStart:jEnd, iStart:iEnd);
RTDoseForGammaIndex = RTDose(jStart:jEnd, iStart:iEnd);
SetGlobalVar('FilmDoseForGammaIndex', FilmDoseForGammaIndex);
SetGlobalVar('RTDoseForGammaIndex', RTDoseForGammaIndex);
SetGlobalVar('xRangeForGammaIndex', xRange);
SetGlobalVar('yRangeForGammaIndex', yRange);



function openGammaIndexGui()

FilmDoseForGammaIndex = GetGlobalVar('FilmDoseForGammaIndex');
RTDoseForGammaIndex = GetGlobalVar('RTDoseForGammaIndex');
xRange = GetGlobalVar('yRangeForGammaIndex');
yRange = GetGlobalVar('xRangeForGammaIndex');

[XCoords, YCoords] = meshgrid( xRange, yRange);
InputData.Film_norm = FilmDoseForGammaIndex;
InputData.tps_norm_interp = RTDoseForGammaIndex;

InputData.Norm.TPSDose = RTDoseForGammaIndex;
InputData.Norm.FilmDose = FilmDoseForGammaIndex;
InputData.Norm.TPSDoseInterp = RTDoseForGammaIndex;

InputData.GY.TPSDose = RTDoseForGammaIndex;
InputData.GY.FilmDose = FilmDoseForGammaIndex;
InputData.GY.TPSDoseInterp = RTDoseForGammaIndex;

InputData.XCoords = XCoords;
InputData.YCoords = YCoords;
InputData.XCoordsInterp = XCoords;
InputData.YCoordsInterp = YCoords;
InputData.RTDoseXCoords = XCoords;
InputData.RTDoseYCoords = YCoords;

GammaIndex2DGUI(InputData);


% [out, message ] = EBTSceneController.CalculateGammaMap();
%
% if out == 0
%     MessageBox(message, 'Error Message');
% else
% SetGlobalVar('EBTSceneController',EBTSceneController);
%
% MessageBox(message, 'Error Message');
%
% end
% UpdateEBTViewer(handles);



% --- Executes on button press in pushbuttonImageScaleDosemap.
function pushbuttonImageScaleDosemap_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImageScaleDosemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EBTSceneController = GetGlobalVar('EBTSceneController');

if isempty(EBTSceneController.SingleChannel)
    MessageBox('Not enough data to perform this operation', 'Error');
    return;
end

% Select rectangular to plot
isCallbackDisabled = GetGlobalVar('DisableCallbacks');

if ~isempty(isCallbackDisabled)
    hRect = GetGlobalVar('RectRoiComparisonHandle');
    if ~isempty(hRect)
       delete(hRect);
    end
    SetGlobalVar('DisableCallbacks', []);
    plotDosemaps();
    return;
end

SetGlobalVar('DisableCallbacks', 1);
EBTSceneController = GetGlobalVar('EBTSceneController');
Film = EBTSceneController.SingleChannel.FilmDose;
FilmSize = size(Film);
xSize = FilmSize(1)/7;
ySize = FilmSize(2)/7;
hRect = imrect(handles.axesFilm, [xSize, ySize, 2*xSize, 2*ySize]);
SetGlobalVar('RectRoiComparisonHandle', hRect);
addNewPositionCallback(hRect,@(p) onComparisonRectUpdate2(p,hObject, handles));


function onComparisonRectUpdate2(position, rect, handles)

EBTSceneController = GetGlobalVar('EBTSceneController');
Film = EBTSceneController.SingleChannel.FilmDose;
RTDose = EBTSceneController.CT2FilmSlice_DOSE;
position = floor(position);
iStart = position(1);
jStart = position(2);
iEnd = iStart + position(3);
jEnd = jStart + position(4);
iRange = iStart:iEnd;
jRange = jStart:jEnd;
xRange = EBTSceneController.CTImageSet.ImageCoordinates.x(jRange);
yRange = EBTSceneController.CTImageSet.ImageCoordinates.y(iRange);

FilmDose = Film(jStart:jEnd, iStart:iEnd);
RTDosemap = RTDose(jStart:jEnd, iStart:iEnd);
SetGlobalVar('FilmDoseForGammaIndex', FilmDose);
SetGlobalVar('RTDoseForGammaIndex', RTDosemap);
SetGlobalVar('xRangeForGammaIndex', xRange);
SetGlobalVar('yRangeForGammaIndex', yRange);


function plotDosemaps(position, rect, handles)
EBTSceneController = GetGlobalVar('EBTSceneController');
FilmDose = GetGlobalVar('FilmDoseForGammaIndex');
RTDosemap = GetGlobalVar('RTDoseForGammaIndex');
y = GetGlobalVar('yRangeForGammaIndex');
x = GetGlobalVar('xRangeForGammaIndex');
Slice2Plot = EBTSceneController.meanZcoordinate ;
figure;
% createfigureDosemaps(EBTSceneController.CT2FilmSlice_DOSE,EBTSceneController.SingleChannel.FilmDose);
subplot(1,3,2);
imagesc(y,x,RTDosemap);
daspect([1 1 1]);
colorbar('fontsize',10,'color',[0 0 0],'fontweight','b');
colormap(jet); %freezeColors;
hold on;
daspect([1 1 1])
caxis([0 5])
title(strcat('RTDOSE @ z=',num2str(Slice2Plot),'mm'),'FontWeight','bold')
xlabel('x axis (mm)','fontsize',12)
ylabel('y axis (mm)','fontsize',12)

%createfigureDosemaps(EBTSceneController.SingleChannel.FilmDose);
subplot(1,3,1);
imagesc(y,x,FilmDose);
daspect([1 1 1]);
colorbar('fontsize',10,'color',[0 0 0],'fontweight','b');
colormap(jet); %freezeColors;
hold on;
daspect([1 1 1])
caxis([0 5])
title(strcat('FILM @ z=',num2str(Slice2Plot),'mm'),'FontWeight','bold')
xlabel('x axis (mm)','fontsize',12)
ylabel('y axis (mm)','fontsize',12)

% UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%


% --- Executes on button press in btnShowVois.
function btnShowVois_Callback(hObject, eventdata, handles)
% hObject    handle to btnShowVois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnShowVois
    if get(hObject,'Value') == 1
        visible = 'on';
    else
        visible = 'off';
    end
    drawnow;
    SetGlobalVar('ShowVois',get(hObject,'Value'));
    UpdateEBTViewer(handles);
%-------------------------------------------------------------------------%
%-------------------------------------------------------------------------%


% --- Executes on button press in btnCpSelect.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to btnCpSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%--------------------------------------------------------------------------
% --- Executes on button press in btnCpSelect.
function btnCpSelect_Callback(hObject, eventdata, handles)

EBTSceneController = GetGlobalVar('EBTSceneController');

[out, message ] = EBTSceneController.ControlPointSelection_Registration();

if out == 0
    MessageBox(message, 'Error Message');
else
    SetGlobalVar('EBTSceneController',EBTSceneController);
    MessageBox(message);
end
UpdateEBTViewer(handles);
