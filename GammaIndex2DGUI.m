function varargout = GammaIndex2DGUI(varargin)
% GAMMAINDEX2DGUI MATLAB code for GammaIndex2DGUI.fig

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GammaIndex2DGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GammaIndex2DGUI_OutputFcn, ...
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


%--------------------------------------------------------------------------
% --- Executes just before GammaIndex2DGUI is made visible.
function GammaIndex2DGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GammaIndex2DGUI (see VARARGIN)

% Choose default command line output for GammaIndex2DGUI
handles.output = hObject;


    InputData = varargin{1};

    %Set default mode to 'Norm'
    if isfield(handles, 'ComparisonMode')
        if isempty(handles.ComparisonMode)
            handles.ComparisonMode = 'Norm';
        end
    else
        handles.ComparisonMode = 'Norm';


    %Initialize isodose levels
    handles.contourLevels = [20 30 50 70 95];
    handles.contourLevelsABS = [0.5 1 2 3 4.5];
    set(handles.txtIsodoseLevels1,'string', num2str(handles.contourLevels(1)));
    set(handles.txtIsodoseLevels2,'string',  num2str(handles.contourLevels(2)));
    set(handles.txtIsodoseLevels3,'string',  num2str(handles.contourLevels(3)));
    set(handles.txtIsodoseLevels4,'string',  num2str(handles.contourLevels(4)));
    set(handles.txtIsodoseLevels5,'string',  num2str(handles.contourLevels(5)));
    set(handles.txtIsodoseLevel, 'String', 'Isodose Levels (%)');
    end

    handles.DoseData = InputData;

% Update handles structure
guidata(hObject, handles);
SetGlobalVar('hGammaIndexGui', hObject);
setGuiIcon(hObject);


%Calculate and Render
plotGamma2D(handles,hObject);


% uiwait();
% UIWAIT makes GammaIndex2DGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = GammaIndex2DGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Get default command line output from handles structure
varargout{1} = handles.output;


%--------------------------------------------------------------------------
% --- Executes on button press in btnShowAbsoluteDvh.
function btnShowAbsoluteDvh_Callback(hObject, eventdata, handles)
% hObject    handle to btnShowAbsoluteDvh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%--------------------------------------------------------------------------
% --- Executes on button press in btnExportFig.
function btnExportFig_Callback(hObject, eventdata, handles)
% hObject    handle to btnExportFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


    %Get dose data based on comparison mode (Normalized or GY)
    FilmDose = handles.DoseData.(handles.ComparisonMode).FilmDose;
    TPSDose = handles.DoseData.(handles.ComparisonMode).TPSDose;

    %Recalculate contour levels based on comparison mode
    switch handles.ComparisonMode
        case 'Norm'
            contourLevels = handles.contourLevels;
        case 'GY'
            contourLevels = handles.contourLevelsABS;
        otherwise
            contourLevels = handles.contourLevels;
    end

    %Get raw an interpolated coordinates
    XCoords =  handles.DoseData.XCoords;
    YCoords = handles.DoseData.YCoords;
    RTDoseXCoords = handles.DoseData.RTDoseXCoords;
    RTDoseYCoords = handles.DoseData.RTDoseYCoords;

    Gnan = handles.Gamma;

    if isempty(Gnan)
        disp('For unknown reason, there is no gamma comparison calculation to show');
        return;
    end

    figure; subplot(1,3,3);

        H = imagesc(XCoords(1,:), YCoords(:,1), Gnan);

        viewMode = GetGlobalVar('ViewMode');
        if viewMode ~= Views.Axial
            set(gca, 'YDir', 'normal');
        end
        alphas = ones(size(Gnan));

        daspect([1 1 1]);
        colorbar('fontsize',10,'color',[0 0 0],'fontweight','b');
        colormap(jet(10));
        alphas(isnan(Gnan(:,:))) = 0.0;

        set(H,'AlphaData',alphas);
        caxis([0 2]);

        hold on
        h2 = contour(RTDoseXCoords, RTDoseYCoords, TPSDose, contourLevels, '--k');
        set(gca,'FontWeight','normal');
        if viewMode ~= Views.Axial
            set(gca, 'YDir', 'normal');
        end
        xlabel('x axis (mm)');
        ylabel('y axis (mm)');
        daspect([1 1 1]);
        hold on
        h3 = contour(RTDoseXCoords, RTDoseYCoords, FilmDose, contourLevels, '-k');
        if viewMode ~= Views.Axial
            set(gca, 'YDir', 'normal');
        end
        clabel(h2,'manual','FontSize',12,'FontWeight','bold','FontName','Arial','Color','w','Rotation',0);
        clabel(h3,'manual','FontSize',12,'FontWeight','bold','FontName','Arial','Color','w','Rotation',0);
        legend('TPS','Film');
        title('Gamma Index DD = 3% & DTA = 3 mm','FontWeight','bold')

    f = figure;
    axesHandle = axes('Parent',f);

        h2 = contour(RTDoseXCoords, RTDoseYCoords, TPSDose, contourLevels, '--r');
        set(gca,'Ydir','Reverse','FontWeight','bold');
        if viewMode ~= Views.Axial
            set(gca, 'YDir', 'normal');
        end
        xlabel('x axis (mm)');
        ylabel('y axis (mm)');
        daspect([1 1 1]);

        hold on
        h3 = contour(RTDoseXCoords, RTDoseYCoords, FilmDose, contourLevels, '-k');
        if viewMode ~= Views.Axial
            set(gca, 'YDir', 'normal');
        end
        clabel(h2)
        clabel(h3)
