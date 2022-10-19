% -------------------------------------------------------------------------
function value = GetGlobalVar(name)
    try
        hMainGui = getappdata(0,'hFilmGUI');
        if ~isempty(hMainGui)
            value = getappdata(hMainGui,name);
        else
            value = [];
        end
    catch
       value = []; 
    end
end

