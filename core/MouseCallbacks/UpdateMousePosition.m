function UpdateMousePosition( hObject )
%UPDATEMOUSEPOSITION 

  
  %Gets the current position of the mouse in terms of (x,y) pixels
  %with respect to the global reference frame of the gui
  MousePos = get(hObject,'currentpoint');
      
  %Gets the bounds of ui elements to identify if the mouse if over a
  %certain ui element. Specifically, we care about the main axis
  MainAxesBounds = GetGlobalVar('MainAxesBounds');
  FilmAxesBounds = GetGlobalVar('FilmAxesBounds');
  
  %Refresh the currentMousePos which is used throughout the form
  %Usage : SetGlobalVar('currentMousePos', 'UiElementName' );
  %This way, you can identify over which element the mouse cursor is at any
  %given time during the program execution.
  if isWithinBounds(MousePos, MainAxesBounds)
       %If the mouse is over axis, set a flag
       SetGlobalVar('currentMousePos','MainAxes');
  elseif isWithinBounds(MousePos, FilmAxesBounds)
      SetGlobalVar('currentMousePos', 'FilmAxes'); 
  else
      %Otherwise set a general flag indicating that the mouse if over 
      %neutral form areas
      SetGlobalVar('currentMousePos','Form');
  end
  
  
%--------------------------------------------------------------------------
 %Compares mouse position against a given set of bound and returns true or
 %false depending on result
function out = isWithinBounds(pos, bounds)
%--------------------------------------------------------------------------
     
      x  = pos(1);      y  = pos(2);
      lx = bounds(1);   ly = bounds(2);
      lw = bounds(3);   lh = bounds(4);      
      if x>=lx && x<=(lx+lw) && y>=ly && y<=(ly+lh)
          out = 1;
      else
          out = 0;
      end   
      
 end

end

