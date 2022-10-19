function WindowScrollFcn(hObject, eventdata, handles)
%WINDOWSCROLLFCN Performs the scrolling between CT/MR slices

isCallbackDisabled = GetGlobalVar('DisableCallbacks');
if ~isempty(isCallbackDisabled)
    return;
end

    %First, disable scrolling before performing calculations
    set(gcf,'WindowScrollWheelFcn',[]);
   
    %Read and store the current mouse position.
    UpdateMousePosition(hObject);
    
    %Load current mouse position
    currentMousePos = GetGlobalVar('currentMousePos');
    
    newSliceIndex = 0;
    if  strcmp(currentMousePos,'Form')
        %If the mouse is not over an axes, then scroll does nothing
    else
        
        %Else, scroll is translated into change of the cross position,
        %hence change on what the viewer is showing    
        CurrentSlice = GetGlobalVar('CurrentSlice');

        %Identify traverse direction (+ or -) and traverse on slice
        %at a time to this direction
        if eventdata.VerticalScrollCount < 0
            if ((CurrentSlice + eventdata.VerticalScrollCount) >= GetGlobalVar('MinSlice'))
                newSliceIndex = CurrentSlice + eventdata.VerticalScrollCount;
                SetGlobalVar('CurrentSlice',CurrentSlice + eventdata.VerticalScrollCount);
            else
                newSliceIndex = GetGlobalVar('MinSlice');
                SetGlobalVar('CurrentSlice',GetGlobalVar('MinSlice'));
            end
        else
            if (CurrentSlice + eventdata.VerticalScrollCount <= GetGlobalVar('MaxSlice'))
                newSliceIndex = CurrentSlice + eventdata.VerticalScrollCount;
                SetGlobalVar('CurrentSlice',CurrentSlice + eventdata.VerticalScrollCount);
            else
                newSliceIndex = GetGlobalVar('MaxSlice');
                SetGlobalVar('CurrentSlice',GetGlobalVar('MaxSlice'));
            end
        end

        UpdateEBTViewer(handles);
        %Changing the value of jSlider will raise the
        %"StateChangedCallback" and consequently the UpdateEBTViewer(handles) 
        if ~isempty(GetGlobalVar('CurrentSlice'))
            set(handles.hScrollSlider,'Value',newSliceIndex);
        end


    end
    
    %Finally, re-enable scrolling
    set(gcf,'WindowScrollWheelFcn',{@WindowScrollFcn, handles});
  

