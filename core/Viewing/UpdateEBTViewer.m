function out = UpdateEBTViewer( handles )
%RENDERSCENE Renders current scene, taking into account a collection of
%global variables

    %If rendering of previous frame has not been completed, do nothing
    if(GetGlobalVar('Rendering') == 1); out = 0; return;
    end

    %Set rendering flag to 'on'
    SetGlobalVar('Rendering',1);


    %Get Scene Controller
    EBTSceneController = GetGlobalVar('EBTSceneController');

    %The current slice indicates current view position. It is
    %orientation-agnostic, and responsibility for maintaining within-bounds
    %values does not belong to this renderer (renderScene fcn)
    CurrentSlice = GetGlobalVar('CurrentSlice');
    CurrentView = GetGlobalVar('ViewMode');
    CurrentLevel = 1024;
    CurrentWindow = 200;

    CurrentFilmView = GetGlobalVar('FilmViewMode');

    %Set renderer to opengl
    set(getappdata(0,'hFilmGUI'),'renderer','opengl');


    % WARNING : HANDCODED VALUES MIGHT CAUSE PROBLEMS WITH DIFFERENT SIZES
    axesLimits = [0.5 512.5 0.5 512.5]; %axis(handles.axesCT)
    %Get current limits based on ct or mr image dimensions

    currentImageSet = [];

    try

        %Check if CT should be drawn
        if GetGlobalVar('ShowCT') == 1
            CurrentLevel = GetGlobalVar('CTLevel');
            CurrentWindow = GetGlobalVar('CTWindow');
            if EBTSceneController.fCTImageSet ~= 0
                if CurrentSlice <= GetGlobalVar('MaxSlice')
                RenderCTImageSet();
                else
                    imshow(0,'Parent',handles.axesCT);
                end
            end
        end

        %Check if TPS Isodoses should be drawn
        if EBTSceneController.fTPSRTDose > 0 && GetGlobalVar('ShowTPSIsodoses') == 1
            RenderTPSIsodoses();
        end
        if (EBTSceneController.fTPSRTDose) && (GetGlobalVar('ShowDoseGrids') == 1)
            RenderDoseGrids();
        end
        ApplyZoom();


        %Check if VOIS should be drawn
        if GetGlobalVar('ShowVois') == 1
            if (EBTSceneController.fRTStructureSet > 0) && (GetGlobalVar('ShowCT') == 1)
              RenderVois();
            end
        end
        ApplyZoom();


        %Check if FILM should be drawn
        if EBTSceneController.fPreFilmImageSet ~= 0 && EBTSceneController.fPostFilmImageSet ~= 0
            DrawEBTfilm(EBTSceneController.PostFilmImageSet,handles.axesFilm);

            if EBTSceneController.fregistration == 1
                ApplyZoom();
            end

        end


        %Check if Film Isodoses should be drawn
        if EBTSceneController.fDosemapSingleChannel > 0 & GetGlobalVar('ShowFilmIsodoses') == 1

            RenderFilmIsodoses(EBTSceneController.PostFilmImageSet,handles.axesFilm);
        end
%         if (EBTSceneController.fTPSRTDose) & (GetGlobalVar('ShowDoseGrids') == 1)
%             RenderDoseGrids();
%         end
            if EBTSceneController.fregistration == 1
                ApplyZoom();
            end


    catch ex
        disp('Rendering error : ');
        disp(ex.message);
    end



    FinishRendering();

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
    function RenderCTImageSet()
        %CT Image Set

            CTImageSet = EBTSceneController.CTImageSet;
            currentImageSet = CTImageSet;
            Level = GetGlobalVar('CTLevel');
            Window = GetGlobalVar('CTWindow');
            view = GetGlobalVar('ViewMode');

            %Get current view mode

            scaledCTSlice = ScaledImageFromViewParameters(CTImageSet.mImagesData, CurrentSlice, CurrentView, CurrentLevel, CurrentWindow);

            %Redefine axes limits based on actual viewing image size
            axesLimits = [0.5 size(scaledCTSlice,2)+0.5 0.5 size(scaledCTSlice,1)+0.5];

            % axes(handles.axesCT);
            h = imagesc(scaledCTSlice,'Parent', GetGlobalVar('CTViewer')); colormap(gray); %handles.axesCT);
            % set(h, 'AlphaData', 0.5);
