classdef EBTController < handle
    %EBTCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here

    properties


        fCTImageSet;
        CTImageSet;
        CTImagePositionPatient;
        CTSliceThickness;
        CTVoxelSize;

        fTPSRTDose;
        TPSRTDose;
        RTStructureSet;
        fRTStructureSet;

        fMRImageSet;
        MRImageSet;

        fPreFilmImageSet;
        PreFilmImageSet;
        fPreCalculation;
        fPostFilmImageSet;
        PostFilmImageSet;
        mNumberOfFilms;
        fRegistrationPerformed;

        statsCT;
        fstatsCT;
        statsFilm;
        fstatsFilm;
        NUMCT;
        NUMFILM;
        CTcentroids;
        CTslicesWITHspecificFiducials;
        meanZcoordinate;
        CT2FilmSlice;
        fCT2FilmSlice;
        CT2FilmSlice_DOSE
        fCT2FilmSlice_DOSE
        FilmCentroids;
        fFiducialCoordsCT;
        FiducialCoordsCT;
        fFiducialsFilm;
        FiducialCoordsFilm;

        FilmPoints;
        CTPoints;
        registeredFilmWithCT;
        fregistration;
        CalibrationCoefficients;
        fCalibration;

        fODmapSingleChannel;
        fDosemapSingleChannel;
        SingleChannel;
        Normalization;

    end



    methods (Access = 'public')

        %-----------------------------------------------------------------%
        function obj = EBTController()
            obj.ResetController();
        end


        %-----------------------------------------------------------------%
        function ResetController(obj)
          props = properties(obj);
          for i = 1: size(props,1)
            propName = props(i,1);
            if obj.isFlagProperty(props(i,1))
                obj.(propName{1}) = 0; 
            else 
                obj.(propName{1}) = [];
            end
          end
        end


        % ----------------------------------------------------------------%
        function [out, message] = ImportPrimaryCTImages(obj)

            %Begin loading from directory
            [out, message, list] = obj.ImportImages({'CT'});
            if out <= 0
                set( gcf, 'Pointer', 'arrow' ); drawnow;
                return;
            end

            obj.CTImageSet = [];
            %At this point, a list of single uids has been loaded, so it is
            %safe to proceed
            newImageSet = RTImageSet(list,'CT');
            if newImageSet.fLoaded == 1

                obj.CTImageSet = newImageSet;
                obj.CTImagePositionPatient = obj.CTImageSet.mImagesInfos{1,1}.ImagePositionPatient;
                obj.CTSliceThickness = obj.CTImageSet.SliceDistance; %.mImagesInfos{1,1}.SliceThickness;
                obj.CTVoxelSize = [ obj.CTImageSet.mImagesInfos{1,1}.PixelSpacing; obj.CTImageSet.SliceDistance ];
                obj.fCTImageSet = 1;

            else
                out = -1;
                message = 'Something went wrong while loading CT images';
            end

            set( gcf, 'Pointer', 'arrow' ); drawnow;
        end
        % ----------------------------------------------------------------%



        % ----------------------------------------------------------------%
        function [out, message, list] = ImportImages(obj, modality)

            %Begin loading from directory
            out = 0;
            message = [];
            [result, list, err] = DicomFileFinder(modality);
            if result < 0
                out = -1;
                message = err;
                return
            end

            %Check if single uid is found in the selected folder
            [~, numOfStudies] = GetUniqueFromList(list, 'StudyInstanceUID');
            if numOfStudies > 1
                out = -1;
                message = 'Multiple studies were found in the same directory. Please try again';
                return;
            end
            out = (numOfStudies > 0);
        end
        % ----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out, errormsg] = ImportTPSRTDose(obj)

           out = 0;
           errormsg = [];

          if obj.fCTImageSet == 0
             out = -1;
             errormsg = 'A CT image set must be loaded before importing RT doses';
             return;
          end

           % Load an rtdose
           newRTDose  = RTDoseObject('');

           set( gcf, 'Pointer', 'arrow' ); drawnow;
           % If loading is succesfull, store it and update flag
           if newRTDose.fLoaded == 1
               obj.TPSRTDose = newRTDose;
               obj.fTPSRTDose = true;
               SetGlobalVar('MaxTPSDose',max(obj.TPSRTDose.mDoseCube(:)));
               out = 1;
           elseif newRTDose.fLoaded < 0
               out = -1;
               errormsg = 'Something went wrong while loading the selected RTDOSE file';
           end

        end
        % ----------------------------------------------------------------%



        % ----------------------------------------------------------------%
        function [out, errormsg] = ImportRTStructureSet(obj)

           out = 0;
           errormsg = [];

          if obj.fCTImageSet == 0
             out = -1;
             errormsg = 'A CT image set must be loaded before importing RT Structures';
             return
          end

           % Load an rtdose
           newRTStructure  = RTStructureObject('');

           % If loading is succesfull, store it and update flag
           if newRTStructure.fLoaded == true
               obj.RTStructureSet = newRTStructure;
               obj.fRTStructureSet = true;

               obj.RTStructureSet.mVOIsVolumes = CalculateVoiVolumes();

               out = 1;
           end

           set( gcf, 'Pointer', 'arrow' ); drawnow;
        end
        % ----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out message] = ImportFilmImages(obj, type)

           out = 0;
           message = '';

           CurrentPath = pwd;

           try
               %Create a new collection
               newCollection = FilmCollection();
               importResult = newCollection.ReadCollection(type);

               % if import result is zero, then cancel has been clicked
               if importResult == 0
                   out = 2;
                   return;
               end

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;


               %Calculate mean values for the new film collection
               newCollection.MeanCollection();


               %Update controller accordingly
               switch type
                   case 'Pre'

                       % Reset values existing from previously loaded data
                       obj.fPostFilmImageSet = 0;
                       obj.PostFilmImageSet = [];
                       obj.fPreFilmImageSet = 0;
                       obj.PreFilmImageSet = [];

                       if(obj.fPostFilmImageSet == 1)
                           if(obj.mNumberOfFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.PreFilmImageSet = [];
                               obj.fPreFilmImageSet = 0;
                               set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfFilms = newCollection.mNumberOfFilms;
                       end
                       obj.PreFilmImageSet = newCollection;
                       obj.fPreFilmImageSet = 1;
                       obj.RegisterPrePostCollections();

                   case 'Post'

                       if(obj.fPreFilmImageSet == 1)
                           if(obj.mNumberOfFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.PostFilmImageSet = [];
                               obj.fPostFilmImageSet = 0;
                               set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfFilms = newCollection.mNumberOfFilms;
                       end
                       obj.PostFilmImageSet = newCollection;
                       obj.fPostFilmImageSet = 1;
                       obj.RegisterPrePostCollections();



               end

                out = 1;

           catch
               out = 0;
               message = 'An error has occured while loading the selected dataset';
               %Return to current path in case of loading error
              cd(CurrentPath);
           end
               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%


        %-----------------------------------------------------------------%
        function out = RegisterPrePostCollections(obj, type)

            out = 0;
            if ((obj.fPostFilmImageSet == 1) && (obj.fPreFilmImageSet == 1))

                [optimizer, metric] = imregconfig('monomodal') ;

                for j = 1:obj.mNumberOfFilms


                    tform = imregtform(obj.PreFilmImageSet.mMeanFilms.Red(:,:,j),obj.PostFilmImageSet.mMeanFilms.Red(:,:,j),...
                                                             'rigid',optimizer,metric);

                    obj.PreFilmImageSet.mRegisteredFilms.Red(:,:,j) = imwarp(obj.PreFilmImageSet.mMeanFilms.Red(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostFilmImageSet.mMeanFilms.Red(:,:,j))));

                    obj.PreFilmImageSet.mRegisteredFilms.Green(:,:,j) = imwarp(obj.PreFilmImageSet.mMeanFilms.Green(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostFilmImageSet.mMeanFilms.Green(:,:,j))));

                    obj.PreFilmImageSet.mRegisteredFilms.Blue(:,:,j) = imwarp(obj.PreFilmImageSet.mMeanFilms.Blue(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostFilmImageSet.mMeanFilms.Blue(:,:,j))));


                end
                obj.fRegistrationPerformed = 1;
                out = 1;

            else
                out = 1;
                return;
            end
        end

        %-----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out message NUMCT] = FindCTslicesWithFiducials(obj)

           out = 0;
           message = '';

          if obj.fCTImageSet == 0
             message = 'A CT image set must be loaded before proceeding to registration';
             return;
          end

          obj.fFiducialCoordsCT = 0;
           CurrentPath = pwd;

           try

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;

                        VoxelValue = GetGlobalVar('VoxelValue');
                        bw1CT = (obj.CTImageSet.mImagesData  > VoxelValue);
                        [bw2, NUMCT] = bwlabeln(bw1CT); % figure; imshow(bw2); impixelinfo;
                        obj.statsCT = regionprops(bw2,'basic');

                        for i = 1:size(obj.statsCT,1)

                            indx = obj.statsCT(i, 1).Centroid(1,1);
                            indy = obj.statsCT(i, 1).Centroid(1,2);
                            indz = obj.statsCT(i, 1).Centroid(1,3);

                            obj.CTcentroids(i,1) = obj.statsCT(i, 1).Centroid(1,1);
                            obj.CTcentroids(i,2) = obj.statsCT(i, 1).Centroid(1,2);
                            obj.CTcentroids(i,3) = obj.statsCT(i, 1).Centroid(1,3);

                            index_x = [1:1:size(obj.CTImageSet.ImageCoordinates.x)]';
                            index_y = [1:1:size(obj.CTImageSet.ImageCoordinates.y)]';
                            index_z = [1:1:size(obj.CTImageSet.ImageCoordinates.z)]';

                            xCTslice = interp1(index_x,obj.CTImageSet.ImageCoordinates.x,indx);
                            yCTslice = interp1(index_y,obj.CTImageSet.ImageCoordinates.y,indy);
                            zCTslice = interp1(index_z,obj.CTImageSet.ImageCoordinates.z,indz);

                            obj.FiducialCoordsCT(i,1) = xCTslice;
                            obj.FiducialCoordsCT(i,2) = yCTslice;
                            obj.FiducialCoordsCT(i,3) = zCTslice;

                            clear xCTslice yCTslice zCTslice

                        end
                        clear bw1 bw2 i

                        numOFfiducials = num2str(NUMCT);
                        message = strcat(numOFfiducials,' fiducials were found');
                        obj.fFiducialCoordsCT = 1;
                        out = 1;

           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out message NUMFILM] = FindFilmFiducials(obj)

           out = 0;
           message = '';

          if obj.fPostFilmImageSet == 0
             message = 'A Film image set must be loaded before proceeding to registration';
             return;
          end

           CurrentPath = pwd;
           obj.fFiducialsFilm = 0;

           try

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;


                        PixelValue = GetGlobalVar('PixelValue');

                        bw1Film = (obj.PostFilmImageSet.mMeanFilms.Red  > PixelValue);
                        bw2Film = imclearborder(bw1Film);
                        bw3Film = bwareaopen(bw2Film,1);
                        [bw4Film, NUMFILM] = bwlabeln(bw3Film); % figure; imshow(bw2); impixelinfo;
                        obj.statsFilm = regionprops(bw4Film,'basic');


                        filmHoles = size(obj.statsFilm,1);
                        j = 1;
                        for i = 1:filmHoles

                            if obj.statsFilm(i).Area < 20 % Delete big holes (no fiducials holes) and scanned image background

                            a = obj.statsFilm(i).Centroid;
                            obj.FilmCentroids(j,:) = a;
                            j = j + 1;

                            clear a

                            end

                        end



                        for i = 1:size(obj.statsFilm,1)

                            indx = obj.statsFilm(i, 1).Centroid(1,1);
                            indy = obj.statsFilm(i, 1).Centroid(1,2);

                            obj.FilmCentroids(i,1) = obj.statsFilm(i, 1).Centroid(1,1);
                            obj.FilmCentroids(i,2) = obj.statsFilm(i, 1).Centroid(1,2);

                            index_x = [1:1:size(obj.PostFilmImageSet.mFilms.Film_1{1, 1}.mFilmCoordinates.x,2)]';
                            index_y = [1:1:size(obj.PostFilmImageSet.mFilms.Film_1{1, 1}.mFilmCoordinates.y,2)]';

                            xFilmSlice = interp1(index_x,obj.PostFilmImageSet.mFilms.Film_1{1, 1}.mFilmCoordinates.x,indx);
                            yFilmSlice = interp1(index_y,obj.PostFilmImageSet.mFilms.Film_1{1, 1}.mFilmCoordinates.y,indy);

                            obj.FiducialCoordsFilm(i,1) = xFilmSlice;
                            obj.FiducialCoordsFilm(i,2) = yFilmSlice;

                            clear xFilmSlice yFilmSlice

                        end
                        clear bw1 bw2 i

                        numOFfilmFiducials = num2str(NUMFILM);
                        message = strcat(numOFfilmFiducials,' fiducials were found');
                        obj.fFiducialsFilm = 1;
                        out = 1;
           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out, message ] = ControlPointSelection_Registration(obj)

          out = 0;
          message = '';

          % check that both ct and film have been loaded
          if (obj.fPostFilmImageSet == 0) || (obj.fCTImageSet == 0)
             message = 'Both film and CT image sets must be loaded to perform registration';
             return;
          end

          % Select Film slice to use for registration
          CurrentFilmView = GetGlobalVar('FilmViewMode');
          if CurrentFilmView == 1
            message = 'Please select a valid film color channel. Red, Green, Blue... ';
            return;
          end

          if (obj.fFiducialCoordsCT == 0) || (obj.fFiducialsFilm == 0)
            message = 'Control points have not been set. Please provide threshold values';
            return;
          end

          % keep reference to the current path
          CurrentPath = pwd;

           try

              % set mouse cursor to "loading"
              set(gcf,'Pointer','Watch'); drawnow;
              PixelValue = GetGlobalVar('PixelValue');

                switch CurrentFilmView
                    case FilmViews.Red
                        unregistered_temp = obj.PostFilmImageSet.mMeanFilms.Red ;
                        bw1Film = (unregistered_temp  < PixelValue);
                        bw2Film = imclearborder(bw1Film);
                        bw3Film = bwareaopen(bw2Film,10);
                        [bw4Film, NUMFILM] = bwlabeln(bw3Film); % figure; imshow(bw4Film); impixelinfo;
                    case FilmViews.Green
                        unregistered_temp = obj.PostFilmImageSet.mMeanFilms.Green ;
                        bw1Film = (unregistered_temp  < PixelValue);
                        bw2Film = imclearborder(bw1Film);
                        bw3Film = bwareaopen(bw2Film,10);
                        [bw4Film, NUMFILM] = bwlabeln(bw3Film); % figure; imshow(bw4Film); impixelinfo;
                    case FilmViews.Blue
                        unregistered_temp = obj.PostFilmImageSet.mMeanFilms.Blue ;
                        bw1Film = (unregistered_temp  < PixelValue);
                        bw2Film = imclearborder(bw1Film);
                        bw3Film = bwareaopen(bw2Film,10);
                        [bw4Film, NUMFILM] = bwlabeln(bw3Film); % figure; imshow(bw4Film); impixelinfo;
                end
                        unregistered = bw4Film ;

                        % CT slice to use for registration
                        CurrentSlice = GetGlobalVar('CurrentSlice');
                        VoxelValue = GetGlobalVar('VoxelValue');

                        reference_temp = obj.CTImageSet.mImagesData(:,:,CurrentSlice) ;
                        bw1CTslice = (reference_temp  > VoxelValue);
                        [bw2CTslice, NUMCT] = bwlabeln(bw1CTslice); % figure; imshow(bw2CTslice); impixelinfo;
                        reference = bw2CTslice ;

                        [input_points, base_points] = cpselect(unregistered, reference,'Wait',true);
                        SetGlobalVar('input_points',input_points);
                        SetGlobalVar('base_points',base_points);

                % Film points
                for i = 1:size(input_points,1)

                    flagFilm_x = find((obj.FilmCentroids(:,1)) >= input_points(i,1)-5 & (obj.FilmCentroids(:,1)) <= input_points(i,1)+5 ) ;
                    flagFilm_y = find((obj.FilmCentroids(:,2)) >= input_points(i,2)-5 & (obj.FilmCentroids(:,2)) <= input_points(i,2)+5 ) ;

                    for j = 1:size(flagFilm_x,1)
                        flagy = find(flagFilm_y == flagFilm_x(j));
                        if ~isempty(flagy)
                            flagx = j; break;
                        end
                    end
                    clear j

                    if flagFilm_x(flagx) == flagFilm_y(flagy)
                        index = flagFilm_x(flagx) ;
                        obj.FilmPoints(i,:) = obj.FilmCentroids(index,:) ;
                    end

                end
                clear flagx flagy i j index


                % CTpoints
                indexCTslices = find(obj.CTcentroids(:,3) <= (CurrentSlice+5) & obj.CTcentroids(:,3) >= (CurrentSlice-5)) ;
                obj.CTslicesWITHspecificFiducials.centroids = obj.CTcentroids(indexCTslices(1):indexCTslices(end),:);
                for i = 1:size(base_points,1)

                    flagCT_x = find((obj.CTslicesWITHspecificFiducials.centroids(:,1)) >= base_points(i,1)-5 & ...
                        (obj.CTslicesWITHspecificFiducials.centroids(:,1)) <= base_points(i,1)+5 ) ;
                    flagCT_y = find((obj.CTslicesWITHspecificFiducials.centroids(:,2)) >= base_points(i,2)-5 & ...
                        (obj.CTslicesWITHspecificFiducials.centroids(:,2)) <= base_points(i,2)+5 ) ;

                        for j = 1:size(flagCT_x,1)
                            flagy = find(flagCT_y == flagCT_x(j));
                            if ~isempty(flagy)
                                flagx = j; break;
                            end
                        end
                    clear j

                    if flagCT_x(flagx) == flagCT_y(flagy)
                        index = flagCT_x(flagx) ;
                        obj.CTPoints(i,:) = obj.CTslicesWITHspecificFiducials.centroids(index,:) ;
                    end

                end



            % Convert CTslicesWITHspecificFiducials.centroids to CTslicesWITHspecificFiducials.coordinates
            for i = 1:size(obj.CTslicesWITHspecificFiducials.centroids,1)

                indx = obj.CTslicesWITHspecificFiducials.centroids(i, 1);
                indy = obj.CTslicesWITHspecificFiducials.centroids(i, 2);
                indz = obj.CTslicesWITHspecificFiducials.centroids(i, 3);

