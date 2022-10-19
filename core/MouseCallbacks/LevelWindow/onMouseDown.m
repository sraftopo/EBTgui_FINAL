function onMouseDown(hObject, eventdata, handles)
% if GetGlobalVar('showComparisonMap'); return; end;
% -------------------------------------------------------------------------

isCallbackDisabled = GetGlobalVar('DisableCallbacks');
if ~isempty(isCallbackDisabled)
    return;
end

 UpdateMousePosition(hObject);
    % If mouse is over the main axes
    if (strcmp(GetGlobalVar('currentMousePos'),'MainAxes'));

        % If left mouse button is clicked, adjust level/window
        if strcmp(get(gcf,'Selectiontype'),'normal')

            setptr(gcf, 'cross');
            SetGlobalVar('adjustLWState',1);
            SetGlobalVar('adjustStartPos',get(hObject,'currentpoint'));

            SetGlobalVar('lastLevel',GetGlobalVar('CTLevel'));
            SetGlobalVar('lastWindow',GetGlobalVar('CTWindow'));

        % If right mouse button is clicked, apply pan
        elseif strcmp(get(gcf,'Selectiontype'),'alt')
            setptr(gcf, 'hand');
            SetGlobalVar('panState',1);
        	SetGlobalVar('panStartPosition',get(gcf,'currentpoint'));
        end

        set(gcf,'WindowButtonUpFcn',@onMouseUp);
        set(gcf,'WindowButtonMotionFcn',@onMouseMove);

    end
end