%             set(h,'CDataMapping','direct');
            set(handles.axesCT,'xTick',[],'yTick',[]);

    end
%--------------------------------------------------------------------------




%--------------------------------------------------------------------------
    function RenderDoseGrids()

        TPSRTDose = EBTSceneController.TPSRTDose;
        tpsDoseCoordinates = TPSRTDose.mRTDoseCoordinates;

        switch CurrentView
            case Views.Axial
                if CurrentSlice >= min(tpsDoseCoordinates.zind) && ...
                 CurrentSlice <= max(tpsDoseCoordinates.zind)
                    RenderDoseBox(tpsDoseCoordinates.xind, tpsDoseCoordinates.yind, [237 125 49]./255, '-');
                end

            case Views.Sagittal

                if CurrentSlice >= min(tpsDoseCoordinates.xind) && ...
                 CurrentSlice <= max(tpsDoseCoordinates.xind)
                    RenderDoseBox(tpsDoseCoordinates.yind, tpsDoseCoordinates.zind, [237 125 49]./255, '-');
                end

            case Views.Coronal

                if CurrentSlice >= min(tpsDoseCoordinates.yind) && ...
                 CurrentSlice <= max(tpsDoseCoordinates.yind)
                    RenderDoseBox(tpsDoseCoordinates.xind, tpsDoseCoordinates.zind, [237 125 49]./255, '-');
                end
       end

    end


