classdef FilmSceneController < handle
    %FILMSCENECONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PreCollection;
        PostCollection;
        BgPreCollection;
        BgPostCollection;
        
        fPreCollection;
        fPostCollection;
        fBgPreCollection;
        fBgPostCollection;
        
        mNumberOfFilms;
        mNumberOfBgFilms;
        DR_control;
        sigmaDR_control;
        netDR;
        sigmaNetDR;
        netOD;
        sigmaNetOD;
        CalibrationResults;
        dose;
        FitData;
        
        fRegistrationPerformed;
        fBgRegistrationPerformed;
        fBoundingBox;
        fBgBoundingBox;
        fHasRois;
        fHasBgRois;
        fHasMeanPVs;
        fHasMeanBgPVs;
        fHasDR_OD;
        fHasDose;
        fHasFit;
        
    end
    
    methods
        
        %-----------------------------------------------------------------%
        function obj = FilmSceneController()
            obj.Reset('all'); 
        end
        %-----------------------------------------------------------------%
        
        
        %-----------------------------------------------------------------%
        function [out message] = ImportData(obj, type)
           
           out = 0;
           message = '';
           
           CurrentPath = pwd;
           
           try
               %Create a new collection
               newCollection = FilmCollection();
               importResult = newCollection.ReadCollection(type);
               
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

                       if(obj.fPostCollection == 1)
                           if(obj.mNumberOfFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.PreCollection = [];
                               obj.fPreCollection = 0;
                               set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfFilms = newCollection.mNumberOfFilms;
                       end                   
                       obj.PreCollection = newCollection;
                       obj.fPreCollection = 1;
                       obj.RegisterPrePostCollections();

                   case 'Post'

                       if(obj.fPreCollection == 1)
                           if(obj.mNumberOfFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.PostCollection = [];
                               obj.fPostCollection = 0;
                               set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfFilms = newCollection.mNumberOfFilms;
                       end                   
                       obj.PostCollection = newCollection;   
                       obj.fPostCollection = 1;
                       obj.RegisterPrePostCollections();

                   case 'BgPre'

                       if(obj.fBgPostCollection == 1)
                           if(obj.mNumberOfBgFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.BgPreCollection = [];
                               obj.fBgPreCollection = 0;
                               set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfBgFilms = newCollection.mNumberOfFilms;
                       end        
                       obj.BgPreCollection = newCollection; 
                       obj.fBgPreCollection = 1;
                       obj.RegisterBgPrePostCollections();

                   case 'BgPost'
                       if(obj.fBgPreCollection == 1)
                           if(obj.mNumberOfBgFilms ~= newCollection.mNumberOfFilms)
                               message = 'Inconsistent dimensions between the two datasets';
                               %Reset data on error
                               obj.BgPostCollection = [];
                               obj.fBgPostCollection = 0;
                                set(gcf,'Pointer','Arrow'); drawnow;
                               return;
                           end
                       else
                           obj.mNumberOfBgFilms = newCollection.mNumberOfFilms;                       
                       end   
                       obj.BgPostCollection = newCollection;
                       obj.fBgPostCollection = 1;
                       obj.RegisterBgPrePostCollections();
                       
           
           
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
        function [out, message, errorcode] = Reset(obj, type)   
            
            out = 0;
            message = '';
            errorcode = 0;
            
            try
                switch  type
                    case 'films'
                        obj.PreCollection = [];
                        obj.PostCollection = [];
                        obj.fPreCollection = 0;
                        obj.fPostCollection = 0;
                        obj.mNumberOfFilms = 0;
                        obj.fRegistrationPerformed = 0;
                        obj.fBoundingBox = 0;
                        obj.fHasRois = 0;
                        obj.fHasRois = 0;
                        obj.fHasMeanPVs = 0;
                        obj.fHasDR_OD = 0;
                        obj.FitData = [];
                        
                    case 'bgfilms'
                        obj.BgPreCollection = [];
                        obj.BgPostCollection = [];
                        obj.fBgPreCollection = 0;
                        obj.fBgPostCollection = 0;
                        obj.mNumberOfBgFilms = 0;
                        obj.fBgRegistrationPerformed = 0;
                        obj.fBgBoundingBox = 0;
                        obj.fHasBgRois = 0;
                        obj.fHasMeanPVs = 0;
                        obj.fHasDR_OD = 0;
                        obj.FitData = [];
                        
                    case 'all'
                        obj.PreCollection = [];
                        obj.PostCollection = [];
                        obj.fPreCollection = 0;
                        obj.fPostCollection = 0;
                        obj.mNumberOfFilms = 0;
                        obj.BgPreCollection = [];
                        obj.BgPostCollection = [];
                        obj.fBgPreCollection = 0;
                        obj.fBgPostCollection = 0;
                        obj.mNumberOfBgFilms = 0;
                        obj.fRegistrationPerformed = 0;
                        obj.fBgRegistrationPerformed = 0;
                        obj.fBoundingBox = 0;
                        obj.fBgBoundingBox = 0;
                        obj.fHasRois = 0;
                        obj.fHasBgRois = 0;
                        obj.fHasMeanPVs = 0;
                        obj.fHasMeanBgPVs = 0;
                        obj.fHasDR_OD = 0;
                        obj.FitData = [];
                end
                out = 1;
             
            catch ex
                disp('Unable to reset film controller. Reason:');
                disp(ex.message);
                message = ex.message;
                errorcode = 1;
            end
        
        end
        %-----------------------------------------------------------------%
        
        
        %-----------------------------------------------------------------%
        function out = RegisterPrePostCollections(obj, type)
            
            out = 0;
            if(obj.fPostCollection == 1)&&(obj.fPreCollection == 1)

                [optimizer, metric] = imregconfig('monomodal') ;

                for j = 1:obj.mNumberOfFilms

                    tform = imregtform(obj.PreCollection.mMeanFilms.Red(:,:,j),obj.PostCollection.mMeanFilms.Red(:,:,j),...
                                                             'rigid',optimizer,metric);

                    obj.PreCollection.mRegisteredFilms.Red(:,:,j) = imwarp(obj.PreCollection.mMeanFilms.Red(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostCollection.mMeanFilms.Red(:,:,j)))); 
                    obj.PreCollection.mRegisteredFilms.Green(:,:,j) = imwarp(obj.PreCollection.mMeanFilms.Green(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostCollection.mMeanFilms.Green(:,:,j)))); 
                    obj.PreCollection.mRegisteredFilms.Blue(:,:,j) = imwarp(obj.PreCollection.mMeanFilms.Blue(:,:,j),tform,'OutputView',...
                                                              imref2d(size(obj.PostCollection.mMeanFilms.Blue(:,:,j)))); 

                end
                obj.fRegistrationPerformed = 1;
                out = 1;

            else
                out = 1;
                return;
            end
        end
        %-----------------------------------------------------------------%
                    

        %-----------------------------------------------------------------%
        function out = RegisterBgPrePostCollections(obj, type)

            if(obj.fBgPostCollection == 1)&&(obj.fBgPreCollection == 1)

            [optimizer, metric] = imregconfig('monomodal') ;

            for j = 1:obj.mNumberOfBgFilms

                tform = imregtform(obj.BgPreCollection.mMeanFilms.Red(:,:,j),obj.BgPostCollection.mMeanFilms.Red(:,:,j),...
                                                         'rigid',optimizer,metric);

                obj.BgPreCollection.mRegisteredFilms.Red(:,:,j) = imwarp(obj.BgPreCollection.mMeanFilms.Red(:,:,j),tform,'OutputView',...
                                                          imref2d(size(obj.BgPostCollection.mMeanFilms.Red(:,:,j)))); 
                obj.BgPreCollection.mRegisteredFilms.Green(:,:,j) = imwarp(obj.BgPreCollection.mMeanFilms.Green(:,:,j),tform,'OutputView',...
                                                          imref2d(size(obj.BgPostCollection.mMeanFilms.Green(:,:,j)))); 
                obj.BgPreCollection.mRegisteredFilms.Blue(:,:,j) = imwarp(obj.BgPreCollection.mMeanFilms.Blue(:,:,j),tform,'OutputView',...
                                                          imref2d(size(obj.BgPostCollection.mMeanFilms.Blue(:,:,j)))); 

            end
            obj.fBgRegistrationPerformed = 1;

            else
                return;
            end
                    
                    
        end
        %-----------------------------------------------------------------%
            
            
            
        
        
        %-----------------------------------------------------------------%
        function [out ,message, errorcode] = CreateROIauto(obj)
            
            out = 0;
            message = '';
            errorcode = 0;
            
            
            if (obj.fPostCollection == 1)&&(obj.fPreCollection == 1) 
            
                try
                    for j = 1:obj.mNumberOfFilms

                        smoothedFilm = wiener2(obj.PostCollection.mMeanFilms.Red (:,:,j) ,[7, 7]);

                        PixelValue = min(min(smoothedFilm ));
                        bw1 = (smoothedFilm > PixelValue);
                        [bw2, NUM] = bwlabeln(bw1);
                        c = regionprops(bw2,'basic');
                        cP = round(c(1, 1).Centroid );
                        t = 20 ;
                        obj.PreCollection.mRegisteredFilms.BoundingBox(:,:,j) = [cP(1)-t, cP(2)-t, cP(1)+t, cP(2)+t];
                        obj.PreCollection.mRegisteredFilms.CentralPoint(:,:,j) = cP;

                        obj.PostCollection.mRegisteredFilms.BoundingBox(:,:,j) = [cP(1)-t, cP(2)-t, cP(1)+t, cP(2)+t];
                        obj.PostCollection.mRegisteredFilms.CentralPoint(:,:,j) = cP;

                    end

                    out = 1;    
                    obj.fBoundingBox = 1;
                    obj.fHasRois = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end
            end
            
            if (obj.fBgPostCollection == 1)&&(obj.fBgPreCollection == 1)
                
                try
                    for j = 1:obj.mNumberOfBgFilms

                        smoothedFilm = wiener2(obj.BgPostCollection.mMeanFilms.Red (:,:,j) ,[7, 7]);

                        PixelValue = min(min(smoothedFilm ));
                        bw1 = (smoothedFilm > PixelValue);
                        [bw2, NUM] = bwlabeln(bw1);
                        c = regionprops(bw2,'basic');
                        cP = round(c(1, 1).Centroid );
                        t = 20 ;
                        obj.BgPreCollection.mRegisteredFilms.BoundingBox(:,:,j) = [cP(1)-t, cP(2)-t, cP(1)+t, cP(2)+t];
                        obj.BgPreCollection.mRegisteredFilms.CentralPoint(:,:,j) = cP;

                        obj.BgPostCollection.mRegisteredFilms.BoundingBox(:,:,j) = [cP(1)-t, cP(2)-t, cP(1)+t, cP(2)+t];
                        obj.BgPostCollection.mRegisteredFilms.CentralPoint(:,:,j) = cP;

                    end

                    out = 1;    
                    obj.fBgBoundingBox = 1;
                    obj.fHasBgRois = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end

            else
                message = 'Both Pre and Post datasets are required in order to create ROIs';
            end

        end
        %-----------------------------------------------------------------%
        

        
        %-----------------------------------------------------------------%
        function [out, message, warningcode] = MeanROIvalues(obj)

                    out = 0;
                    message = '';
                    warningcode = 0;


                    if (obj.fHasRois == 1)

                        try
                            for j = 1:obj.mNumberOfFilms

                                bb =  obj.PostCollection.mRegisteredFilms.BoundingBox(:,:,j) ;

                                ROIpre.Red = obj.PreCollection.mRegisteredFilms.Red(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpre.Green = obj.PreCollection.mRegisteredFilms.Green(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpre.Blue = obj.PreCollection.mRegisteredFilms.Blue(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 

                                obj.PreCollection.mROIs.Red.PV(j,1) = mean2(ROIpre.Red(:,:)); 
                                obj.PreCollection.mROIs.Red.std(j,1) = std2(ROIpre.Red(:,:));
                                obj.PreCollection.mROIs.Green.PV(j,1) = mean2(ROIpre.Green(:,:)); 
                                obj.PreCollection.mROIs.Green.std(j,1) = std2(ROIpre.Green(:,:));
                                obj.PreCollection.mROIs.Blue.PV(j,1) = mean2(ROIpre.Blue(:,:)); 
                                obj.PreCollection.mROIs.Blue.std(j,1) = std2(ROIpre.Blue(:,:));


                                ROIpost.Red = obj.PostCollection.mMeanFilms.Red(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpost.Green = obj.PostCollection.mMeanFilms.Green(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpost.Blue = obj.PostCollection.mMeanFilms.Blue(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 

                                obj.PostCollection.mROIs.Red.PV(j,1) = mean2(ROIpost.Red(:,:)); 
                                obj.PostCollection.mROIs.Red.std(j,1) = std2(ROIpost.Red(:,:));
                                obj.PostCollection.mROIs.Green.PV(j,1) = mean2(ROIpost.Green(:,:)); 
                                obj.PostCollection.mROIs.Green.std(j,1) = std2(ROIpost.Green(:,:));
                                obj.PostCollection.mROIs.Blue.PV(j,1) = mean2(ROIpost.Blue(:,:)); 
                                obj.PostCollection.mROIs.Blue.std(j,1) = std2(ROIpost.Blue(:,:));


                               clear bb ROIpre ROIpost

                            end

                            out = 1;
                            obj.fHasMeanPVs = 1;

                        catch ex
                            disp(ex.message);
                            message = ex.message;
        %                     warningcode = 2;
                            out = 0;
                        end
                    end

                    if (obj.fHasBgRois == 1)

                        try
                            for j = 1:obj.mNumberOfBgFilms

                                bb =  obj.BgPostCollection.mRegisteredFilms.BoundingBox(:,:,j) ;

                                ROIpre.Red = obj.BgPreCollection.mRegisteredFilms.Red(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpre.Green = obj.BgPreCollection.mRegisteredFilms.Green(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpre.Blue = obj.BgPreCollection.mRegisteredFilms.Blue(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 

                                obj.BgPreCollection.mROIs.Red.PV(j,1) = mean2(ROIpre.Red(:,:)); 
                                obj.BgPreCollection.mROIs.Red.std(j,1) = std2(ROIpre.Red(:,:));
                                obj.BgPreCollection.mROIs.Green.PV(j,1) = mean2(ROIpre.Green(:,:)); 
                                obj.BgPreCollection.mROIs.Green.std(j,1) = std2(ROIpre.Green(:,:));
                                obj.BgPreCollection.mROIs.Blue.PV(j,1) = mean2(ROIpre.Blue(:,:)); 
                                obj.BgPreCollection.mROIs.Blue.std(j,1) = std2(ROIpre.Blue(:,:));


                                ROIpost.Red = obj.BgPostCollection.mMeanFilms.Red(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpost.Green = obj.BgPostCollection.mMeanFilms.Green(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 
                                ROIpost.Blue = obj.BgPostCollection.mMeanFilms.Blue(bb(1):bb(3),bb(2):bb(4),j);   % Remove Image Noise with wienner filter 

                                obj.BgPostCollection.mROIs.Red.PV(j,1) = mean2(ROIpost.Red(:,:)); 
                                obj.BgPostCollection.mROIs.Red.std(j,1) = std2(ROIpost.Red(:,:));
                                obj.BgPostCollection.mROIs.Green.PV(j,1) = mean2(ROIpost.Green(:,:)); 
                                obj.BgPostCollection.mROIs.Green.std(j,1) = std2(ROIpost.Green(:,:));
                                obj.BgPostCollection.mROIs.Blue.PV(j,1) = mean2(ROIpost.Blue(:,:)); 
                                obj.BgPostCollection.mROIs.Blue.std(j,1) = std2(ROIpost.Blue(:,:));


                               clear bb ROIpre ROIpost

                            end

                            out = 1;    
                            obj.fHasMeanBgPVs = 1;

                        catch ex
                            disp(ex.message);
                            message = ex.message;
                            out = 0;
                        end

                    else
                        out = 1;
                        warningcode = 1;
                        if ((obj.fBgPreCollection ~= 1)||(obj.fBgPostCollection ~= 1))
                            message = 'To calculate mean values for the background, both Pre and Post BG images are required. Please recalculate mean values after loading background images...';
                        else
                            message = 'Background rois have not been defined. Please create BG Rois to calculate mean values...';
                        end
                    end

        end
        %-----------------------------------------------------------------%
        
        
        
        %-----------------------------------------------------------------%
        function [out, message, errorcode] = Calculate_Reflectance_OpticalDensity(obj)
            
            out = 0;
            message = '';
            errorcode = 0;
            
            
            if (obj.fHasMeanPVs == 1)&&(obj.fHasMeanBgPVs == 1)
            
                try
                    for j = 1:obj.mNumberOfFilms

                        obj.DR_control.Red = ( obj.BgPreCollection.mROIs.Red.PV / (2^16 - 1) ) - ( obj.BgPostCollection.mROIs.Red.PV / (2^16 - 1) ) ;
                        obj.DR_control.Green = ( obj.BgPreCollection.mROIs.Green.PV / (2^16 - 1) ) - ( obj.BgPostCollection.mROIs.Green.PV / (2^16 - 1) ) ;
                        obj.DR_control.Blue = ( obj.BgPreCollection.mROIs.Blue.PV / (2^16 - 1) ) - ( obj.BgPostCollection.mROIs.Blue.PV / (2^16 - 1) ) ;
                        
                        obj.sigmaDR_control.Red = (1/(2^16-1))*sqrt((obj.BgPreCollection.mROIs.Red.std)^2+(obj.BgPostCollection.mROIs.Red.std)^2) ;
                        obj.sigmaDR_control.Green = (1/(2^16-1))*sqrt((obj.BgPreCollection.mROIs.Green.std)^2+(obj.BgPostCollection.mROIs.Green.std)^2) ;
                        obj.sigmaDR_control.Blue = (1/(2^16-1))*sqrt((obj.BgPreCollection.mROIs.Blue.std)^2+(obj.BgPostCollection.mROIs.Blue.std)^2) ;
                        
                        Rbefore.Red(j,1) = obj.PreCollection.mROIs.Red.PV(j,1)./(2^16 - 1) ; 
                        Rafter.Red(j,1) = obj.PostCollection.mROIs.Red.PV(j,1)./(2^16 - 1) ;
                        
                        Rbefore.Green(j,1) = obj.PreCollection.mROIs.Green.PV(j,1)./(2^16 - 1) ; 
                        Rafter.Green(j,1) = obj.PostCollection.mROIs.Green.PV(j,1)./(2^16 - 1) ;
                        
                        Rbefore.Blue(j,1) = obj.PreCollection.mROIs.Blue.PV(j,1)./(2^16 - 1) ; 
                        Rafter.Blue(j,1) = obj.PostCollection.mROIs.Blue.PV(j,1)./(2^16 - 1) ;
                        
                        DR.Red(j,1) = Rbefore.Red(j,1) - Rafter.Red(j,1) ;
                        DR.Green(j,1) = Rbefore.Green(j,1) - Rafter.Green(j,1) ;
                        DR.Blue(j,1) = Rbefore.Blue(j,1) - Rafter.Blue(j,1) ;

                        sigmaDR.Red(j,1) = (1/(2^16-1))*sqrt((obj.PreCollection.mROIs.Red.std(j,1))^2+(obj.PostCollection.mROIs.Red.std(j,1))^2) ;
                        sigmaDR.Green(j,1) = (1/(2^16-1))*sqrt((obj.PreCollection.mROIs.Green.std(j,1))^2+(obj.PostCollection.mROIs.Green.std(j,1))^2) ;
                        sigmaDR.Blue(j,1) = (1/(2^16-1))*sqrt((obj.PreCollection.mROIs.Blue.std(j,1))^2+(obj.PostCollection.mROIs.Blue.std(j,1))^2) ;
                        
                        obj.netDR.Red(j,1) = DR.Red(j,1) - obj.DR_control.Red(1,1) ;
                        obj.netDR.Green(j,1) = DR.Green(j,1) - obj.DR_control.Green(1,1) ;
                        obj.netDR.Blue(j,1) = DR.Blue(j,1) - obj.DR_control.Blue(1,1) ;
                        
                        obj.sigmaNetDR.Red(j,1) = sqrt((sigmaDR.Red(j,1)^2)+(obj.sigmaDR_control.Red^2)) ;
                        obj.sigmaNetDR.Green(j,1) = sqrt((sigmaDR.Green(j,1)^2)+(obj.sigmaDR_control.Green^2)) ;
                        obj.sigmaNetDR.Blue(j,1) = sqrt((sigmaDR.Blue(j,1)^2)+(obj.sigmaDR_control.Blue^2)) ;
                        
                    end

                    out = 1;
                    obj.CalibrationResults(:,1) = obj.netDR.Red(:,1);
                    obj.CalibrationResults(:,2) = obj.sigmaNetDR.Red(:,1); 
                    obj.CalibrationResults(:,3) = obj.netDR.Green(:,1); 
                    obj.CalibrationResults(:,4) = obj.sigmaNetDR.Green(:,1); 
                    obj.CalibrationResults(:,5) = obj.netDR.Blue(:,1); 
                    obj.CalibrationResults(:,6) = obj.sigmaNetDR.Blue(:,1); 
                    obj.fHasDR_OD = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end
            end

            
        end
        %-----------------------------------------------------------------%
        
        
        %-----------------------------------------------------------------%
        function [out, message, errorcode] = Calculate_EBT_netOpticalDensity(obj)
            
            out = 0;
            message = '';
            errorcode = 0;
            
            
            if (obj.fHasMeanPVs == 1)
            
                try
                    for j = 1:obj.mNumberOfFilms

                        obj.netOD.Red(j,1) = log10( obj.PreCollection.mROIs.Red.PV(j,1) / obj.PostCollection.mROIs.Red.PV(j,1) ) ;
                        obj.netOD.Green(j,1) = log10( obj.PreCollection.mROIs.Green.PV(j,1) / obj.PostCollection.mROIs.Green.PV(j,1) ) ;
                        obj.netOD.Blue(j,1) = log10( obj.PreCollection.mROIs.Blue.PV(j,1) / obj.PostCollection.mROIs.Blue.PV(j,1) ) ;
                        
                        obj.sigmaNetOD.Red(j,1) = (1/log(10))*sqrt((obj.PreCollection.mROIs.Red.std(j,1)/obj.PreCollection.mROIs.Red.PV(j,1))^2+...
                                                              (obj.PostCollection.mROIs.Red.std(j,1)/obj.PostCollection.mROIs.Red.PV(j,1))^2) ;
                        obj.sigmaNetOD.Green(j,1) = (1/log(10))*sqrt((obj.PreCollection.mROIs.Green.std(j,1)/obj.PreCollection.mROIs.Green.PV(j,1))^2+...
                                                              (obj.PostCollection.mROIs.Green.std(j,1)/obj.PostCollection.mROIs.Green.PV(j,1))^2) ;
                        obj.sigmaNetOD.Blue(j,1) = (1/log(10))*sqrt((obj.PreCollection.mROIs.Blue.std(j,1)/obj.PreCollection.mROIs.Blue.PV(j,1))^2+...
                                                              (obj.PostCollection.mROIs.Blue.std(j,1)/obj.PostCollection.mROIs.Blue.PV(j,1))^2) ;
                        
                        
                    end

                    out = 1;
                    obj.CalibrationResults(:,1) = obj.netOD.Red(:,1);
                    obj.CalibrationResults(:,2) = obj.sigmaNetOD.Red(:,1); 
                    obj.CalibrationResults(:,3) = obj.netOD.Green(:,1); 
                    obj.CalibrationResults(:,4) = obj.sigmaNetOD.Green(:,1); 
                    obj.CalibrationResults(:,5) = obj.netOD.Blue(:,1); 
                    obj.CalibrationResults(:,6) = obj.sigmaNetOD.Blue(:,1); 
                    obj.fHasDR_OD = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end
            end

            
        end
        %-----------------------------------------------------------------%
        
        
        
        
        %-----------------------------------------------------------------%
        function [out, message, errorcode] = Create_XR_RV3_SingleChannel_CalibrationCurve(obj)
            
            out = 0;
            message = '';
            errorcode = 0;
            
            
            if (obj.fHasDose == 1)
            
                try

% 
                    [FitOutput] = createFit_XR_RV3_DEVICprotocol(obj.dose(:,1), obj.netDR.(GetGlobalVar('CurrentColor')));



                    FitRes = FitOutput.fitresult;
                    FitResults = [FitRes.a; FitRes.b; FitRes.c];
                    FitOutput.FitCoefficients = FitResults ;
                    
                    obj.FitData = FitOutput;

                    out = 1;
                    obj.fHasFit = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end
            else
                message = 'Please fill dose values to create calibration curve.';
            end

            
        end
        %-----------------------------------------------------------------%
        
        
        %-----------------------------------------------------------------%
        function [out, message, errorcode] = Create_EBT3_SingleChannel_CalibrationCurve(obj)
            
            out = 0;
            message = '';
            errorcode = 0;
            
            
            if (obj.fHasDose == 1)
            
                try

% 
                    [FitOutput] = createFit_Devic_protocol_EBT3_SingleChannel(obj.netOD.(GetGlobalVar('CurrentColor')),obj.dose(:,1));



                    FitRes = FitOutput.fitresult;
                    FitResults = [FitRes.a; FitRes.b];
                    FitOutput.FitCoefficients = FitResults ;
                    
                    obj.FitData = FitOutput;

                    out = 1;
                    obj.fHasFit = 1;

                catch ex
                    disp(ex.message);
                    message = ex.message;
                    errorcode = 2;
                    out = 0;
                end
            else
                message = 'Please fill dose values to create calibration curve.';
            end

            
        end
        %-----------------------------------------------------------------%        

        
        
    end
    
end

