function [ out ] = RenderDoseBox( c1, c2, color, style )
%RENDERDOSEBOX Draw box boundaries of a given coordinate set (c1, c2).

     line([c1(1)   c1(1)  ],[c2(1)   c2(end)],'Color',color,'linewidth',1,'LineStyle',style);
     line([c1(end) c1(end)],[c2(1)   c2(end)],'Color',color,'linewidth',1,'LineStyle',style);
     line([c1(1)   c1(end)],[c2(1)   c2(1)],'Color',color,'linewidth',1,'LineStyle',style);
     line([c1(1)   c1(end)],[c2(end) c2(end)],'Color',color,'linewidth',1,'LineStyle',style);

     out = 1;
end