%         legend(GetGlobalVar('RefDoseName'),GetGlobalVar('EvalDoseName'));
        legend('TPS','Film');
        grid(axesHandle,'on');
        set(axesHandle,'GridAlpha',0.75);
        set(axesHandle,'GridLineStyle',':');
        set(axesHandle,'MinorGridLineStyle',':');



%--------------------------------------------------------------------------
function plotGamma2D(handles, hObject)

    %Get gamma variables
    DTA = str2num(get(handles.txtDTA,'String'));
    DD = str2num(get(handles.txtDoseDifference,'String'))/100.0;
    THRESHOLD = str2num(get(handles.txtTRSH,'String'))/100.0;

    %Get dose data based on comparison mode (Normalized or GY)
    FilmDose = handles.DoseData.(handles.ComparisonMode).FilmDose;
    TPSDoseInterp = handles.DoseData.(handles.ComparisonMode).TPSDoseInterp;
    TPSDose = handles.DoseData.(handles.ComparisonMode).TPSDose;

    %Recalculate contour levels based on comparison mode
    switch handles.ComparisonMode
        case 'Norm'
            contourLevels = handles.contourLevels;
        case 'GY'
            contourLevels = handles.contourLevelsABS;
        otherwise
            contourLevels = handles.contourLevels;
    end

    %Save new contour levels
%     handles.contourLevels = contourLevels;

    %Get raw an interpolated coordinates
    XCoords =  handles.DoseData.XCoords;
    YCoords = handles.DoseData.YCoords;
    XCoordsInterp = handles.DoseData.XCoordsInterp;
    YCoordsInterp = handles.DoseData.YCoordsInterp;
    RTDoseXCoords = handles.DoseData.RTDoseXCoords;
    RTDoseYCoords = handles.DoseData.RTDoseYCoords;

    %Perform Gamma calculation
    G = CalculateGamma2D(FilmDose, TPSDoseInterp, XCoords, YCoords, XCoordsInterp, YCoordsInterp, DTA, DD);

    %Add Nans to values under threshold
    Gnan = G;
    Gnan(FilmDose < THRESHOLD*100) = NaN;

    %Save calculated value
    handles.Gamma = Gnan;

%     %Re-save handles
    guidata(hObject, handles);
% 
%     %Clear axes
%     cla(handles.hProfileComparisonAxes,'reset');

    %Plot Gamma 2D
    H = imagesc(XCoords(1,:), YCoords(:,1), Gnan, 'Parent',handles.hProfileComparisonAxes );
    set(handles.hProfileComparisonAxes,'fontsize',12,'color',[0 0 0],'fontweight','b');
    viewMode = GetGlobalVar('ViewMode');
    if viewMode ~= Views.Axial
        set(handles.hProfileComparisonAxes, 'YDir', 'normal');
    end
    alphas = ones(size(Gnan));

    daspect([1 1 1]);
    colorbar('fontsize',12,'color',[1 1 1],'fontweight','n'); 
    colormap(handles.hProfileComparisonAxes, jet(10));
    alphas(isnan(Gnan(:,:))) = 0.0;

    set(H,'AlphaData',alphas);
    caxis([0 2]);
    set(handles.hProfileComparisonAxes,'YTick',[],'YColor','w');
    set(handles.hProfileComparisonAxes,'XTick',[],'XColor','w');
    hold on;
    h2 = contour(RTDoseXCoords, RTDoseYCoords, TPSDose, contourLevels, '--k');
%     set(handles.hProfileComparisonAxes);
    hold on;
    h3 = contour(RTDoseXCoords, RTDoseYCoords, FilmDose, contourLevels, '-k');
    clabel(h2,'FontSize',12,'FontWeight','bold','FontName','Arial','Color','w','Rotation',0)
    clabel(h3,'FontSize',12,'FontWeight','bold','FontName','Arial','Color','w','Rotation',0)

% Calculate passing rates
bw1 = (G <= 1);  %& isnan(gammaMap)==0);
% figure; imshow(bw1,[0 1]); impixelinfo;
passing = sum(sum(bw1));

total = numel(G);
NaNsGammaMap = numel(find(isnan(G)));
totalnew = total - NaNsGammaMap;
passingRate1 = ( passing/total ) * 100;
passingRate2 = ( passing/totalnew ) * 100;
set(handles.textPassingRateResult, 'String', num2str(passingRate2));