%--------------------------------------------------------------------------
    function RenderTPSIsodoses()

        %Get TPS dose cube
        TPSRTDose = EBTSceneController.TPSRTDose;

        %Get global isodose viewing properties
        IsodoseProperties = GetGlobalVar('IsodoseProperties');
        %Divide Dose (Gy) / DoseGridScaling to match what the actual rtdose
        %cube contains
        IsodoseProperties.Value = IsodoseProperties.Value ./TPSRTDose.mDoseGridScaling;
        %Get new isodose levels in Gy/Scaling
        isodoseLevels = IsodoseProperties.Value;
        %Get dose cube coordinates
        coordinates = TPSRTDose.mRTDoseCoordinates;

        c = [];

        %Find closest index with respect to the current slice and view
        %based on rtdose coordinates, and get corresponding contours using
        %the isodoseLevels
        switch CurrentView
            case Views.Axial
                if CurrentSlice >= min(coordinates.zind) && ...
                 CurrentSlice <= max(coordinates.zind)

                    index = findIndiceMinDistance(coordinates.zind,CurrentSlice) ;
                    [c]= contourc(double(coordinates.xind),double(coordinates.yind),double(TPSRTDose.mDoseCube(:,:,index)),double(isodoseLevels));
                end
            case Views.Sagittal

                if CurrentSlice >= min(coordinates.xind) && ...
                 CurrentSlice <= max(coordinates.xind)

                    index = findIndiceMinDistance(coordinates.xind,CurrentSlice) ;
                    [c] = contourc(double(coordinates.yind),double(coordinates.zind),double(squeeze(TPSRTDose.mDoseCube(:,index,:)))',double(isodoseLevels));
               end
            case Views.Coronal

                if CurrentSlice >= min(coordinates.yind) && ...
                 CurrentSlice <= max(coordinates.yind)

                    index = findIndiceMinDistance(coordinates.yind,CurrentSlice) ;
                    [c] = contourc(double(coordinates.xind),double(coordinates.zind),double(squeeze(TPSRTDose.mDoseCube(index,:,:)))',double(isodoseLevels));

                end
        end



        %Draw isodose lines

        if ~isempty(c)
            s = contourdata(c);

            hold(handles.axesCT,'on');

            for ic = 1:size(s,2)

                isodoseIndex = find(isodoseLevels==s(ic).level);
                plot(handles.axesCT,s(ic).xdata,s(ic).ydata,'Color',IsodoseProperties.Color(isodoseIndex,:), ...
                                             'LineStyle','-',...
                                             'LineWidth',IsodoseProperties.LineThickness(isodoseIndex));

            end
            hold(handles.axesCT,'off');

        end


    end



%--------------------------------------------------------------------------
    function RenderVois()
        try
            if ~isempty(EBTSceneController.RTStructureSet.mVOIs)
            voiNames = fieldnames(EBTSceneController.RTStructureSet.mVOIs);
            numOfVOIs  = numel(voiNames);

            for i = 1:numOfVOIs
                selectedVOI = i;
                if EBTSceneController.RTStructureSet.mVOIs.(voiNames{selectedVOI}).hasContourData == 1

                    ContourData = EBTSceneController.RTStructureSet.mVOIs.(voiNames{selectedVOI}).indexedContourData;
                    ContourColor = double(EBTSceneController.RTStructureSet.mVoisProperties(selectedVOI).color)/255.0;

                    switch CurrentView
                        case Views.Axial

                            ind = find(round(ContourData(:,3)) == CurrentSlice);
                            if numel(ind)>0
                                ContoursInSlice = ContourData(ind,:);
                                for flag=1:max(ContoursInSlice(:,4));
                                    ind2 = find(ContoursInSlice(:,4) == flag);
                                    if numel(ind2) > 0
                                        ContourSetInSlice = ContoursInSlice(ind2,1:3);
                                        ContourSetInSlice(numel(ind2)+1,1:3) = ContoursInSlice(ind2(1),1:3);
                                        hold(handles.axesCT,'on');
                                        plot(handles.axesCT,ContourSetInSlice(:,1),ContourSetInSlice(:,2),'-',...
                                            'Color',ContourColor,'linewidth',1.5);
                                        hold(handles.axesCT,'off');
                                    end
                                end
                            end

                        case Views.Sagittal
                           ind = find(round(ContourData(:,1)) == CurrentSlice);
                           if numel(ind)>0
                              ContoursInSlice = ContourData(ind,:);
                              for flag=1:max(ContoursInSlice(:,4));
                                  ind2 = find(ContoursInSlice(:,4) == flag);
                                  if numel(ind2)>0
                                      ContourSetInSlice = ContoursInSlice(ind2,1:3);
%                                     contourSetInSliceNew = removePointsOutsidePlot(ContourSetInSlice,'sagittal');
                                      plot(ContourSetInSlice(:,2),ContourSetInSlice(:,3),...
                                           '.','Color',ContourColor,'markersize',10)
                                  end
                              end
                           end

                    	case Views.Coronal;
                           ind = find(round(ContourData(:,2)) == CurrentSlice);
                           if numel(ind)>0
                              ContoursInSlice = ContourData(ind,:);
                              for flag=1:max(ContoursInSlice(:,4));
                                  ind2 = find(ContoursInSlice(:,4) == flag);
                                  if numel(ind2)>0
                                      ContourSetInSlice = ContoursInSlice(ind2,1:3);
%                                     contourSetInSliceNew = removePointsOutsidePlot(ContourSetInSlice,'coronal');
                                      plot(ContourSetInSlice(:,1),ContourSetInSlice(:,3),'.','Color',ContourColor,'markersize',10)
                                      axis on
                                  end
                              end
                           end
                    end

                end
            end %if hasContourData


            end
        catch ex
          disp(ex.message);
        end
    end




%--------------------------------------------------------------------------
    function RenderFilmDoseGrids()

        FilmDose = EBTSceneController.SingleChannel.FilmDose;
        FilmDoseCoordinates = EBTSceneController.CTImageSet.ImageCoordinates;

        switch CurrentFilmView

            case FilmViews.Red
%                 if CurrentSlice >= min(tpsDoseCoordinates.zind) && ...
%                  CurrentSlice <= max(tpsDoseCoordinates.zind)
                    RenderDoseBox(FilmDoseCoordinates.x, FilmDoseCoordinates.y, [237 125 49]./255, '-');
%                 end

            case FilmViews.Green

%                 if CurrentSlice >= min(tpsDoseCoordinates.xind) && ...
%                  CurrentSlice <= max(tpsDoseCoordinates.xind)
                    RenderDoseBox(FilmDoseCoordinates.x, FilmDoseCoordinates.y, [237 125 49]./255, '-');
%                 end

            case FilmViews.Blue

%                 if CurrentSlice >= min(tpsDoseCoordinates.yind) && ...
%                  CurrentSlice <= max(tpsDoseCoordinates.yind)
                    RenderDoseBox(FilmDoseCoordinates.x, FilmDoseCoordinates.y, [237 125 49]./255, '-');
%                 end
       end

    end




%--------------------------------------------------------------------------
    function RenderFilmIsodoses(data, axesHandle)

        %Get Film dose and coordinates
        FilmDoseCoordinates = EBTSceneController.CTImageSet.ImageCoordinates;
        FilmDose = EBTSceneController.SingleChannel.FilmDose;


        %Get TPS dose cube
        TPSRTDose = EBTSceneController.TPSRTDose;
        % Get global isodose viewing properties
        IsodoseProperties = GetGlobalVar('IsodoseProperties');
        % Divide Dose (Gy) / DoseGridScaling to match what the actual rtdose
        % cube contains
        IsodoseProperties.Value = IsodoseProperties.Value; % ./TPSRTDose.mDoseGridScaling;
        % Get new isodose levels in Gy/Scaling
        isodoseLevels = IsodoseProperties.Value;
        % Get dose cube coordinates
        coordinates = TPSRTDose.mRTDoseCoordinates;


       xind = ((FilmDoseCoordinates.x - EBTSceneController.CTImagePositionPatient(1))/ EBTSceneController.CTVoxelSize(1)) + 1;
       yind = ((FilmDoseCoordinates.y - EBTSceneController.CTImagePositionPatient(2))/ EBTSceneController.CTVoxelSize(2)) + 1 ;


        c = [];

        %Find closest index with respect to the current slice and view
        %based on rtdose coordinates, and get corresponding contours using
        %the isodoseLevels


        switch CurrentFilmView
            case FilmViews.Red

                    hold(axesHandle,'on');
                    [c]= contour(double(xind),...
                                 double(yind),...
                                 double(FilmDose(:,:)),double(isodoseLevels),'Parent', axesHandle);


            case FilmViews.Green

                if CurrentSlice >= min(coordinates.xind) && ...
                 CurrentSlice <= max(coordinates.xind)

                    index = findIndiceMinDistance(coordinates.xind,CurrentSlice) ;
                    [c] = contourc(double(coordinates.yind),double(coordinates.zind),double(squeeze(TPSRTDose.mDoseCube(:,index,:)))',double(FilmisodoseLevels));
               end
            case FilmViews.Blue

                if CurrentSlice >= min(coordinates.yind) && ...
                 CurrentSlice <= max(coordinates.yind)

                    index = findIndiceMinDistance(coordinates.yind,CurrentSlice) ;
                    [c] = contourc(double(coordinates.xind),double(coordinates.zind),double(squeeze(TPSRTDose.mDoseCube(index,:,:)))',double(FilmisodoseLevels));

                end

            case FilmViews.Total

                if CurrentSlice >= min(coordinates.yind) && ...
                 CurrentSlice <= max(coordinates.yind)

                    index = findIndiceMinDistance(coordinates.yind,CurrentSlice) ;
                    [c] = contourc(double(coordinates.xind),double(coordinates.zind),double(squeeze(TPSRTDose.mDoseCube(index,:,:)))',double(FilmisodoseLevels));

                end
        end



        %Draw isodose lines

        if ~isempty(c)
            s = contourdata(c);

            hold(handles.axesFilm,'on');

            for ic = 1:size(s,2)

                FilmisodoseIndex = find(isodoseLevels==s(ic).level);
                plot(handles.axesFilm,s(ic).xdata,s(ic).ydata,'Color',IsodoseProperties.Color(FilmisodoseIndex,:), ...
                                             'LineStyle','-',...
                                             'LineWidth',IsodoseProperties.LineThickness(FilmisodoseIndex));
            end
            hold(handles.axesFilm,'off');

        end


    end





%--------------------------------------------------------------------------
%Set axes limits based on current zoom factor
%Get current zoom factor (0.0 - 1.0)
    function ApplyZoom()

        if CurrentView ~= Views.Axial
            v = axis;
            daspect(currentImageSet.AspectFactor);
            axis([v(1) v(2) ((v(4)-v(3))/2) - (((v(2)-v(1))/2)*currentImageSet.AspectFactor(2)) ((v(4)-v(3))/2) + (((v(2)-v(1))/2)*currentImageSet.AspectFactor(2))]);
            axis xy;
        end

        %Update axes limits after zoom has been applied
        axesLimits =  axis(handles.axesCT);


          zoomFactor = GetGlobalVar('ZoomFactor');

          %if zoom should be applied
%           if zoomFactor ~= 1
              %Calculate horizontal zoom factor
              zoomFactorX = ((axesLimits(2)-axesLimits(1))*zoomFactor)-(axesLimits(2)-axesLimits(1));
              %Calculate vertical zoom factor
              zoomFactorY = ((axesLimits(4)-axesLimits(3))*zoomFactor)-(axesLimits(4)-axesLimits(3));
              %Find new axes bounds based on zoom factors
              vNew(1) = (axesLimits(1)-zoomFactorX);   vNew(3) = (axesLimits(3)-zoomFactorY);
              vNew(2) = (axesLimits(2)+zoomFactorX);   vNew(4) = (axesLimits(4)+zoomFactorY);

              %Apply bound-swap if necessary
              if vNew(1)>vNew(2)
                  xNew = [vNew(2) vNew(1)];
              else
                  xNew = [vNew(1) vNew(2)];
              end
              if vNew(3)>vNew(4)
                  yNew = [vNew(4) vNew(3)];
              else
                  yNew = [vNew(3) vNew(4)];
              end

              %Apply new bounds to gui
              axis(handles.axesCT,[xNew yNew]);
              axis(handles.axesFilm,[xNew yNew]);
%           end

          %Removes white padding created by the difference in daspect of
          %sagittal and coronal views
          axis off;

    end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%% FILMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%-------------------------------------------------------------------------%
%Draws current film (pre and post) for current view mode
function DrawEBTfilm(data, axesHandle)

%             FilmImageSet = EBTSceneController.PostFilmImageSet;
%             currentImageSet = FilmImageSet;

    if EBTSceneController.fregistration == 1

        switch CurrentFilmView
            case FilmViews.Red
                imshow(data.mRegisteredFilmsWithCT.Red(:,:),[],'Parent', axesHandle);% impixelinfo;
            case FilmViews.Green
                imshow(data.mRegisteredFilmsWithCT.Green(:,:),[],'Parent', axesHandle); %  impixelinfo;
            case FilmViews.Blue
                imshow(data.mRegisteredFilmsWithCT.Blue(:,:),[],'Parent', axesHandle); % impixelinfo;
            case FilmViews.Total
                imshow(data.mTotalRegisteredFilms{1,1},[] ,'Parent', axesHandle); %impixelinfo;
        end
         axis(axesHandle,'off');


    else
        switch CurrentFilmView
            case FilmViews.Red
                imshow(data.mMeanFilms.Red(:,:),[],'Parent', axesHandle);% impixelinfo;
            case FilmViews.Green
                imshow(data.mMeanFilms.Green(:,:),[],'Parent', axesHandle); %  impixelinfo;
            case FilmViews.Blue
                imshow(data.mMeanFilms.Blue(:,:),[],'Parent', axesHandle); % impixelinfo;
            case FilmViews.Total
                imshow(data.mTotalFilms{1,1},[] ,'Parent', axesHandle); %impixelinfo;
        end
         axis(axesHandle,'off');

    end


end
%-------------------------------------------------------------------------%







%-------------------------------------------------------------------------%
function FinishRendering()
    %Draw whatever should be drawn to update gui
    drawnow;

    %Notify that rendering has been finished
    SetGlobalVar('Rendering',0);

    %bye bye
    out = 0;
end
%-------------------------------------------------------------------------%



end
