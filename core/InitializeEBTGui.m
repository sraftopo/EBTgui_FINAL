function InitializeEBTGui( handles )
%INITIALIZEEBTGUI Summary of this function goes here
%   Detailed explanation goes here

    h = getappdata(0,'hFilmGUI');

    % convert gui units to pixels temporarily to fetch pixel dimensions,
    % and then restore
    set(h, 'units', 'pixels');
    absoluteGuiSize = get(h, 'position');
    set(h, 'units', 'normalized');

    set(h,'doublebuffer','on');

    axis([handles.axesFilm handles.axesCT],'off'); %

    EBTSceneController = EBTController();
    SetGlobalVar('EBTSceneController',EBTSceneController);

    %Store the bounds of our main viewing panel
    viewingPanelBounds = getpixelposition(handles.uipanelviewing);

    %Calculate and store axes bounds
    ctBoxBounds = getpixelposition(handles.uipanelAxesCTBox);
    ctAxesBounds = getpixelposition(handles.axesCT);
    ctAxesBounds(1,1) = ctAxesBounds(1,1) + viewingPanelBounds(1,1) + ctBoxBounds(1,1);
    ctAxesBounds(1,2) = ctAxesBounds(1,2) + viewingPanelBounds(1,2) + ctBoxBounds(1,2);

    SetGlobalVar('MainAxesBounds', [...
        ctAxesBounds(1,1)/absoluteGuiSize(1,3)...
        ctAxesBounds(1,2)/absoluteGuiSize(1,4)...
        ctAxesBounds(1,3)/absoluteGuiSize(1,3)...
        ctAxesBounds(1,4)/absoluteGuiSize(1,4)...
    ]);

    filmBoxBounds = getpixelposition(handles.uipanelAxesFilmBox);
    filmAxesBounds = getpixelposition(handles.axesFilm);
    filmAxesBounds(1,1) = filmAxesBounds(1,1) + viewingPanelBounds(1,1) + filmBoxBounds(1,1);
    filmAxesBounds(1,2) = filmAxesBounds(1,2) + viewingPanelBounds(1,2) + filmBoxBounds(1,2);

    SetGlobalVar('FilmAxesBounds', [...
        filmAxesBounds(1,1)/absoluteGuiSize(1,3)...
        filmAxesBounds(1,2)/absoluteGuiSize(1,4)...
        filmAxesBounds(1,3)/absoluteGuiSize(1,3)...
        filmAxesBounds(1,4)/absoluteGuiSize(1,4)...
    ]);



    %Set current mouse position to 'form'
    SetGlobalVar('currentMousePos','Form');

    %Lock CT initial view to Axial
    SetGlobalVar('ViewMode',Views.Axial);

    %Lock FILM initial view to Total
    SetGlobalVar('FilmViewMode',FilmViews.Total);

    %Set current current FILM color channel
