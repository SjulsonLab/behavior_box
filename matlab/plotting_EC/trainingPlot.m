%% extract all info

function trainingPlot(basedir)

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
        D(s) = extract_session_info(cd);
        
        pokes = extract_poke_info(cd);
        acc(s) = calc_accuracy_LS(pokes);
        %[~,fname] = fileparts(cd);
        
    end
    cd(basedir)
end



%% preparing data to plot

Lpokes = cellfun(@length,{L(:).Lpokes});
Rpokes = cellfun(@length,{L(:).Rpokes});
Ipokes = cellfun(@length,{L(:).Ipokes});
Lrewards = cellfun(@length,{L(:).Lpokes_correct});
Rrewards = cellfun(@length,{L(:).Rpokes_correct});
trialStarts = cellfun(@length,{L(:).trial_starts});
trialMissed = cellfun(@length,{L(:).trial_avails}) - trialStarts;
weight = [D(:).weight];
IrewardSize_nL = [D(:).IrewardSize_nL];

%collecting first poke in the trial
for i = 1:length(L)
    intervals = [L(i).trial_starts; L(i).trial_stops];
    allpokes = [L(i).Lpokes L(i).Rpokes];
    for it = 1:size(intervals,2)
        temp = Restrict(allpokes,intervals(:,it)'); %getting the latency to first poke in the trial
        if ~isempty(temp)
            sidePoke(i).first_sidePoke_latenc(it) = temp(1);
        else
            sidePoke(i).first_sidePoke_latenc(it) = nan;
        end
    end
end

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

%% first plot- correct reward

f1= figure;
f1.InnerPosition = [291 256 1959 942]; % these just set the window size so it's bigger for the PNG
f1.OuterPosition = [283 248 1975 1035];

day_helper = doy-doy(1);


subplot(5,1,1);hold on
plot(day_helper,Lrewards,'-db','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(day_helper,Rrewards,'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(day_helper,Lrewards+Rrewards,'-dg','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(day_helper,trialStarts,'-dk','linewidth',2,'markerfacecolor',[0 0 0],'markersize',3)
plot(day_helper,trialMissed,'-+','color',[0.8 0.8 0.8],'linewidth',2,'markerfacecolor',[0 0 0],'markersize',5)
xticks(day_helper)
xlabel('Sessions')
ylabel('# of rewards')
figTitle = ['Subject: ' basename ' - last  session:  ' D(end).date];
title(figTitle,'fontsize',16)

%preparing training phase plot

trainingPhase = [D(:).trainingPhase];
x = day_helper; % 1:length(trainingPhase);%starting from a minus# so the shades would cover from the first day
auxShade = find(diff(trainingPhase))+1;

for i = 1:length(auxShade)
    x = [x(1:auxShade(i)-1) x(auxShade(i))-0.001 x(auxShade(i):end)];
    trainingPhase = [trainingPhase(1:auxShade(i)-1) trainingPhase(auxShade(i)-1) trainingPhase(auxShade(i):end)];
end

subplot(5,1,1)
yyaxis right
area(x,trainingPhase,'facecolor','k','edgealpha',0,'facealpha',0.1);
ylabel('training phase')
legend('L rewards','R rewards','Total rewards','Trials start','Trials missed','Training phase','location','northwest')
xticks(day_helper)
xlim([day_helper(1) day_helper(end)])
% xticks(1:length(Lpokes))
%xticklabels(auxTicks);
% yticks([0 unique([ses(:).trainingPhase])])
set(gca,'fontsize',12)






%second plot - latency to poke on either left or right after initpoke
subplot(5,1,2)
latenciesL = [];
id_LatencL = [];
latenciesR = [];
id_LatencR = [];
init_Latenc = [];
id_init_Latenc = [];

latencies1stSide = [];
id_Latenc1stSide = [];
for idx = 1:length(L)
    tempL = [L(idx).Lreward_pokes_latencies]/1000;%storing latencies for left side poke in seconds
    tempR = [L(idx).Rreward_pokes_latencies]/1000;
    temp2 = [L(idx).trial_start_latencies]/1000;%storing latencies in seconds
    tempS = [sidePoke(idx).first_sidePoke_latenc]/1e6; %this still in arduino units (microsseconds)
    %     med_latenciesL(idx) = median(temp);
    latencies1stSide = [latencies1stSide tempS];
    id_Latenc1stSide = [id_Latenc1stSide ones(size(tempS))*day_helper(idx)];
    
    latenciesL = [latenciesL tempL];
    id_LatencL = [id_LatencL ones(size(tempL))*day_helper(idx)];
    
    latenciesR = [latenciesR tempR];
    id_LatencR = [id_LatencR ones(size(tempR))*day_helper(idx)];
    %     med_init_latencies(idx) = median(temp2);
    init_Latenc = [init_Latenc temp2];
    id_init_Latenc = [id_init_Latenc ones(size(temp2))*day_helper(idx)];
end

temp = unique(id_LatencL);
aux = temp(1):temp(end);
missing = aux(~ismember(aux,temp));

latencies1stSide = [latencies1stSide nan(size(missing))];
id_Latenc1stSide = [id_Latenc1stSide missing];


latenciesL = [latenciesL nan(size(missing))];
id_LatencL = [id_LatencL missing];

latenciesR = [latenciesR nan(size(missing))];
id_LatencR = [id_LatencR missing];


init_Latenc = [init_Latenc nan(size(missing))];
id_init_Latenc = [id_init_Latenc missing];


boxplot(latenciesL,id_LatencL,'PlotStyle','compact','positions',[unique(id_init_Latenc)])
hold on
% plot(day_helper+1,med_latencies,'-b','linewidth',2)

boxplot(latenciesR,id_LatencR,'colors','r','PlotStyle','compact','positions',[unique(id_init_Latenc)]+0.05)
boxplot(init_Latenc,id_init_Latenc,'colors','g','PlotStyle','compact','positions',[unique(id_init_Latenc)+0.10])
boxplot(latencies1stSide,id_Latenc1stSide,'colors','k','PlotStyle','compact','positions',[unique(id_init_Latenc)+0.15])
% plot(day_helper+1.05,med_init_latencies,'-r','linewidth',2)
xlabel('\color{blue}Blue: latency to left poke \color{black}| \color{red}Red: latency to poke right \color{black}| \color{green}Green: latency to init poke \color{black}| Black:Latency to first side poke' )
ylabel('Latency to poke (s)')
temp = [init_Latenc, latenciesL, latenciesR, latencies1stSide];
ylim([min(temp) max(temp)])

xlim([aux(1)-0.01 aux(end)+0.2])
set(gca,'fontsize',12)








%third plot- % accuracy
subplot(5,1,3);hold on
yyaxis left
plot(day_helper,[acc.all],'-dg','linewidth',2,'markerfacecolor',[0 0 1],'markersize',3)
plot(day_helper,[acc.left],'-db','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
plot(day_helper,[acc.right],'-dr','linewidth',2,'markerfacecolor',[1 0 0],'markersize',3)
ylabel('% accuracy')

dark_green = [0 145 26]/255;dark_blue = [0 80 193]/255; dark_red = [193 0 0]/255;
yyaxis right
plot(day_helper,[acc.all_pval],'-d','color',dark_green,'linewidth',2,'markerfacecolor',dark_green,'markersize',3)
plot(day_helper,[acc.left_pval],'-d','color',dark_blue,'linewidth',2,'markerfacecolor',dark_blue,'markersize',3)
plot(day_helper,[acc.right_pval],'-d','color',dark_red,'linewidth',2,'markerfacecolor',dark_red,'markersize',3)
ylabel('p-value')
ylim([0 0.10])
xticks(day_helper)
xlim([day_helper(1) day_helper(end)])
legend('All','Left','Right','All _p_v_a_l_u_e','L _p_v_a_l_u_e','R _p_v_a_l_u_e','location','southwest')

set(gca,'fontsize',12)








%fourth plot - weight and water consumption
subplot(5,1,4);hold on

left_color = [255 149 79]/255;
right_color = [117 176 255]/255;
% set(f1,'defaultAxesColorOrder',[left_color; right_color]);

yyaxis left

RewardSizes = {L.Ireward_size;L.Lreward_size;L.Rreward_size};
aux_rewardSize = cellfun(@(x) sum(x,2),RewardSizes,'UniformOutput',false);
temp = find(cellfun(@(x) isempty(x),aux_rewardSize));
for i = 1:length(temp)
    aux_rewardSize{temp(i)} = 0;
end
reward_size = cell2mat(aux_rewardSize);


plot(day_helper,reward_size(1,:)/1000,'-d','color',[97 211 127]/255,'linewidth',2,'markerfacecolor',[97 211 127]/255,'markersize',8)
plot(day_helper,reward_size(2,:)/1000,'-d','color',[97 204 211]/255,'linewidth',2,'markerfacecolor',[97 204 211]/255,'markersize',8)
plot(day_helper,reward_size(3,:)/1000,'-d','color',[211 101 97]/255,'linewidth',2,'markerfacecolor',[211 101 97]/255,'markersize',8)
ylabel('Water consumed ( \mu L)')

yyaxis right
plot(day_helper,[D.weight],'-d','color',left_color,'linewidth',2,'markerfacecolor',left_color,'markersize',10)
legend('Init consump','Left consump','Right consump','Weight')
ylabel('mouse weight (g)')
xticks(day_helper)
xlim([day_helper(1) day_helper(end)])
xlabel('Sessions')
set(gca,'fontsize',12)


% fifth subplot - parameter from the task: time limit to side poke, to init
% poke, punishment time if not initiated, reward sizes and probability of
% the init poke
subplot(5,1,5)
title('session parameters')
yyaxis left
hold on
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.initiation_time_limit],':dm','linewidth',2,'markerfacecolor','m')
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.sidePoke_time_limit],':dc','linewidth',2,'markerfacecolor','c')
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.punish_time],':d','color',[0.4660 0.6740 0.1880],'linewidth',2,'markerfacecolor',[0.4660 0.6740 0.1880])
ylabel('time (s)')
%plot time if initiated and etc
yyaxis right
hold on
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.IrewardSize_nL],':dg','linewidth',2,'markerfacecolor','g')
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.LrewardSize_nL],':db','linewidth',2,'markerfacecolor','b')
plot(day_helper+(randn(1,size(day_helper,2))/50),[D.RrewardSize_nL],':dr','linewidth',2,'markerfacecolor','r')
ylabel('reward size (uL)')
xlim([day_helper(1)-0.07 day_helper(end)+0.07])
legend('init time limit','side poke time limit','punishment time','I reward size','L reward size','R reward size','location','best')
%plot reward sizes

%% saving plot to disk

%identifying figures folder in animal
flagdir = 1;
for i = idxDir
    if strcmp(animalDir(i).name,'figures');flagdir = 0;end
end
if flagdir;mkdir('figures');end

cd('figures');
savefig(f1, [basename '_training_plot1.fig'], 'compact');
print([basename '_training_plot1.png'], '-dpng');

close(f1);
cd(basedir)

disp(['Finished training plot for ', basename]);