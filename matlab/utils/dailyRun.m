names = {'ADRAI32001F293','ADRAI32001F299','ADRAI32001M300'};
todaysdate = ['20200303'];%[datestr(now,'yyyymmdd')];
basedir = pwd;

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