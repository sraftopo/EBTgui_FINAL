function tempWindow = adjustWindow(val,totalWidth)

        Window = GetGlobalVar('lastWindow');
        WindowLimits = GetGlobalVar('WindowLimits');
         adjustment = (WindowLimits.max - WindowLimits.min)*(val*GetGlobalVar('WindowAdjustSpeed')/totalWidth);
        %If new adjustment falls within limits, apply it, else maintain top or
        %bottom limit according to the direction of change
         if (Window + adjustment) > WindowLimits.min && (Window + adjustment) <  WindowLimits.max
            tempWindow =  Window + adjustment;
         else
            if (Window + adjustment) <= WindowLimits.min
                tempWindow = WindowLimits.min;
            elseif (Window + adjustment) >=  WindowLimits.max
                tempWindow = WindowLimits.max;
            end   
         end
end