%                 obj.CTcentroids(i,1) = obj.statsCT(i, 1).Centroid(1,1);
%                 obj.CTcentroids(i,2) = obj.statsCT(i, 1).Centroid(1,2);
%                 obj.CTcentroids(i,3) = obj.statsCT(i, 1).Centroid(1,3);

                index_x = [1:1:size(obj.CTImageSet.ImageCoordinates.x)]';
                index_y = [1:1:size(obj.CTImageSet.ImageCoordinates.y)]';
                index_z = [1:1:size(obj.CTImageSet.ImageCoordinates.z)]';

                xCTslice = interp1(index_x,obj.CTImageSet.ImageCoordinates.x,indx);
                yCTslice = interp1(index_y,obj.CTImageSet.ImageCoordinates.y,indy);
                zCTslice = interp1(index_z,obj.CTImageSet.ImageCoordinates.z,indz);

                obj.CTslicesWITHspecificFiducials.coordinates(i,1) = xCTslice;
                obj.CTslicesWITHspecificFiducials.coordinates(i,2) = yCTslice;
                obj.CTslicesWITHspecificFiducials.coordinates(i,3) = zCTslice;

                clear xCTslice yCTslice zCTslice

            end

            % Perform registration
            t_concord = cp2tform(obj.FilmPoints,obj.CTPoints(:,1:2),'projective');

            % Register post films
            obj.PostFilmImageSet.mRegisteredFilmsWithCT.Red = imtransform(obj.PostFilmImageSet.mMeanFilms.Red,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);
            obj.PostFilmImageSet.mRegisteredFilmsWithCT.Green = imtransform(obj.PostFilmImageSet.mMeanFilms.Green,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);
            obj.PostFilmImageSet.mRegisteredFilmsWithCT.Blue = imtransform(obj.PostFilmImageSet.mMeanFilms.Blue,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);

            % Register pre films
            obj.PreFilmImageSet.mRegisteredFilmsWithCT.Red = imtransform(obj.PreFilmImageSet.mRegisteredFilms.Red,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);
            obj.PreFilmImageSet.mRegisteredFilmsWithCT.Green = imtransform(obj.PreFilmImageSet.mRegisteredFilms.Green,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);
            obj.PreFilmImageSet.mRegisteredFilmsWithCT.Blue = imtransform(obj.PreFilmImageSet.mRegisteredFilms.Blue,t_concord,...
                'XData',[1 size(reference_temp,2)], 'YData',[1 size(reference_temp,1)]);

            %Create Total
            Totaltemp(:,:,1) = obj.PostFilmImageSet.mRegisteredFilmsWithCT.Red ;
            Totaltemp(:,:,2) = obj.PostFilmImageSet.mRegisteredFilmsWithCT.Green ;
            Totaltemp(:,:,3) = obj.PostFilmImageSet.mRegisteredFilmsWithCT.Blue ;

            obj.PostFilmImageSet.mTotalRegisteredFilms{1,1} = uint16(Totaltemp) ;

           % CT slice to use for comparison
           CurrentSlice = GetGlobalVar('CurrentSlice');
           CTsliceONdemand = find(obj.CTcentroids(:,3) <= (CurrentSlice+1) & obj.CTcentroids(:,3) >= (CurrentSlice-1)) ;
           obj.meanZcoordinate = mean(obj.FiducialCoordsCT(CTsliceONdemand,3)) ;
           figure;
           h1 = slice(obj.CTImageSet.ImageCoordinates.x,obj.CTImageSet.ImageCoordinates.y,obj.CTImageSet.ImageCoordinates.z,...
               double(obj.CTImageSet.mImagesData),[],[],obj.meanZcoordinate,'nearest');
           obj.CT2FilmSlice = get(h1,'CDATA'); close;

                % Bring RTDOSE to CT coordinates
                rtdose2CT_initialize = double(obj.TPSRTDose.mDoseCube).*obj.TPSRTDose.mDoseGridScaling;
                figure;
                h2 = slice(obj.TPSRTDose.mRTDoseCoordinates.x,obj.TPSRTDose.mRTDoseCoordinates.y,obj.TPSRTDose.mRTDoseCoordinates.z,...
                    rtdose2CT_initialize,[],[],obj.meanZcoordinate,'nearest');
                TPSRTDoseCTsliceTemp = get(h2,'CDATA'); close;
                [xx, yy] = meshgrid(obj.CTImageSet.ImageCoordinates.x,obj.CTImageSet.ImageCoordinates.y);
                obj.CT2FilmSlice_DOSE = interp2(obj.TPSRTDose.mRTDoseCoordinates.x,...
                    obj.TPSRTDose.mRTDoseCoordinates.y,TPSRTDoseCTsliceTemp,xx,yy,'linear');
