% -------------------------------------------------------------------------   
function SetGlobalVar(name, value)
 
    hMainGui = getappdata(0,'hFilmGUI');
    if ~ishandle(hMainGui); return; 
    end
    
%     currentVal = getappdata(hMainGui,name);
%     if isempty(currentVal)
%        setappdata(hMainGui,[name '_'], value); 
%     end
    setappdata(hMainGui,name, value);
% -------------------------------------------------------------------------

if getappdata(hMainGui,'DEBUG_MODE')
    if getappdata(hMainGui,'MEMORY_PROFILE')
        memoryTable = GetGlobalVar('memoryTable');
        if isempty(memoryTable)
            memoryTable{1,1} = name;
            memoryTable{1,2} = getByteSize(value);
            memoryTable{1,3} = 1;
        else
           ind = find(strcmp(memoryTable, name));
           if isempty(ind)
               ind = size(memoryTable,1) + 1;
                memoryTable{ind,1} = name;
                memoryTable{ind,2} = getByteSize(value);
                memoryTable{ind,3} = 1;  
           else
                memoryTable{ind,1} = name;
                memoryTable{ind,2} = getByteSize(value);
                memoryTable{ind,3} = memoryTable{ind,3}  + 1;               
           end 
        end
        setappdata(hMainGui,'memoryTable',memoryTable);
    end
end

function si  = getByteSize(otherVar)
% BYTESIZE writes the memory usage of the provide variable to the given file
% identifier. Output is written to screen if fid is 1, empty or not provided.
    c = otherVar;
    origWarn = warning();
    warning off 'MATLAB:structOnObject'
    try
        item = builtin('struct', c); % use 'builtin' in case @foo overrides struct()
    catch
        item = c;
    end
    warning(origWarn);


s = whos('item');
si = Bytes2str(s.bytes);

    function str = Bytes2str(NumBytes)
    % BYTES2STR Private function to take integer bytes and convert it to
    % scale-appropriate size.

    scale = floor(log(NumBytes)/log(1024));
        switch scale
            case 0
                str = [sprintf('%.0f',NumBytes) ' b'];
            case 1
                str = [sprintf('%.2f',NumBytes/(1024)) ' kb'];
            case 2
                str = [sprintf('%.2f',NumBytes/(1024^2)) ' Mb'];
            case 3
                str = [sprintf('%.2f',NumBytes/(1024^3)) ' Gb'];
            case 4
                str = [sprintf('%.2f',NumBytes/(1024^4)) ' Tb'];
            case -inf
                % Size occasionally returned as zero (eg some Java objects).
                str = 'Not Available';
            otherwise
               str = 'Over a petabyte!!!';
        end

    end

end




end