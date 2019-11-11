function movie_all = importIncomingMovies(directory, file_baseName, filesExpected)

clear movie_all
ImportWarning_Waiting_Shown = 0;
ImportWarning_OpenAccess_Shown = 0;
lastImportedFileIdx = 0;
while lastImportedFileIdx < filesExpected
    if ImportWarning_Waiting_Shown == 0
        disp('Looking for files to import')
        ImportWarning_Waiting_Shown = 1;
    end
    
    dirProps = dir([directory , '\', file_baseName, '*.tif']);
    
    if size(dirProps,1) > 0
        fileNames = str2mat(dirProps.name);
        fileNames_temp = fileNames;
        fileNames_temp(:,[1:numel(file_baseName), end-3:end]) = [];
        fileNums = str2num(fileNames_temp);
        
        if size(fileNames,1) > lastImportedFileIdx
            if fopen([directory, '\', fileNames(lastImportedFileIdx+1,:)]) ~= -1
                
                disp(['===== Importing:    ', fileNames(lastImportedFileIdx+1,:), '====='])
                movie_chunk = bigread4([directory, '\', fileNames(lastImportedFileIdx+1,:)]);
                
                if ~exist('movie_all')
                    movie_all = movie_chunk;
                else
                    movie_all = cat(3, movie_all, movie_chunk);
                end
                
                disp(['Completed import'])
                lastImportedFileIdx = lastImportedFileIdx + 1;
                ImportWarning_Waiting_Shown = 0;
                ImportWarning_OpenAccess_Shown = 0;
                
            else if ImportWarning_OpenAccess_Shown == 0
                    disp('New file found, waiting for access to file')
                    ImportWarning_OpenAccess_Shown = 1;
                end
            end
        end
    end
end