%                 figure, imagesc(obj.CTImageSet.ImageCoordinates.x,obj.CTImageSet.ImageCoordinates.y,obj.CT2FilmSlice_DOSE), daspect([1 1 1])




               message = 'Registration has been successfully completed';
               obj.fregistration = 1 ;
               obj.fCT2FilmSlice = 1 ;
               obj.fCT2FilmSlice_DOSE = 1 ;
               out = 1;

           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
%                disp(ex.message);
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%




        % ----------------------------------------------------------------%
        function [out, message ] = CalculateFilmODmap(obj)

           out = 0;
           message = '';

          if obj.fPostFilmImageSet == 0 || obj.fPreFilmImageSet == 0
             message = 'Both pre and post-irradiation films must be loaded to calculate ODmap for single channel dosimetry';
             return;
          end

           CurrentPath = pwd;

           try

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;

               if obj.fPostFilmImageSet == 1 && obj.fPreFilmImageSet == 1

                  obj.SingleChannel.ODmap.Red = -log10(obj.PostFilmImageSet.mRegisteredFilmsWithCT.Red./obj.PreFilmImageSet.mRegisteredFilmsWithCT.Red);

                  flag1 = find(obj.SingleChannel.ODmap.Red <= 0 );
                  flag2 = find(obj.SingleChannel.ODmap.Red == -Inf );
                  obj.SingleChannel.ODmap.Red(flag1) = NaN ;
                  obj.SingleChannel.ODmap.Red(flag2) = NaN ;
