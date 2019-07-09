

function organize_BehavFolders(basedir)

%% % This function was made to organize the behavior box folder. By the time
% this code was written, our functions to control the boxes would save the
% the behavioral data in a folder with animal name_date_time and save it in
% the google drive in a folder containing all the behavioral data. However,
% most of our codes to analyze the data depends in a specific structure of
% folders where an animal folder contains every session that animal ever
% went through.
%
% How this code works: It searches for session folders of animals outside
% of their respective folders and move them inside their respective folder
%
% created by Eliezyer F. de Oliveira - 2019/07/08

%% TO-DO LIST
% [] See which folders needs to be created and show to user and ask if they
% want all of them needs to be created
% [] Spit out name of folders that are potentially empty because of a
% problem (i.e. doesn't have the two .mat files in it) and that can be
% deleted

%Initializing variables
firstPass = [];
secondPass = [];
rejectedFolders = [];

cd(basedir)
behaviorDir = dir;


folders = [behaviorDir.isdir];
folderNames = {behaviorDir(folders).name};

%first check if there are folders
auxLength = cellfun(@(x) length(x)>=16,folderNames);
if sum(auxLength>0)
    firstPass = {folderNames{auxLength}};
    aux = {folderNames{~auxLength}};
    if length(aux)>2
        rejectedFolders = {aux{3:end}};
    end
else
    warning('No potential session folders to be organized')
end

%now veryfing for date and hour in the name of the folder
if ~isempty(firstPass)
    temp = cellfun(@(x) [numel(num2str(str2num(x(end-14:end-7))))==8 && ...
        numel(num2str(str2num(x(end-5:end))))>=5],firstPass);
    
    if sum(temp>0)
        secondPass = {firstPass{temp}};
        rejectedFolders = [rejectedFolders,{firstPass{~temp}}];
        
    else
        warning('No potential session folder to be organized')
    end
end

%now we have to find for which animal folder it belongs, if there is any.
if ~isempty(secondPass)
    %Check for name of rejected folders to see if there is any full match
    %with the ones that got here
    if ~isempty(rejectedFolders)
        for i = 1:length(rejectedFolders)
            temp = cellfun(@(x) strfind(x,rejectedFolders{i}),secondPass,'UniformOutput',false);
            folders2transfer(i,:) = cellfun(@(x) ~isempty(x),temp); %this is a matrix indicating to which folder each of the files should be transferred
            
        end
        
        for i = 1:length(secondPass)
            aux = find(folders2transfer(:,i));
            
            if length(aux) == 1 %what if it's 2?
                %first check if the matlab files are inside the animal folder
                cd(secondPass{i})
                if isfile('mouse_info.mat') && isfile('session_info.mat')
                    cd ..
                    %here insert the system command to move the session folder inside the
                    %animal folder
                    [status,result] = system(['mv ' secondPass{i} ' ' rejectedFolders{aux}]);
                    if status == 0
                        fprintf(['\n Folder ' secondPass{i} ' successfully tranferred to ' rejectedFolders{aux} ])
                    else
                        fprintf(['\n Error transferring folder ' secondPass{i} ' to ' rejectedFolders{aux} ' \n' ...
                            '-Error: ' result])
                    end
                else
                    cd ..
                end
                
            end
        end
        
        
    else
        
        %find which animal folders are missing
        
        noMainFolder = secondPass;
        
        fprintf(['There are potential folders to be organized, \n'...
            'but no main animal folder was found, should it \n' ...
            'be created and the session folders transfered?\n\n' ...
            'Here is the list of new folders to be created: \n'])
        for i = 1:length(noMainFolder)
            fprintf(['  - ' noMainFolder{i}(1:end-16) ' \n'])
        end
    end
    
    
end




end