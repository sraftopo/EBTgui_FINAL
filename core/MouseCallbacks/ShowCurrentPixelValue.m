function ShowCurrentPixelValue(src,eventdata)
%SHOWCURRENTPIXELVALUE Updates the bottom legend with information regarding
%the current mouse position

    %Update mouse position, to check if it is over the viewing axes
    UpdateMousePosition(gcf);
    currentAxes = GetGlobalVar('currentMousePos');
    
    %Get gui handles
    handles = guidata(src);

    %Get scene controller and current viewing slice
    EBTSceneController = GetGlobalVar('EBTSceneController');

    %If the mouse if over main viewing axes
    if strcmp(currentAxes, 'FilmAxes')
        %Get mouse coordinates in the coordinate system of the axes
        currentMousePoint = int16(get(handles.('axesFilm'),'currentpoint'));
        curX = currentMousePoint(1,1);
        curY = currentMousePoint(1,2);
        
        try
            filmPixelValue = EBTSceneController.PostFilmImageSet.mMeanFilms.Red(curY,curX);
            set(handles.lbFilmPixelValue,'String', ['(',...
                num2str(curX), ',', ...
                num2str(curY), ') ',...
            ' PV: ',num2str(int16(filmPixelValue))]);
        catch 
            % mute exception - it can happen if curX or curY is less than 1
            % which can happen if the access is square and the dataset is
            % not
        end
        
    elseif strcmp(currentAxes,'MainAxes')

        %Get mouse coordinates in the coordinate system of the axes
        currentMousePoint = int16(get(handles.('axesCT'),'currentpoint'));
        curX = currentMousePoint(1,1);
        curY = currentMousePoint(1,2);


        CurrentSlice = GetGlobalVar('CurrentSlice');
        CurrentView = GetGlobalVar('ViewMode');

        %Convert mouse coordinates to voxel coordinates based on current
        %view orientation and depth.
        switch CurrentView
            case Views.Axial
                mouseToVoxelCoordinateX = curY;
                mouseToVoxelCoordinateY = curX;
                mouseToVoxelCoordinateZ = CurrentSlice;
            case Views.Coronal
                mouseToVoxelCoordinateX = CurrentSlice;
                mouseToVoxelCoordinateY = curX;
                mouseToVoxelCoordinateZ = curY;
            case Views.Sagittal
                mouseToVoxelCoordinateX = curX;
                mouseToVoxelCoordinateY = CurrentSlice;
                mouseToVoxelCoordinateZ = curY;
        end

        %Check if current view is showing CT or MR and update legends
        %respectivelly
        
        try
            ctPixelValue = EBTSceneController.CTImageSet.mImagesData(mouseToVoxelCoordinateX,mouseToVoxelCoordinateY,mouseToVoxelCoordinateZ);
            set(handles.lbCTValue,'String', ...
                ['(', num2str(mouseToVoxelCoordinateX), ',', ...
                num2str(mouseToVoxelCoordinateY), ',', ...
                num2str(mouseToVoxelCoordinateZ), ') ',...
                ' HU: ',num2str(ctPixelValue)]);
        catch ex
            % mute exception - it can happen if curX or curY is less than 1
            % which can happen if the access is square and the dataset is
            % not
        end
      
            
        %Next, check for doses : Since we have locked the gui to require an
        %RTDose before loading GEL doses etc, we first check if an RTDose
        %exists
        if EBTSceneController.fTPSRTDose == 1

            try
                %Convert mouse coordinates to X,Y,Z indices of the dose
                %cube
                indexX = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.xind,curX);
                indexY = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.yind,curY);
                indexZ = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.zind,CurrentSlice);

                switch CurrentView
                    case Views.Axial
                        mouseToDoseCoordsX = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.xind,curX);
                        mouseToDoseCoordsY = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.yind,curY);
                        mouseToDoseCoordsZ = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.zind,CurrentSlice) ;
                    case Views.Coronal
                        mouseToDoseCoordsX = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.xind,curX);
                        mouseToDoseCoordsY = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.yind,CurrentSlice);
                        mouseToDoseCoordsZ = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.zind,curY);
                    case Views.Sagittal
                        mouseToDoseCoordsX = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.xind,CurrentSlice) ;
                        mouseToDoseCoordsY = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.yind,curX) ;
                        mouseToDoseCoordsZ = findIndiceMinDistance(EBTSceneController.TPSRTDose.mRTDoseCoordinates.zind,curY) ;
                end

                tpsDoseVal = double(EBTSceneController.TPSRTDose.mDoseCube(mouseToDoseCoordsY,mouseToDoseCoordsX,mouseToDoseCoordsZ))*EBTSceneController.TPSRTDose.mDoseGridScaling;

                %Get value of dose cube in these indices, multiplied by
                %dose grid scaling
                doseLegendString = ['TPS: ', sprintf('%0.2f',tpsDoseVal), ' Gy'];

                %Then, check if a gel dose has been calculated
                GelDose = GetGlobalVar('CalculatedGelDose');
                %If geldose
                if ~isempty(GelDose)
                   try
                       %Get dose value from coordinates
                        gelDoseVal = double(GelDose(mouseToVoxelCoordinateX,mouseToVoxelCoordinateY,mouseToVoxelCoordinateZ));
                        if isnan(gelDoseVal)
                            gelDoseVal = 0.0;
                        end
                        %Create dose string
                        doseLegendString = [doseLegendString, '  Gel: ', sprintf('%0.2f',gelDoseVal), ' Gy'];

                   catch ex
                        %The only possible error in this try statement,
                        %is to get out of bounds. This is done on purpose in order
                        %to avoid checking all the time for "out of
                        %bounds" conditions regarding the position of
                        %the mouse w.r.t dose volume.
                        %Hence, we don't have to display or do something
                        %for error checking.
                   end

                else
                    %else check for directly loaded interpolated dose
                    GelDose = GetGlobalVar('InterpolatedGelDose');
                    if ~isempty(GelDose)
                        try
                            gelDoseVal = double(GelDose(mouseToDoseCoordsY,mouseToDoseCoordsX,mouseToDoseCoordsZ));
                            if isnan(gelDoseVal)
                                gelDoseVal = 0.0;
                            end

                            doseLegendString = [doseLegendString, '  Gel: ', sprintf('%0.2f',gelDoseVal), ' Gy'];
                        catch ex
                            %The only possible error in this try statement,
                            %is to get out of bounds. This is done on purpose in order
                            %to avoid checking all the time for "out of
                            %bounds" conditions regarding the position of
                            %the mouse w.r.t dose volume.
                            %Hence, we don't have to display or do something
                            %for error checking.
                        end

                    end
                end

            catch ex
                disp(ex.message);
            end

        end
	end


end
