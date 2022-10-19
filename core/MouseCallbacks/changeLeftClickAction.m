function changeLeftClickAction(varargin)
%CHANGELEFTCLICKACTION This function allows to change what the left mouse
%button of the gui does. For now, the EEAEAnalysis tool only uses left
%click for adjusting window/level. However in the future we might need
%extra functionalities. In that case, this function will prove handy ;)

    %Get GUI handles (input)
    handles = varargin{1};
    %Get type of action (input : string)
    action  = varargin{2};

    %Additional input (no. 3) is for providing a specific figure handle
    if size(varargin,2) == 3
        currentFig = varargin{3};
    else
        currentFig = gcf;
    end

    %Update global variable storing the current action
    SetGlobalVar('leftClickAction',action);

    %Disable callbacks and refresh mouse pointer to default
    set(currentFig,'WindowButtonMotionFcn',@noCallback);
    set(currentFig,'WindowButtonDownFcn',@noCallback);
    set(currentFig,'WindowButtonUpFcn'  ,@noCallback);
    set(currentFig,'Pointer','arrow');

	switch action

        %ADJUST is for window/level
        case 'ADJUST'
            %If CT mode is on, update labels to show the CT level/window
            if (GetGlobalVar('ShowCT') == 1)
                set(handles.lbWindow,'String',['W: ', num2str(uint32(GetGlobalVar('CTWindow'))), ' L: ', num2str(uint32(GetGlobalVar('CTLevel')))]);
            end

            %Activate the appropriate callback
            set(currentFig,'WindowButtonDownFcn',@onMouseDown);
            %Set corresponding global var to false
            SetGlobalVar('adjustLWState',0);

        %-----------------------------------------------------------------%
        %THE FOLLOWING OPTIONS ARE NOT ENABLED IN RTsafeAnalysisTool but we
        %can use them as a reference for future implementations
        case 'MEASURE'
            set(currentFig,'WindowButtonDownFcn',@startMeasure);
            SetGlobalVar('measureIsOn',0);

        case 'SNAPSHOT'
            SetGlobalVar('snapIsOn',0);
            set(currentFig,'WindowButtonDownFcn',@mouseClickOnSnap);
            initSnap(handles);

        case 'CROP'
            set(currentFig,'WindowButtonDownFcn',@initMeasure1);
            SetGlobalVar('measureIsOn',0);

        case 'ZOOMNEW'
            set(currentFig,'WindowButtonDownFcn',@startZoom);
            SetGlobalVar('zoomIsOn',0);

        case 'PIXELVALUE'
            set(getappdata(0,'hMainGui'),'WindowButtonMotionFcn',@viewCurrentPixelValue);
            viewCurrentPixelValue(currentFig,[]);
            set(getappdata(0,'hMainGui'),'WindowButtonUpFcn',@noCallback);
            set(getappdata(0,'hMainGui'),'WindowButtonDownFcn',@rightClickOnlyCallback);
        %-----------------------------------------------------------------%

	end

end