%--------------------------------------------------------------------------
function txtDoseDifference_Callback(hObject, eventdata, handles)

    currentString = get(hObject, 'String');
    [newDDValue, status] = str2num(currentString);
    if status == 0 || size(newDDValue,2) > 1

        set(hObject,'String',5);
        return;
    else
        newDDValue = abs(newDDValue);
        if newDDValue == 0.0
            newDDValue = 1;
        end
        set(hObject,'String',num2str(newDDValue));

        plotGamma2D(handles, hObject)
    end



%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function txtDoseDifference_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtDoseDifference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%--------------------------------------------------------------------------
function txtDTA_Callback(hObject, eventdata, handles)

    currentString = get(hObject, 'String');
    [newDTAValue, status] = str2num(currentString);
    if status == 0 || size(newDTAValue,2) > 1
        set(hObject,'String',2);
        return;
    else
        newDTAValue = abs(newDTAValue);
        if newDTAValue == 0.0
            newDTAValue = 0.1;
        end
        set(hObject,'String',num2str(newDTAValue));

        plotGamma2D(handles, hObject)
    end


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function txtDTA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtDTA (see GCBO)
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


%--------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtTRSH_Callback(hObject, eventdata, handles)

    currentString = get(hObject, 'String');
    [newTRSHValue, status] = str2num(currentString);
    if status == 0 || size(newTRSHValue,2) > 1
        set(hObject,'String',2);
        return;
    else
        newTRSHValue = abs(newTRSHValue);
        if newTRSHValue == 0.0
            newTRSHValue = 15;
        elseif newTRSHValue > 100.0;
            newTRSHValue = 100.0;
        end
        set(hObject,'String',num2str(newTRSHValue));

        plotGamma2D(handles, hObject)
    end


% --- Executes during object creation, after setting all properties.
function txtTRSH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtTRSH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lblThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to lblThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lblThreshold as text
%        str2double(get(hObject,'String')) returns contents of lblThreshold as a double


% --- Executes during object creation, after setting all properties.
function lblThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function updateIsodoseLevelInputs(handles, levels)
    set(handles.txtIsodoseLevels1, 'string', num2str(levels(1)));
    set(handles.txtIsodoseLevels2, 'string', num2str(levels(2)));
    set(handles.txtIsodoseLevels3, 'string', num2str(levels(3)));
    set(handles.txtIsodoseLevels4, 'string', num2str(levels(4)));
    set(handles.txtIsodoseLevels5, 'string', num2str(levels(5)));





function txtIsodoseLevel_Callback(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtIsodoseLevel as text
%        str2double(get(hObject,'String')) returns contents of txtIsodoseLevel as a double


% --- Executes during object creation, after setting all properties.
function txtIsodoseLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function UpdateIsodoseLevels(hObject, handles, id)

    switch handles.ComparisonMode
        case 'Norm'

            currentString = get(hObject, 'String');
            [newIsoValue, status] = str2num(currentString);
            if status == 0 || size(newIsoValue,2) > 1
                set(hObject,'String',num2str(handles.contourLevels(id)));
                return;
            else
                newIsoValue = abs(newIsoValue);
                if (newIsoValue == 0.0) || (newIsoValue > 100.0)
                    set(hObject,'String',num2str(handles.contourLevels(id)));
                    return;
                end
                set(hObject,'String',num2str(newIsoValue));
                handles.contourLevels(id) = newIsoValue;
                guidata(hObject, handles);
                plotGamma2D(handles, hObject)
            end

        case 'GY'

            currentString = get(hObject, 'String');
            [newIsoValue, status] = str2num(currentString);
            if status == 0 || size(newIsoValue,2) > 1
                set(hObject,'String',num2str(handles.contourLevelsABS(id)));
                return;
            else
                newIsoValue = abs(newIsoValue);
                if (newIsoValue == 0.0)
                    set(hObject,'String',num2str(handles.contourLevelsABS(id)));
                    return;
                end
                set(hObject,'String',num2str(newIsoValue));
                handles.contourLevelsABS(id) = newIsoValue;
                guidata(hObject, handles);
                plotGamma2D(handles, hObject)
            end

    end



function txtIsodoseLevels1_Callback(hObject, eventdata, handles)
    UpdateIsodoseLevels(hObject, handles, 1)

function txtIsodoseLevels2_Callback(hObject, eventdata, handles)
    UpdateIsodoseLevels(hObject, handles, 2)

function txtIsodoseLevels3_Callback(hObject, eventdata, handles)
    UpdateIsodoseLevels(hObject, handles, 3)

function txtIsodoseLevels4_Callback(hObject, eventdata, handles)
    UpdateIsodoseLevels(hObject, handles, 4)

function txtIsodoseLevels5_Callback(hObject, eventdata, handles)
    UpdateIsodoseLevels(hObject, handles, 5)



% --- Executes during object creation, after setting all properties.
function txtIsodoseLevels1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevels1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function txtIsodoseLevels2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevels2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function txtIsodoseLevels3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevels3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function txtIsodoseLevels4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevels4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function txtIsodoseLevels5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIsodoseLevels5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textPassingRateResult_Callback(hObject, eventdata, handles)
% hObject    handle to textPassingRateResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textPassingRateResult as text
%        str2double(get(hObject,'String')) returns contents of textPassingRateResult as a double
