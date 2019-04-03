%% extract all info 

function sessionsPokePlot1_practice(basedir)

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
        %if flag
        s = s+1;
        L(s) = extract_poke_info(cd);
        D(s) = date_weight_info(cd);
        %[~,fname] = fileparts(cd);
        
    end
      cd(basedir) 
end



%% preparing plot

Lpokes = cellfun(@length,{L(:).Lpokes});
Rpokes = cellfun(@length,{L(:).Rpokes});
Ipokes = cellfun(@length,{L(:).Ipokes});
Lrewards = cellfun(@length,{L(:).Lpokes_correct});
Rrewards = cellfun(@length,{L(:).Rpokes_correct});
trialStarts = cellfun(@length,{L(:).trial_starts});
weight = [D(:).weight];
IrewardSize_nL = [D(:).IrewardSize_nL];
cellofDates = {D(:).date};
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

%first plot- correct reward

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


%preparing training phase plot

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


%second plot
% for idx = 1:length(L)
%     latencies{idx} = [L(idx).Lreward_pokes_latencies L(idx).Rreward_pokes_latencies]/1000;
% end
boxplot([1:5],latencies')





%third plot
subplot(3,1,3);hold on




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