%   SetGlobalVar('CurrentColor',Red);
    SetGlobalVar('CurrentColor','Red')

    % add icon to main gui
    setGuiIcon(h);

    %Set initial level
    SetGlobalVar('Level',1000); SetGlobalVar('LevelHU',-24);
    SetGlobalVar('InitialLevel',getappdata(h,'Level'));
    %Define and store level range
    LevelLimits.min = -1024;
    LevelLimits.max = 4096;
    %Set level adjustment speed
    SetGlobalVar('LevelAdjustSpeed',0.25);
    SetGlobalVar('LevelLimits',LevelLimits);

    %Set initial window
    SetGlobalVar('Window',300);
    SetGlobalVar('InitialWindow',getappdata(h,'Window'));
    %Define and store window range
    WindowLimits.min = 24;
    WindowLimits.max = 4096;
    %Set window adjustment speed
    SetGlobalVar('WindowAdjustSpeed',0.25) ;
    SetGlobalVar('WindowLimits',WindowLimits);

    SetGlobalVar('OverlayTransparency',0.5);
    SetGlobalVar('OverlayColor',0);

    %Set a fixed prescription dose value
    SetGlobalVar('PrescriptionDose',1);

    %Create and initialize default isodose line properties
    totalNumberOfIsodoseLines = 5;
    SetGlobalVar('NumberOfIsodoseLines', totalNumberOfIsodoseLines);

    %CT
    IsodoseProperties.Color = jet(totalNumberOfIsodoseLines); %Color random
    IsodoseProperties.ValuePercent = [0.1;0.2;0.3;0.8;1.5;];
    IsodoseProperties.Status = ones(totalNumberOfIsodoseLines,1);
    IsodoseProperties.Value = IsodoseProperties.ValuePercent*(100.0/100.0);
    IsodoseProperties.LineThickness = ones(totalNumberOfIsodoseLines,1);
    SetGlobalVar('IsodoseProperties',IsodoseProperties);
    SetGlobalVar('ShowTPSIsodoses',1);

    %Create and initialize default FILM isodose line properties
    totalNumberOfFilmIsodoseLines = 5;
    SetGlobalVar('NumberOfFilmIsodoseLines', totalNumberOfFilmIsodoseLines);

    %FILM
    FilmIsodoseProperties.Color = jet(totalNumberOfFilmIsodoseLines); %Color random
    FilmIsodoseProperties.ValuePercent = [0.1;0.2;0.3;0.8;1.5;];
    FilmIsodoseProperties.Status = ones(totalNumberOfFilmIsodoseLines,1);
    FilmIsodoseProperties.Value = FilmIsodoseProperties.ValuePercent*(100.0/100.0);
    FilmIsodoseProperties.LineThickness = ones(totalNumberOfFilmIsodoseLines,1);
    SetGlobalVar('FilmIsodoseProperties',FilmIsodoseProperties);
    SetGlobalVar('ShowFilmIsodoses',1);

    %Initialize CT threashold value to zero
    SetGlobalVar('VoxelValue',0);
    %Initialize Film threashold value to zero
    SetGlobalVar('PixelValue',0);

    %Initialize all viewing flags (ShowXXXX) to 0
    SetGlobalVar('ShowCT',0);
    SetGlobalVar('ShowVois',0);
    SetGlobalVar('ShowTPSIsodoses',0);
    SetGlobalVar('ShowDoseGrids',0);

    %Initial zoom factor
    SetGlobalVar('ZoomFactor',0.0);

    %Initial Film zoom factor
    SetGlobalVar('FilmZoomFactor',0.0);

    %Generate an initial color map
    guiColorMap = gray(256);
    SetGlobalVar('GuiColormap',guiColorMap);
    SetGlobalVar('ColormapRange',20);
    SetGlobalVar('ColormapAlpha',0.5);
    SetGlobalVar('ShowGelDose',0);


    map2 = [  0.54  0.02  0.02
          0.73  0.02  0.02
          1.00  0.25  0.05
          0.98  0.40  0.07
          1.00  0.55  0.00
          0.89  0.75  0.16
          0.74  0.75  0.09
          0.46  0.55  0.20
          0.03  0.63  0.05
          0.34  1.00  0.07
          0.06  0.92  0.97
          0.00  0.56  1.00
          0.08  0.34  0.92
          0.49  0.51  0.93
          0.40  0.43  0.92
          0.33  0.36  0.91
          0.62  0.22  0.91
          0.45  0.20  0.90
          0.37  0.10  0.85
          0.30  0.08  0.69];

    map2 = flipud(map2);
    map2 = jet(20);

    currentColormap  = GetGlobalVar('GuiColormap');
    cnew = [currentColormap; map2];
    SetGlobalVar('GuiColormap',cnew);
    SetGlobalVar('ZoomFactor',1);


    %Initialize multiview parameters
    %A global variable defines the current view orientation
    SetGlobalVar('ActiveOrientation', 'Axial');

    SetGlobalVar('ViewPosition', []);
    SetGlobalVar('MaxAxialSlice', 0);
    SetGlobalVar('MaxCoronalSlice', 0);
    SetGlobalVar('MaxSagittalSlice', 0);

    guidata(getappdata(0,'hFilmGUI'));
    %Set current mouse position to 'form'
    SetGlobalVar('currentMousePos','Form');

    % set button icons
    createImageBackground('merge.png', handles.btnCpSelect);
    createImageBackground('eeae.png', handles.btnEEAE);
    createImageBackground('contour_icon2.png', handles.btnShowFilmIsodoses);
    createImageBackground('contour_icon2.png', handles.btnShowTPSIsodoses);
    createImageBackground('dosemap_icon2.png', handles.togglebuttonFilmDosemap);
    createImageBackground('dosemap_icon2.png', handles.togglebuttonCTdosemap);

    out = handles;

end
