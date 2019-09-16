names = {'Black_F','D1R106F699','D1R114F826','D1R114F827','D1R114F829','D1R114F831','D1R114F834','D1R114M828','D1R114M832'};
todaysdate = [20190912]%[datestr(now,'yyyymmdd')];
basedir = cd;

for idx = 1:length(names)
    cd([basedir filesep names{idx}])
    auxDir = dir;
    for i = 1:length(auxDir)
        if strfind(auxDir(i).name,[names{idx} '_' todaysdate])
            folderOI = auxDir(i).name;
        end
    end
        
    
    SessionPlot([basedir filesep names{idx} filesep folderOI])
    fprintf([folderOI ' finished \n'])
end