%                         %Create Total
%                         TotaltempOD(:,:,1) = obj.ODmap.Red ;
%                         TotaltempOD(:,:,2) = obj.ODmap.Green ;
%                         TotaltempOD(:,:,3) = obj.ODmap.Blue ;
%
%                         obj.mTotalODmap{1,1} = uint16(TotaltempOD) ;


                 message = 'Optical Density map was successfully calculated';
                 obj.fODmapSingleChannel = 1 ;
                 out = 1;

               end

           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
%                disp(ex.message);
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%



        % ----------------------------------------------------------------%
        function [out, message ] = CalculateDosemap(obj)

           out = 0;
           message = '';

           CurrentPath = pwd;

           try

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;

                  if obj.fODmapSingleChannel == 0
                     out = -1;
                     message = 'Optical Density must be first calculated to proceed';
                     return;
                  end

                  if obj.fCalibration == 0
                     out = -1;
                     message = 'Please load a valid Calibration Curve to proceed';
                     return;
                  end


                   if obj.fODmapSingleChannel == 1 && obj.fCalibration == 1

                        obj.SingleChannel.Film_DoseMap(:,:) = ( (obj.SingleChannel.ODmap.Red.*obj.CalibrationCoefficients.a) + ...
                            obj.CalibrationCoefficients.b*(obj.SingleChannel.ODmap.Red.^(obj.CalibrationCoefficients.c)));

                        % Film_DoseMap = Film_DoseMap./1000 ;
                        obj.SingleChannel.FilmDose = wiener2(obj.SingleChannel.Film_DoseMap,[5 5]);


