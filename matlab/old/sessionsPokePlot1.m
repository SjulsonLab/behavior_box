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
% Edited by Edith, 2019-03-19
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

%         try
            if isfile('sessionStr.mat')
                load ./sessionStr.mat
                session_info = sessionStr;
                flag = true;
            elseif isfile('session_info.mat')
                load ./session_info.mat
                flag = true;
            else
                flag = false;
            end
%         catch
%             warning(['Unable to find .mat files in ' basedir]);
%             return
%         end

        
        % extract times of nosepoke entries
        if flag
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
        end
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

for i =1:length(cellofDates) 
 yyyy(i) = str2num(cellofDates{i}(1:4)); 
 mm(i) = str2num(cellofDates{i}(5:6)); 
 dd(i) = str2num(cellofDates{i}(7:8)); 
end

% transfer dates into days of year 
auxd = datetime(yyyy,mm,dd); 
doy = day(auxd,'dayofyear');
for i = 1:length(doy)
    doy2{i,1} = num2str(doy(i)-doy(1));
end
auxTicks = doy2;

%first subplot is number of pokes per session, shaded area is the training
%phase
%second subplot is number of rewards per side per session, shaded area is
%the trainingphase

f1= figure;
f1.InnerPosition = [291 256 1959 942]; % these just set the window size so it's bigger for the PNG
f1.OuterPosition = [283 248 1975 1035];

d1 = idxDir
d2 = doy-doy(1)
[commonFrames,ia,ib] = intersect(d1, d2);


subplot(3,1,1);hold on
plot(doy-doy(1),Lrewards,'-db','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(doy-doy(1),Rrewards,'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(doy-doy(1),Lrewards+Rrewards,'-dg','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(doy-doy(1),trialStarts,'-dk','linewidth',2,'markerfacecolor',[0 0 0],'markersize',3)
xticks(doy-doy(1))
xlabel('Sessions')
ylabel('# of rewards')


subplot(3,1,2);hold on
title(basename,'fontsize',16)

plot(doy-doy(1),Lpokes,'-db','linewidth',2,'markerfacecolor',[0 0 1],'markersize',5)
plot(doy-doy(1),Rpokes,'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',5)
plot(doy-doy(1),Ipokes,'-dg','linewidth',2,'markerfacecolor',[0 1 0],'markersize',5)
legend('L pokes','R pokes','I pokes','location','northwest')
xticks(doy-doy(1)) %we have to insert this every subplot
%xticklabels(auxTicks,'xticklabelmode','manual'); %this we have to remove from every subplot

xlabel('Sessions')
ylabel('# of pokes')
set(gca,'fontsize',12)
% xticks(1:length(Lpokes))


%subplot(3,1,3);hold on
%plot(doy-doy(1),weight,'linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
%xticks(doy-doy(1))
%xticklabels(auxTicks);
% plot(date,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
%xlabel('Sessions');
%ylabel('weights');


subplot(3,1,3);hold on
yyaxis right
%xticklabels(auxTicks);
plot(doy-doy(1),IrewardSize_nL,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
% plot(date,'linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
xticks(doy-doy(1))
xlabel('Sessions')
ylabel('Init reward size')


%preparing training phase plot

%to cover the shade to the last trial (Edith) 
xxx = doy-doy(1) 
xxx(end)-xxx(1) %total length of x-axis %25
%[xxx(end)-xxx(1)]-length(trainingPhase) %additional days not covered with shades %3

trainingPhase = [ses(:).trainingPhase];
x = doy-doy(1); % 1:length(trainingPhase);%starting from a minus# so the shades would cover from the first day  
auxShade = find(diff(trainingPhase))+1;

for i = 1:length(auxShade)
    x = [x(1:auxShade(i)-1) x(auxShade(i))-0.001 x(auxShade(i):end)];
    trainingPhase = [trainingPhase(1:auxShade(i)-1) trainingPhase(auxShade(i)-1) trainingPhase(auxShade(i):end)];
end

subplot(3,1,1)
yyaxis right
area(x,trainingPhase,'facecolor','k','edgealpha',0,'facealpha',0.1);
ylabel('training phase')
legend('L rewards','R rewards','Total rewards','Trials start','Training phase','location','northwest')

xticks(doy-doy(1))
% xticks(1:length(Lpokes))
%xticklabels(auxTicks);
% yticks([0 unique([ses(:).trainingPhase])])

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