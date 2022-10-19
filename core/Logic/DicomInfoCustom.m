function [ out ] = DicomInfoCustom( in )
%DICOMINFOCUSTOM Summary of this function goes here
%   Detailed explanation goes here

    dcminfo = dicominfo(in);

    switch dcminfo.Modality

        case 'RTDOSE'
           ProccessRTDOSE();
        case 'RTSTRUCT'
           ProccessRTSTRUCT();
        case 'RTPLAN'
           ProccessRTPLAN();
        case 'CT'
           ProccessCT();
    end

    out = dcminfo;

    %--------------------------------------------------------------------%
    function ProccessRTDOSE()
    %--------------------------------------------------------------------%
        if strfind(dcminfo.Manufacturer,'SagiPlan')
                 pixelSpacingTemp = dcminfo.PixelSpacing;
                 ImagePositionTemp = dcminfo.ImagePositionPatient;

                 dcminfo.PixelSpacing(1) = pixelSpacingTemp(2);
                 dcminfo.PixelSpacing(2) = pixelSpacingTemp(1);
%                  dcminfo.ImagePositionPatient(1) =  ImagePositionTemp(2);
%                  dcminfo.ImagePositionPatient(2) =  ImagePositionTemp(1);
%                  dcminfo.ImagePositionPatient(3) =  ImagePositionTemp(3);
        end

    end


    %--------------------------------------------------------------------%
    function ProccessRTSTRUCT()
    %--------------------------------------------------------------------%


    end


    %--------------------------------------------------------------------%
    function ProccessRTPLAN()
    %--------------------------------------------------------------------%
        if strfind(dcminfo.Manufacturer,'SagiPlan')


        elseif strfind(dcminfo.Manufacturer,'Varian')


        elseif strfind(dcminfo.Manufacturer,'Nucletron')


        end

    end


    %--------------------------------------------------------------------%
    function ProccessCT()
    %--------------------------------------------------------------------%


    end
end