%                         %Create Total
%                         TotaltempOD(:,:,1) = obj.ODmap.Red ;
%                         TotaltempOD(:,:,2) = obj.ODmap.Green ;
%                         TotaltempOD(:,:,3) = obj.ODmap.Blue ;
%
%                         obj.mTotalODmap{1,1} = uint16(TotaltempOD) ;


                       message = 'Dosemap was successfully calculated';
                       obj.fDosemapSingleChannel = 1 ;
                       out = 1;

                   end

           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

           % Restore default mouse cursor
           set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%


        % ----------------------------------------------------------------%
        function [out, message ] = CalculateGammaMap(obj)

           out = 0;
           message = '';

           CurrentPath = pwd;

           try

               %Set mouse cursor to "loading"
               set(gcf,'Pointer','Watch'); drawnow;

                  if obj.fDosemapSingleChannel == 0
                     out = -1;
                     message = 'Film Dosemap must be first calculated to proceed';
                     return;
                  end

                  if  obj.fCT2FilmSlice == 0
                     out = -1;
                     message = 'Please confirm the CTslice selected to proceed';
                     return;
                  end


                   if obj.fDosemapSingleChannel == 1 && obj.fCT2FilmSlice == 1

                        obj.SingleChannel.Film_DoseMap(:,:) = ( (obj.SingleChannel.ODmap.Red.*obj.CalibrationCoefficients.a) + ...
                            obj.CalibrationCoefficients.b*(obj.SingleChannel.ODmap.Red.^(obj.CalibrationCoefficients.c)));

                        % Film_DoseMap = Film_DoseMap./1000 ;
                        obj.SingleChannel.FilmDose = wiener2(obj.SingleChannel.Film_DoseMap,[5 5]);


%                         %Create Total
%                         TotaltempOD(:,:,1) = obj.ODmap.Red ;
%                         TotaltempOD(:,:,2) = obj.ODmap.Green ;
%                         TotaltempOD(:,:,3) = obj.ODmap.Blue ;
%
%                         obj.mTotalODmap{1,1} = uint16(TotaltempOD) ;


                       message = 'Dosemap was successfully calculated';
                       obj.fDosemapSingleChannel = 1 ;
                       out = 1;

                   end

           catch
               out = 0;
               message = 'An error has occured. Please try again... ';
%                disp(ex.message);
               %Return to current path in case of loading error
               cd(CurrentPath);
           end

               %Restore default mouse cursor
               set(gcf,'Pointer','Arrow'); drawnow;
        end
        %-----------------------------------------------------------------%


    end

    methods (Access = 'private')
      
      % Returns true if a property starts with 'm', which indicates a flag
      % property
      function out = isFlagProperty(obj, propName)
        propNameChars = char(propName);
        out = propNameChars(1) == 'f';
        
        % alternatively, we could use startsWith(propName, 'f') but I
        % removed it because it does not work in Matlab < 2018a
      end
    end
end
