function setGuiIcon( current_figure )
%SETGUIICON Sets rtsafe favicon to a gui figure

	% disable matlab warning for obsolete jFrame
  warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');

	% get current jFrame
  jframe = get(current_figure ,'javaframe');

	% get icons folder
  iconsFolder = fullfile(getexecutablefolder(),'\Resources\Icons\');

	% create a jIcon and set it as jFrame figure
  jIcon = javax.swing.ImageIcon(strrep([iconsFolder 'eeaefavicon.png'],'\','/'));
  jframe.setFigureIcon(jIcon);
end
