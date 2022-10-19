function errorReport( where, err )
 %open file
 try
   fullpath = strcat(GetGlobalVar('LocalDataFolder'),'\log\logFile.txt');
   fid = fopen(fullpath,'a+');
   % write the error to file
   % first line: message
   fprintf(fid,'\n%s\n',datestr(now, 'HH:MM:SS'));
   fprintf(fid,'%s\n',where);
   fprintf(fid,'%s\n',err.message);
   % close file
   fclose(fid);
 catch ex
 end
   
   
end
