function sessionsPokePlot1(basedir)

% function sessionsPokePlot1(basedir, startdir)
%
% Makes a plot averaging nosepokes and rewards of each session for a given
% mice. Your folder should be structured in each animal having its own
% folder in which sessions are recorded in single folders
%
% basedir is the name of the directory of the session to plot.
%
% Eliezyer F. de Oliveira, 2019-01-14
%

%TODO:
% [] CHANGE TRIALS START TO TRIALS INITIATED IN PHASE 2

%% start of function
if nargin<1
    basedir = pwd;
end

cd(basedir);
[~, basename] = fileparts(basedir);
animalDir = dir;

idxDir = find([animalDir.isdir]);

s = 0;
for idx = idxDir
    if (strfind(animalDir(idx).name,basename))
        cd(animalDir(idx).name)
        %processing and collecting data
        try
            if isfile('sessionStr.mat')
                load ./sessionStr.mat
                session_info = sessionStr;
            else
                load ./session_info.mat
            end
        catch
            warning(['Unable to find .mat files in ' basedir]);
            return
        end
        
        % extract times of nosepoke entries
        s = s+1;
        [~,fname] = fileparts(cd);
        ses(s).Lpokes = getEventTimes('leftPokeEntry', [fname '.txt']);
        ses(s).Rpokes = getEventTimes('rightPokeEntry', [fname '.txt']);
        ses(s).Ipokes = getEventTimes('initPokeEntry', [fname '.txt']);
        ses(s).Lrewards = getEventTimes('leftReward_nL', [fname '.txt']);
        ses(s).Rrewards = getEventTimes('rightReward_nL', [fname '.txt']);
        ses(s).trialStarts = getEventTimes('TrialAvailable', [fname '.txt']);
        ses(s).trainingPhase = session_info.trainingPhase;
        ses(s).weight = session_info.weight;
        ses(s).IrewardSize_nL = session_info.IrewardSize_nL;
        ses(s).date = session_info.date;
        cd(basedir)
       
    end
end


%% preparing plot

Lpokes = cellfun(@length,{ses(:).Lpokes});
Rpokes = cellfun(@length,{ses(:).Rpokes});
Ipokes = cellfun(@length,{ses(:).Ipokes});
Lrewards = cellfun(@length,{ses(:).Lrewards});
Rrewards = cellfun(@length,{ses(:).Rrewards});
trialStarts = cellfun(@length,{ses(:).trialStarts});
weight = [ses(:).weight];
IrewardSize_nL = [ses(:).IrewardSize_nL];
cellofDates = {ses(:).date};
days = cellfun(@str2num,cellofDates);


%first subplot is number of pokes per session, shaded area is the training
%phase
%second subplot is number of rewards per side per session, shaded area is
%the trainingphase

f1 = figure;
f1.InnerPosition = [291 256 1959 942]; % these just set the window size so it's bigger for the PNG
f1.OuterPosition = [283 248 1975 1035];

subplot(3,1,1);hold on
title(basename,'fontsize',16)
plot(Lpokes,'-db','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(Rpokes,'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(Ipokes,'-dg','linewidth',2,'markerfacecolor',[0 1 0],'markersize',3)
legend('L pokes','R pokes','I pokes','location','northwest')
xticks([days-days(1)]);
xlabel('Sessions')
ylabel('# of pokes')
set(gca,'fontsize',12)
% xticks(1:length(Lpokes))

subplot(3,1,2);hold on
plot(Lrewards,'-db','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(Rrewards,'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(Lrewards+Rrewards,'-dg','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(trialStarts,'-dk','linewidth',2,'markerfacecolor',[0 0 0],'markersize',3)
xticks([days-days(1)]);
xlabel('Sessions')
ylabel('# of rewards')

subplot(3,1,3);hold on
plot(weight,'linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
xticks([days-days(1)]);
% plot(date,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
xlabel('Sessions');
ylabel('weights');
title ('Weights');

subplot(3,1,3);hold on
yyaxis right
xticks([days-days(1)]);
plot(IrewardSize_nL,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
% plot(date,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
xlabel('Sessions')
ylabel('Init reward size')

%preparing training phase plot

trainingPhase = [ses(:).trainingPhase];
x = 1:length(trainingPhase);
auxShade = find(diff(trainingPhase))+1;

for i = 1:length(auxShade)
    x = [x(1:auxShade(i)-1) x(auxShade(i))-0.001 x(auxShade(i):end)];
    trainingPhase = [trainingPhase(1:auxShade(i)-1) trainingPhase(auxShade(i)-1) trainingPhase(auxShade(i):end)];
end

subplot(3,1,2)
yyaxis right
area(x,trainingPhase,'facecolor','k','edgealpha',0,'facealpha',0.1);
ylabel('training phase')
legend('L rewards','R rewards','Total rewards','Trials start','Training phase','location','northwest')
xticks(1:length(Lpokes))
yticks([0 unique([ses(:).trainingPhase])])
set(gca,'fontsize',12)

%% saving plot to disk

%identifying figures folder in animal
flagdir = 1;
for i = idxDir
    if strcmp(animalDir(i).name,'figures');flagdir = 0;end
end
if flagdir;mkdir('figures');end

cd('figures');
savefig(f1, [basename '_sessions_plot1.fig'], 'compact');
print([basename '_sessions_plot1.png'], '-dpng');

close(f1);
cd(basedir)

disp(['Finished session plot for ', basename]);
end