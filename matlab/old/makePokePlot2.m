% function makePokePlot2(basedir, startdir)

% function makePokePlot2(basedir, startdir)
%
% Makes a plot of when nosepokes and rewards occurred for a given mouse
% behavior box session.
%
% basedir is the name of the directory of the session to plot.
% startdir is the directory that basedir is in. If omitted, defaults
% to the current directory.
%
% Luke Sjulson, 2018-12-20
%
% update by Eliezyer de Oliveira, on 2019-02-15



% for testing
clear all
close all
% basedir = 'D1R102Male600_181205_145056';
% basedir = 'D1R96Male246_181203_154542';
% startdir = 'C:\Users\lukes\Desktop\temp';
nargin = 1;
visibleON = 1;

%cd('G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior\ADR45M591\ADR45M591_20190328_152930');
basedir = pwd;


%% start of function
% tic %added by EFO to track time spent on each period
if nargin<2
	startdir = pwd;
	basedir = pwd;
end

cd(startdir);
cd(basedir);
[~, basename] = fileparts(pwd);

try
	load ./mouse_info.mat %load ./mouseStr.mat
	load ./session_info.mat %load ./sessionStr.mat
catch
	warning(['Unable to find .mat files in ' basedir]);
	return
end


% extract info about nosepokes
%pokes = extract_poke_info(basedir,basename);
pokes = extract_poke_info(basedir);



% 
% % extract times of nosepoke entries
% Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
% Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
% Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
% Lrewards = getEventTimes('leftReward_nL', [basename '.txt']);
% Rrewards = getEventTimes('rightReward_nL', [basename '.txt']);
% trialAvailable = getEventTimes('TrialAvailable', [basename '.txt']);
% if session_info.trainingPhase > 1
% 	trialStart = getEventTimes('TrialStarted', [basename '.txt']);
% end
% % disp('Done with loading file')%added by EFO
% % toc%added by EFO
% 
% 
% % loop over trials, figure out which pokes were correct vs incorrect
% 











%% plotting and saving plot to disk

% % if session_info.trainingPhase > 1
% %     f1 = PokePlot(session_info,trialAvailable,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards,0,trialStart);
% % else
% %     f1 = PokePlot(session_info,trialAvailable,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards,0);
% % end
% % savefig(f1, [basename '_pokeplot1.fig'], 'compact');
% 
% cd(startdir);
% % %% the code below is not working to me, idk why, so I made an old style
% % %% one
% % if exist('figures', 'dir') ~= 7 %it's identifying the folder when it doesn't exist
% % 	mkdir('figures');
% % end
% auxDir = dir;
% aux = find([auxDir.isdir]);
% 
% flagdir = 1;
% for i = aux
% 	if strcmp(auxDir(i).name,'figures');flagdir = 0;end
% end
% if flagdir;mkdir('figures');end
% 
% cd('figures');
% close all
% 
% if session_info.trainingPhase > 1
% 	f1 = PokePlot(session_info,trialAvailable,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards,1,trialStart, basedir);
% else
% 	f1 = PokePlot(session_info,trialAvailable,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards,1);
% end
% print([basename '_pokeplot1.png'], '-dpng');
% 
% close(f1);
% cd ..
% 
% disp(['Finished pokeplot1 for ', basename]);
% 
% 
% 
% 
% 
% 
% function [f1] = PokePlot(sessionStr,trialAvailable,Lpokes,Rpokes,Ipokes,basename,Lrewards,Rrewards,flagDS,trialStart, basedir)


%% extracting poke info from log file
%pokes = extract_poke_info(pwd, basename);



%% making the plot
close all
histbin = 100; % in ms
histvec = (0:histbin:pokes.trial_avails(end)+120);
hist_scale = 60000;

% norm = 'count';


f1 = figure;
if ~exist('visibleON') && flagDS == 0
	f1.Visible = 'off';
end

f1.InnerPosition = [291 256 1959 942]; % these just set the window size so it's bigger for the PNG
f1.OuterPosition = [283 248 1975 1035];

% trial starts
Thist = histc(pokes.trial_avails, histvec);
Tshade = cumsum(Thist);
Tshade(mod(Tshade, 2)==1) = 9999;
Tshade(mod(Tshade, 2)==0) = 0;

Tshade2 = Tshade * -1;



%% first subplot
a(1) = subplot(3,4,1:3);

% plot pokes, both correct and incorrect
Lhist_correct = histc(pokes.Lpokes_correct, histvec);
Lhist_incorrect = histc(pokes.Lpokes_incorrect, histvec);
Rhist_correct = histc(pokes.Rpokes_correct, histvec);
Rhist_incorrect = histc(pokes.Rpokes_incorrect, histvec);
Ihist_correct = histc(pokes.Ipokes_correct, histvec);
Ihist_incorrect = histc(pokes.Ipokes_incorrect, histvec);

