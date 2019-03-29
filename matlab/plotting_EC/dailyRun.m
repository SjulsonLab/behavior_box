function dailyRun(basedir)

names = {'D1R104M738','D1R104M737','ADR50F695'};
todaysdate = ['20190321'];
basedir = cd;

for idx = 1:length(names)
    cd([basedir filesep names{idx}])
    auxDir = dir;
    for i = 1:length(auxDir)
        if strfind(auxDir(i).name,[names{idx} '_' todaysdate])
            folderOI = auxDir(i).name;
        end
    end
        
    makePokePlot1([basedir filesep names{idx} filesep folderOI])
    fixed_choice_accuracy([basedir filesep names{idx} filesep folderOI])
    %sessionsPokePlot1([basedir filesep names{idx}])
end





