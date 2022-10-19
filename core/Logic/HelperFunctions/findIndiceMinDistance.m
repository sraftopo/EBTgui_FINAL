function index = findIndiceMinDistance(vsearch,vref)
   
    d = abs(double(vsearch) - double(vref));
    index = find(d == min(d));
    
    if numel(index) > 1   % in this case there are two equidistant vref coordinates relative to vsearch
                          % in this case the first in the row is taken as result
        index = index(1);
    end

end

    