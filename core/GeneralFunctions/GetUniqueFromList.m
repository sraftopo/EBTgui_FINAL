%Given a list of dicom filer and a certain filter, it returns unique
%results
function [ uniqueList, uniqueCounter] = GetUniqueFromList( fullList, filterName)
%SELECTFROMLIST Summary of this function goes here
%   Detailed explanation goes here
uniqueList = {};
uniqueCounter  = 0;
   
%These filters indicate the search fields
defaultFilters = {'PatientID', 'SeriesInstanceUID', 'StudyInstanceUID', 'PatientName','Modality','SOPInstanceUID'};

    %First check to see if filter exists
    if~isempty(filterName)
           [exists filterIndex] =find(strcmp(filterName,defaultFilters)==1);
           if isempty(exists)
               disp('Not existing filter');
               return;
           end
    end
    %If the applied filter exists, filterIndex will indicate the column on
    %which this filter should be searched at.

   for index =  1:size(fullList,1)
      currentValue = fullList{index, filterIndex};
      if ~isempty(currentValue)
         %Search in the unique list for the filterValue
        [exists resultColumns] = find(strcmp(uniqueList,currentValue)==1);   
        if isempty(exists)
            uniqueCounter = uniqueCounter + 1;
            uniqueList{uniqueCounter,1} = currentValue;
        end
      end
   end
  
end