% fill with zeros if they're empty
if isempty(Lhist_correct)
	Lhist_correct = zeros(size(histvec));
end
if isempty(Lhist_incorrect)
	Lhist_incorrect = zeros(size(histvec));
end
if isempty(Rhist_correct)
	Rhist_correct = zeros(size(histvec));
end
if isempty(Rhist_incorrect)
	Rhist_incorrect = zeros(size(histvec));
end
if isempty(Ihist_correct)
	Ihist_correct = zeros(size(histvec));
end
if isempty(Ihist_incorrect)
	Ihist_incorrect = zeros(size(histvec));
end

% plot L pokes
h1 = plot(histvec/hist_scale, Lhist_correct, 'b'); hold on
h1.Color(4) = 0.5; % setting alpha (transparency)
h2 = plot(histvec/hist_scale, -1*Lhist_incorrect, 'b');
h2.Color(4) = 0.5;

% plot R pokes
h1 = plot(histvec/hist_scale, Rhist_correct, 'r'); hold on
h1.Color(4) = 0.5; % setting alpha (transparency)
h2 = plot(histvec/hist_scale, -1*Rhist_incorrect, 'r');
h2.Color(4) = 0.5;

% plot I pokes (init)
h1 = plot(histvec/hist_scale, Ihist_correct, 'g'); hold on
h1.Color(4) = 0.5; % setting alpha (transparency)
h2 = plot(histvec/hist_scale, -1*Ihist_incorrect, 'g');
h2.Color(4) = 0.5;


% x1 = xlabel('Time (seconds)');

t1 = title([basename ', trainingPhase ' num2str(session_info.trainingPhase)]);
t1.Interpreter = 'none';
a(1).XTickLabel = [];
ylabel('Nosepokes');
a(1).XLim = a(1).XLim; % so limits don't change when overlaying the trial boundaries
a(1).YLim = a(1).YLim;

% plot trial background

