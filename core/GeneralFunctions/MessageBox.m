    %% --------------------------------------------------------------------
    function [er] = MessageBox(varargin)
    % ---------------------------------------------------------------------
    message = varargin{1};
    if nargin > 1
      title = varargin{2};
    else
      title = 'Message';
    end

        er = msgbox(message,title);
%         set(er, 'units', get(getappdata(0,'hFilmGUI'),'units'));
        setGuiIcon(er);
%         pos = get(er,'position');
%         try %If it fails, it means that it has been called from outside the main GUI
%             hMainGuiPos = get(getappdata(0,'hFilmGUI'),'position');
%             msgPos  = [hMainGuiPos(1) + ((hMainGuiPos(3)-pos(3))/2), hMainGuiPos(2) + ((hMainGuiPos(4)-pos(4))/2),  pos(3),pos(4)];
%             set(er,'position',msgPos);
%         catch
%         end
        waitfor(er);
    end
