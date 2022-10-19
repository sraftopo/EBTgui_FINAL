function [ out ] = DicomReadCustom( in )
%DICOMREADCUSTOM Summary of this function goes here
%   Detailed explanation goes here
 dcmData = dicomread(in);
 
    if ~isfield(in, 'Modality') 
        out = dcmData;
        return;
    end
    
    switch in.Modality
        
        case 'RTDOSE'
           ProccessRTDOSE();
        case 'RTSTRUCT'
           ProccessRTSTRUCT();
        case 'RTPLAN'
           ProccessRTPLAN();            
        case 'CT'
           ProccessCT();            
    end
    
    out = dcmData;
    
    %--------------------------------------------------------------------%
    function ProccessRTDOSE()
    %--------------------------------------------------------------------%
      
    end
    
    
    %--------------------------------------------------------------------%
    function ProccessRTSTRUCT()
    %--------------------------------------------------------------------%
    
    
    end
    
    
    %--------------------------------------------------------------------%
    function ProccessRTPLAN()
    %--------------------------------------------------------------------%
    
    
    end
    
    
    %--------------------------------------------------------------------%
    function ProccessCT()
    %--------------------------------------------------------------------%
    
    
    end
 
 
end