b1 = area(histvec/hist_scale, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';

b2 = area(histvec/hist_scale, Tshade2);
b2.EdgeAlpha = 0;
b2.FaceAlpha = 0.1;
b2.FaceColor = 'k';
% legend('L pokes', 'R pokes', 'I pokes');


%% second subplot

% reward histograms
LrewardHist = histc(pokes.Lreward_pokes, histvec);
if isempty(LrewardHist)
	LrewardHist = zeros(size(histvec));
end
RrewardHist = histc(pokes.Rreward_pokes, histvec);
if isempty(RrewardHist)
	RrewardHist = zeros(size(histvec));
end


% plot trial availability and starts
a(2) = subplot(3,4,5:7);
Thist = histc(pokes.trial_avails, histvec);
h4 = plot(histvec/hist_scale, cumsum(Thist), 'k'); hold on

Thist = histc(pokes.trial_starts, histvec);
if isempty(Thist)
	Thist = zeros(size(histvec));
end
h4 = plot(histvec/hist_scale, cumsum(Thist), 'Color', [0.5 0.5 0.5]);

% plot rewards
% LrewardHist = histc(Lrewards, histvec);

h5 = plot(histvec/hist_scale, cumsum(LrewardHist), 'b');
h5.Color(4) = 0.5;

% RrewardHist = histc(Rrewards, histvec);
h6 = plot(histvec/hist_scale, cumsum(RrewardHist), 'r');
h6.Color(4) = 0.5;


h7 = plot(histvec/hist_scale, cumsum(LrewardHist(:) + RrewardHist(:)), 'g');

%plot trial start if variable is available
if exist('trialStart','var')
	Tstart = histc(trialStart, histvec);
	h8 = plot(histvec/hist_scale, cumsum(Tstart),'color',[0.5 0.5 0.5]);
end


y1 = ylabel('Number of trials/rewards');


% plot trial background
a(2).XLim = a(2).XLim; % so limits don't change when overlaying the trial boundaries
a(2).YLim = a(2).YLim;
b1 = area(histvec/hist_scale, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';
a(2).XTickLabel = [];

L3 = legend('Trial Available', 'Trial Started', 'L rewards', 'R rewards', 'all rewards');
L3.Location = 'northwest';


%% third subplot: bars indicating poke latencies
a(3) = subplot(3, 4, 9:11);
barwidth = 10;

I_lat = zeros(size(histvec));
R_lat = zeros(size(histvec));
L_lat = zeros(size(histvec));

for idx = 1:length(pokes.trial_starts)
	[~, minidx] = min(abs(histvec - pokes.trial_starts(idx)));
	I_lat(minidx) = pokes.trial_start_latencies(idx)/1000;
end

for idx = 1:length(pokes.Lreward_pokes)
	[~, minidx] = min(abs(histvec - pokes.Lreward_pokes(idx)));
	L_lat(minidx) = pokes.Lreward_pokes_latencies(idx)/1000;
end

for idx = 1:length(pokes.Rreward_pokes)
	[~, minidx] = min(abs(histvec - pokes.Rreward_pokes(idx)));
	R_lat(minidx) = pokes.Rreward_pokes_latencies(idx)/1000;
end



p1 = plot(histvec/hist_scale, I_lat, 'g'); hold on
p2 = plot(histvec/hist_scale, L_lat, 'b');
p3 = plot(histvec/hist_scale, R_lat, 'r');


% 
% 
% max_time = max([pokes.Lreward_pokes pokes.Rreward_pokes pokes.trial_starts]);
% max_time = max_time + 1000;
% 
% p1 = bar([0 pokes.Lreward_pokes max_time]/ hist_scale, [0 pokes.Lreward_pokes_latencies 0] / 1000, barwidth, 'b'); hold on
% p2 = bar([0 pokes.Rreward_pokes max_time]/ hist_scale, [0 pokes.Rreward_pokes_latencies 0] / 1000, barwidth, 'r');
% p3 = bar([0 pokes.trial_starts max_time] / hist_scale, [0 pokes.trial_start_latencies 0] / 1000, barwidth, 'g');
% 
% p1.EdgeAlpha = 0;
% p2.EdgeAlpha = 0;
% p3.EdgeAlpha = 0;
% a(3).XLim = [min(histvec/hist_scale) max(histvec/hist_scale)];

% plot trial background
a(3).YLim = a(3).YLim;
b1 = area(histvec/hist_scale, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';
x1 = xlabel('Minutes');
y1 = ylabel('Poke latency (s)');

%% link axes etc
ZoomHandle = zoom(f1);
set(ZoomHandle, 'Motion', 'horizontal')
linkaxes(a, 'x');


%% fourth subplot
s1 = subplot(3, 4, 4);
binwidth = 0.1;

% making histogram of init poke latencies
Ntrials_avail = length(pokes.trial_avails);
Ihistvec = 0:binwidth:max(pokes.trial_start_latencies);
Ihist = histc(pokes.trial_start_latencies, Ihistvec);

if isempty(Ihistvec)
	Ihistvec = zeros(size(histvec));
end

if isempty(Ihist)
	Ihist = zeros(size(histvec));
end

Ihist(end) = Ihist(end) + Ntrials_avail - sum(Ihist);

N_left_trials_started = sum(pokes.trialLR_types==1 | pokes.trialLR_types==2);
N_right_trials_started = sum(pokes.trialLR_types==3 | pokes.trialLR_types==4);
LRhistvec = 0:binwidth:max([pokes.Lreward_pokes_latencies pokes.Rreward_pokes_latencies]);
Lhist = histc(pokes.Lreward_pokes_latencies, LRhistvec);
Rhist = histc(pokes.Rreward_pokes_latencies, LRhistvec);

if isempty(LRhistvec)
	LRhistvec = zeros(size(histvec));
end

if isempty(Lhist)
	Lhist = zeros(size(LRhistvec));
end

if isempty(Rhist)
	Rhist = zeros(size(LRhistvec));
end

Lhist(end) = Lhist(end) + N_left_trials_started - sum(Lhist);
Rhist(end) = Rhist(end) + N_right_trials_started - sum(Rhist);

% h1 = histogram(pokes.trial_start_latencies/1000, 'BinWidth', binwidth, 'Normalization', 'cdf', 'DisplayStyle', 'stairs', 'EdgeColor', 'g');
h1 = plot(Ihistvec/1000, cumsum(Ihist)./sum(Ihist), 'g');
t1 = title('Init poke latency distr.');
x1 = xlabel('Time (seconds)');

s2 = subplot(3, 4, 8);
h1 = plot(LRhistvec/1000, cumsum(Lhist)./sum(Lhist), 'b'); hold on
h1 = plot(LRhistvec/1000, cumsum(Rhist)./sum(Rhist), 'r');

% h1 = histogram(pokes.Lreward_pokes_latencies/1000, 'BinWidth', binwidth, 'Normalization', 'cdf', 'DisplayStyle', 'stairs', 'EdgeColor', 'b'); hold on
% h2 = histogram(pokes.Rreward_pokes_latencies/1000, 'BinWidth', binwidth, 'Normalization', 'cdf', 'DisplayStyle', 'stairs', 'EdgeColor', 'r');
t2 = title('Right, Left poke latency');
x1 = xlabel('Time (seconds)');




