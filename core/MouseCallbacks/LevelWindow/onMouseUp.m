function onMouseUp(src, eventdata)

isCallbackDisabled = GetGlobalVar('DisableCallbacks');
if ~isempty(isCallbackDisabled)
    return;
end

    % for the adjustment of level/window, the last values of these must be
    % set according to the modality being shown (CT and MR have different
    % level and window values)
    if (GetGlobalVar('ShowCT') == 1)        
        SetGlobalVar('lastLevel',GetGlobalVar('CTLevel'));
        SetGlobalVar('lastWindow',GetGlobalVar('CTWindow'));         
    elseif (GetGlobalVar('ShowMR') == 1)        
        SetGlobalVar('lastLevel',GetGlobalVar('MRLevel'));
        SetGlobalVar('lastWindow',GetGlobalVar('MRWindow'));   
    end

    % restore gui mouse pointer
    setptr(gcf, 'arrow');
    
    % set mouse state flags to false, indicating that the callbacks have
    % ended (adjust, pan etc)
    SetGlobalVar('adjustLWState',0);          
    SetGlobalVar('panState',0);
    
    
    UpdateEBTViewer(guidata(src));
    
    % reset mouse movement callback to pixelvalue
    set(gcf,'WindowButtonMotionFcn',@ShowCurrentPixelValue);
end