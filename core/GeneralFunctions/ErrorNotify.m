    %% --------------------------------------------------------------------
    function [er] = ErrorNotify(message, title)
    % ---------------------------------------------------------------------
        er = msgbox(message,title);
                set(er,'units','pixels');
                pos = get(er,'position');
                try %If it fails, it means that it has been called from outside the main GUI
                    hMainGuiPos = get(getappdata(0,'RTSafeAnalysisToolHandle'),'position');
                    msgPos  = [hMainGuiPos(1) + ((hMainGuiPos(3)-pos(3))/2), hMainGuiPos(2) + ((hMainGuiPos(4)-pos(4))/2),  pos(3),pos(4)];
                    set(er,'position',msgPos);
                catch
                end
        waitfor(er); 
    end