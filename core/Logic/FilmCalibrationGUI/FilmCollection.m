classdef FilmCollection < handle
    %FILMCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here

% ----------------------------------------------------------------------- %
    properties
            mFilms;
            mCube;
            mMeanFilms;
            mRegisteredFilms;
            mROIs;
            mNumberOfFilms;
            mTotalFilms;
            mTotalRegisteredFilms;
            mRegisteredFilmsWithCT;
    end
% ----------------------------------------------------------------------- %


    methods

% ----------------------------------------------------------------------- %
        function obj = FilmCollection()

        end
% ----------------------------------------------------------------------- %



% ----------------------------------------------------------------------- %
    function out = ReadCollection(obj, type)
        out = 0;
        CurrentPath = pwd;

        [pathname] = uigetdir(GetGlobalVar('LastSearchPath'), ['Choose folder containing ' type ' images']);

        if pathname ~= 0
            SetGlobalVar('LastSearchPath',pathname);
        end

         if isequal(pathname,0)
            return
         else
            cd(pathname)
         end

                [stat, struct] = fileattrib('*.*');

                numberOfFiles = size(struct,2);
                filmCounter = 0;
                counter = 0;


                for i = 1:numberOfFiles
                    name = struct(1,i).Name;


                    if strfind(name,'.tif')

                            filmCounter = filmCounter + 1;

                            filmPathInfo = strsplit(name,'\');
                            filmAbsoluteName = filmPathInfo(end);

                            flag = strsplit(filmAbsoluteName{1},'-') ;

                            newFilmObject = Film(filmAbsoluteName);
                            newFilmObject.ReadFilmData(name);
                            newFilmObject.CreateFilmCoordinates(name);

                            if isempty(obj.mFilms)

                                counter = counter + 1 ;
                                obj.mFilms.(flag{1}){counter,1} = newFilmObject;

                            elseif isfield(obj.mFilms,flag{1})  % strcmp(flag{1},fieldnames(obj.mFilms)) == 1

                                counter = counter + 1 ;
                                obj.mFilms.(flag{1}){counter,1} = newFilmObject;

                            else
                                counter = 0;
                                counter = counter + 1 ;
                                obj.mFilms.(flag{1}){counter,1} = newFilmObject;

                            end


                    end


                end



       % Create Cubes to visualize %


        numOFfilms = numel(fieldnames(obj.mFilms)) ;
        nameOFfilms = fieldnames(obj.mFilms) ;


        for i = 1 : numOFfilms

            tempName = strsplit(nameOFfilms{i},'_') ;

            sortedFilmNames{i,1} = strcat(tempName{1,1},'_',int2str(i)) ;

        end

        %
        numOFscans = size(obj.mFilms.(sortedFilmNames{1,1}),1) ;

        for i = 1:numOFfilms

            for counter = 1:numOFscans

                scan = strcat('scan_',int2str(counter)) ;
                obj.mCube.(scan).Red(:,:,i) = obj.mFilms.(sortedFilmNames{i,1}){counter, 1}.mData.Red(:,:,1) ;
                obj.mCube.(scan).Green(:,:,i) = obj.mFilms.(sortedFilmNames{i,1}){counter, 1}.mData.Green(:,:,1) ;
                obj.mCube.(scan).Blue(:,:,i) = obj.mFilms.(sortedFilmNames{i,1}){counter, 1}.mData.Blue(:,:,1) ;

            end

        end

        % End of Create Cubes to visualize %

        obj.mNumberOfFilms = numOFfilms;

          cd(CurrentPath)
          out = 1;
    end
% ----------------------------------------------------------------------- %



% ----------------------------------------------------------------------- %
    function out = MeanCollection(obj)
        CurrentPath = pwd;
        out = 0;

        numOFfilms = numel(fieldnames(obj.mFilms)) ;
        nameOFfilms = fieldnames(obj.mFilms) ;


        for i = 1 : numOFfilms

            tempName = strsplit(nameOFfilms{i},'_') ;

            sortedFilmNames{i,1} = strcat(tempName{1,1},'_',int2str(i)) ;

        end

        %
        numOFscans = numel(fieldnames(obj.mCube)) ;

        for i = 1:numOFfilms

            tempMean = [];
            tempTotalMean = [];
            for counter = 1:numOFscans

                scan = strcat('scan_',int2str(counter)) ;
                temp.Red{counter,1} = obj.mCube.(scan).Red(:,:,i) ;
                temp.Green{counter,1} = obj.mCube.(scan).Green(:,:,i) ;
                temp.Blue{counter,1} = obj.mCube.(scan).Blue(:,:,i) ;


                  if isempty(tempMean)

                    tempMean.Red = temp.Red{counter,1} ;
                    tempMean.Green = temp.Green{counter,1} ;
                    tempMean.Blue = temp.Blue{counter,1} ;

                  else
                      tempMean.Red = tempMean.Red + temp.Red{counter,1} ;
                      tempMean.Green = tempMean.Green + temp.Green{counter,1} ;
                      tempMean.Blue = tempMean.Blue + temp.Blue{counter,1} ;

                  end

            end

                obj.mMeanFilms.Red(:,:,i) = (tempMean.Red)./numOFscans ;
                obj.mMeanFilms.Green(:,:,i) = (tempMean.Green)./numOFscans ;
                obj.mMeanFilms.Blue(:,:,i) = (tempMean.Blue)./numOFscans ;



           %----------------------------------%
           %

           film = obj.mFilms.(sortedFilmNames{i,1});%.mData;
           tempTotalMean = [];
           for counter = 1:numOFscans
                if isempty(tempTotalMean)
                    tempTotalMean = uint32(film{counter,1}.mData.Total);
                else
                    tempTotalMean = tempTotalMean + uint32(film{counter,1}.mData.Total);
                end
            end
            tempTotalMean = uint16(tempTotalMean./numOFscans);
            obj.mTotalFilms{i,1} = tempTotalMean;
           %----------------------------------%



        end

        % Create Mean Films %


              cd(CurrentPath)
        out = 1;

    end
% ----------------------------------------------------------------------- %







% ----------------------------------------------------------------------- %
    function out = BoundingBox(obj)

        CurrentPath = pwd;
        out = 0;

        numOFfilms = numel(fieldnames(obj.mFilms)) ;
        nameOFfilms = fieldnames(obj.mFilms) ;

        for i = 1 : numOFfilms

            tempName = strsplit(nameOFfilms{i},'_') ;

            sortedFilmNames{i,1} = strcat(tempName{1,1},'_',int2str(i)) ;

        end
        clear i

    for j = 1:numOFfilms

            name = sortedFilmNames{j,1};

            smoothedFilm = wiener2(obj.mMeanFilms.Red (:,:,j) ,[10, 10]);

            PixelValue = min(min(smoothedFilm(:,:,j) ));
            bw1 = (smoothedFilm(:,:,j) >= PixelValue);
            [bw2, NUM] = bwlabeln(bw1);
            c = regionprops(bw2,'basic');
            cP = round(c(1, 1).Centroid );

            t = 15;

            obj.mRegisteredFilms.BoundingBox(:,:,j) = [cP(1)-t, cP(2)-t, cP(1)+t, cP(2)+t];
            obj.mRegisteredFilms.CentralPoint(:,:,j) = cP;

%             imagesc(obj.mMeanFilms.Red(:,:,j)); impixelinfo; daspect([1 1 1]); axis('off');
%             hold on
%             plot(cP(1),cP(2),'o')
%
%             plot([cP(1)-t, cP(1)-t],[cP(2)-t, cP(2)+t],'-b')
%             plot([cP(1)+t, cP(1)+t],[cP(2)-t, cP(2)+t],'-b')
%             plot([cP(1)-t, cP(1)+t],[cP(2)-t, cP(2)-t],'-b')
%             plot([cP(1)-t, cP(1)+t],[cP(2)+t, cP(2)+t],'-b')

        end

        cd(CurrentPath)
        out = 1;

    end

% ----------------------------------------------------------------------- %








% ----------------------------------------------------------------------- %
    function out = ROImeanPVs(obj)

        CurrentPath = pwd;
        out = 0;


        numOFfilms = numel(fieldnames(obj.mFilms)) ;
        nameOFfilms = fieldnames(obj.mFilms) ;

%         hbar = waitbar(0,'Calculating ROIs mean Pivel Values. Please wait...');

    for j = 1:numOFfilms

%         waitbar(j/numOFfilms);

        bb =  obj.mRegisteredFilms.BoundingBox(:,:,j)  ;

        if isfield(obj.mRegisteredFilms,'Red')
            obj.mROIs.Red(:,:,j) = wiener2(obj.mRegisteredFilms.Red (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter
            obj.mROIs.Green(:,:,j) = wiener2(obj.mRegisteredFilms.Green (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter
            obj.mROIs.Blue(:,:,j) = wiener2(obj.mRegisteredFilms.Blue (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter

            obj.mROIs.meanPVs.Red(j,1) = mean2(obj.mROIs.Red(:,:,j));
            obj.mROIs.stdPV.Red(j,1) = std2(obj.mROIs.Red(:,:,j));
            obj.mROIs.meanPVs.Green(j,1) = mean2(obj.mROIs.Green(:,:,j));
            obj.mROIs.stdPV.Green(j,1) = std2(obj.mROIs.Green(:,:,j));
            obj.mROIs.meanPVs.Blue(j,1) = mean2(obj.mROIs.Blue(:,:,j));
            obj.mROIs.stdPV.Blue(j,1) = std2(obj.mROIs.Blue(:,:,j));

        else
            obj.mROIs.Red(:,:,j) = wiener2(obj.mMeanFilms.Red (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter
            obj.mROIs.Green(:,:,j) = wiener2(obj.mMeanFilms.Green (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter
            obj.mROIs.Blue(:,:,j) = wiener2(obj.mMeanFilms.Blue (bb(1):bb(3),bb(2):bb(4),j),[7 7]);   % Remove Image Noise with wienner filter

            obj.mROIs.meanPVs.Red(j,1) = mean2(obj.mROIs.Red(:,:,j));
            obj.mROIs.stdPV.Red(j,1) = std2(obj.mROIs.Red(:,:,j));
            obj.mROIs.meanPVs.Green(j,1) = mean2(obj.mROIs.Green(:,:,j));
            obj.mROIs.stdPV.Green(j,1) = std2(obj.mROIs.Green(:,:,j));
            obj.mROIs.meanPVs.Blue(j,1) = mean2(obj.mROIs.Blue(:,:,j));
            obj.mROIs.stdPV.Blue(j,1) = std2(obj.mROIs.Blue(:,:,j));

        end

        clear bb

%         waitbar(j/numOFfilms);

    end

%      close(hbar)
     cd(CurrentPath)
     out = 1;

    end
% ----------------------------------------------------------------------- %





    end

end
