function onMouseMove(src, eventdata)
% -------------------------------------------------------------------------
    handles=guidata(src);
    UpdateMousePosition(gcf);

    % If left click (adjust level & window)
    if GetGlobalVar('adjustLWState')

        CurrentAdjustPos = get(gcf,'currentpoint');

        % While mouse is over viewer axes
        if strcmp(GetGlobalVar('currentMousePos'),'MainAxes');

            MainAxesBounds = GetGlobalVar('MainAxesBounds');
            MainAxesWidth =  MainAxesBounds(3);
            MainAxesHeight = MainAxesBounds(4);

            % Get starting position (the mouse coordinates on button
            % down) and find distance of current o starting position
            adjustStartPos = GetGlobalVar('adjustStartPos');
            distX = CurrentAdjustPos(1) - adjustStartPos(1);
            distY = CurrentAdjustPos(2) - adjustStartPos(2);

            try
                % Calculate level and window changes
                tempLevel  = adjustLevel(distY,MainAxesHeight);
                tempWindow = adjustWindow(distX,MainAxesWidth);

                % Update CT or MR level accordingly and update
                % corresponding legends
                if (GetGlobalVar('ShowCT') == 1)
                    SetGlobalVar('CTLevel',tempLevel);
                    SetGlobalVar('CTWindow',tempWindow);
                    set(handles.lbWindow,'String',['W: ', num2str(uint32(tempWindow)), ' L: ', num2str(uint32(tempLevel))]);
                end

            catch err
                disp(err.message);
            end

        end
    elseif GetGlobalVar('panState')

        % get current point and compare to previous point (the location of
        % the mouse during the previous time this callback was raised) and
        % recalculate pan offsets accross each direction
        pNew = get(gcf,'currentpoint');
        pOld = GetGlobalVar('panStartPosition');
        SetGlobalVar('panStartPosition',pNew);

        % TODO: check that this 'hack' indeed returns proper figure
        % dimensions
        axesSize = get(handles.axesCT,'position').*get(handles.EBTgui,'position').*get( groot, 'Screensize' );
        wAxes = axesSize(1,3);
        hAxes = axesSize(1,4);

        xString = [char(GetGlobalVar('ViewMode')) 'PanOffsetX'];
        yString = [char(GetGlobalVar('ViewMode')) 'PanOffsetY'];
        SetGlobalVar(xString, GetGlobalVar(xString) + wAxes*(pNew(1)-pOld(1)));
        SetGlobalVar(yString, GetGlobalVar(yString) + hAxes*(pNew(2)-pOld(2)));
    end


    % Update scene
    UpdateEBTViewer(handles);
end
