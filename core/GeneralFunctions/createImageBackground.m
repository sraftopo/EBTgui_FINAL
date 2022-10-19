function createImageBackground( img, btnHandle )
%CREATEIMAGEBACKGROUND Summary of this function goes here
%   Detailed explanation goes here

   iconsPath = [pwd '\Resources\Icons\'];

   icon = strrep(['file:/' iconsPath img],'\','/');

   btnSize = int16(getpixelposition(btnHandle));

   % create a padding of 4 pixels around the image
	 imgWidth = num2str(btnSize(1,3) - 8);
 	 imgHeight = num2str(btnSize(1,4) - 8);

   set(btnHandle, 'String', ['<html><img src="' icon '" width="' imgWidth '" height="' imgHeight '"/></html>']);
   
   originalImage = imread([iconsPath img]);
  [rows, columns, numberOfColorChannels] = size(originalImage)
end
