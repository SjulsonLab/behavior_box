names = {'D1R96F624','D1R96F625','D1R102F596','D1R102M592'};
todaysdate = ['190204'];
basedir = cd;

for idx = 1:length(names)
    cd([basedir filesep names{idx}])
    auxDir = dir;
    for i = 1:length(auxDir)
        if strfind(auxDir(i).name,[names{idx} '_' todaysdate])
            folderOI = auxDir(i).name;
        end
    end
        
%     makePokePlot1([basedir filesep names{idx} filesep folderOI])
    sessionsPokePlot1([basedir filesep names{idx}])
end