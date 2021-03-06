function plot_2AFC(params)

% Function to plot all figures to evaluate performance of animals in the 2
% alternated forced choice. This function has the capability of plotting
% all plots developed for this task (sessionsPlot / trainingPlot and% etc),
% it's also possible to redo plots for all the sessions one by one. For
% simplicity, this function was created to be used with the script
% dailyRun.m
%
%    This function assumes your data is in the following folder structure:
% ########
% .
% +-- _data(basedir)
% |   +-- _subject1
% |   |   +-- _session1 (this folder in format subject1_yyyymmdd_hhmmss)
% |   |   |   +--  subject1_yyyymmdd_hhmmss.txt
% |   |   |   +--  mouse_info.mat
% |   |   |   +--  session_info.mat
% |   |   +-- _session2
% |   |   +-- _session3
% |   +-- _subject2
% |   |   +-- _session1
% |   |   +-- _session2
% |   |   +-- _session3
% |   |   +-- _session4
% |   |   +-- _session5
% |   +-- _subject3
%
% ########
%
%  INPUT: params - structure to parse parameters to use in this function,
%  first create this structure with all the inputs you need, se more
%  details below:
%
%         - params.basedir: base directory where all the data are stored.
%         see the folder structure above. This field is always needed for
%         this function to run
%
%         - params.subject: name of the subjects in which you want to
%         plot the data. they have to come in a cell array, e.g.,
%         {'D1R104M738','D1R104M737','ADR50F695'}; This field is always
%         needed to run this function.
%
%         - params.sessionsdate: date of the sessions you want to do the
%         session plots on. It should be a cell array with the dates given
%         by strings in the format 'yyyymmdd', e.g.,
%         {'20190327','20190327'}. If set to {'all'} then plot all the
%         sessions in the subject's folder
%
%         - params.plotTraining: boolean variable [true (default) | false]
%         to plot or not the training plot (across sessions figures).
%         Default value is true.
%
%         - params.plotSession: boolean variable [true (default) | false]
%         to plot or not the session plot (individual session figure).
%         Default value is true. If plotSession is true then sessionsdate
%         is required as input.
%  
%  Example:
%         
%         >> params.basedir = '/media/user/SSD/testBehData/'
%         >> params.subject = {'D1R104M738','D1R104M737','ADR50F695'};
%         >> params.sessionsdate = {'20190327','20190327'}
%         >> plot_2AFC(params)
%
%

%to do list:
%[] select individual session within subjects
%

%   developed by Eliezyer de Oliveira - 05/04/2019

%checking the inputs


if isfield(params,'basedir')
    basedir = params.basedir;
else
    error('No base directory provided, type "help plot_2AFC" for more details')
end    

if isfield(params,'subject')
    if iscell(params.subject)
        names = params.subject;
    else
        error('Subject should be typed in cell array format, type "help plot_2AFC" for more details ')
    end
else
    error('No subject(s) provided, type "help plot_2AFC" for more details ')
end

if isfield(params,'plotSession')
    flagPS = params.plotSession;    
else
    flagPS = true;
end

if flagPS && isfield(params,'sessionsdate')
    if iscell(params.sessionsdate)
        sessiondate = params.sessionsdate;
    else
        error('Sessions should be typed in cell array format, type "help plot_2AFC" for more details ')
    end
elseif flagPS
    if ~isfield(params,'sessionsdate')
        error('No sessions date provided, type "help plot_2AFC" for more details ')
    end
    
end

if isfield(params,'plotTraining')
    flagPT = params.plotTraining;
else
    flagPT = true;
end


%doing the real job
for idx = 1:length(names) %loop for subjects
    cd([basedir filesep names{idx}])
    auxDir = dir;
    
    if flagPS
        if strcmpi(sessiondate{1},'all') %strcmp but case insensitive
            for ses = idxDir  % loop for sessions within the subjects
                if (strfind(animalDir(idx).name,basename))
                    makePokePlot1([basedir filesep names{idx} filesep animalDir(idx).name],[basedir filesep names{idx}])
                    %we have to change this for the new session plot
                    %we can insert all the codes to generate plots inside
                    %single sessions.
                end
            end
            
        else %in case the user wants to plot specific dates.
            
            for ses = 1:length(sessiondate) % loop for sessions within the subjects
                for i = 1:length(auxDir)
                    if strfind(auxDir(i).name,[names{idx} '_' sessiondate{ses}])
                        folderOI = auxDir(i).name;
                    else
                        folderOI = [];
                    end
                end
                
                if ~isempty(folderOI)
                    makePokePlot1([basedir filesep names{idx} filesep folderOI],[basedir filesep names{idx}])
                else
                    warning(['The session' sessiondate{ses} 'is not available for the subject' names{idx} ', skipping session plot'])
                end
                
                %we have to change this for the new session plot
                %we can insert all the codes to generate plots inside
                %single sessions.
            end
            
        end
    end
    
    if flagPT
        trainingPlot([basedir filesep names{idx}]) %in this line and below we can add all the plots made across sessions
    end
end

