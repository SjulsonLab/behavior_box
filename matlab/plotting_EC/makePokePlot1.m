function makePokePlot1(basedir, startdir)

% function makePokePlot1(basedir, startdir)
%
% Makes a plot of when nosepokes and rewards occurred for a given mouse
% behavior box session.
%
% basedir is the name of the directory of the session to plot.
% startdir is the directory that basedir is in. If omitted, defaults
% to the current directory.
%
% Luke Sjulson, 2018-12-20



% % for testing
% clear all
% close all
% basedir = 'D1R102Male600_181205_145056';
% basedir = 'D1R96Male246_181203_154542';
% startdir = 'C:\Users\lukes\Desktop\temp';
% nargin = 2;
% visibleON = 1;


%% start of function
if nargin<2
	startdir = pwd;
end

cd(startdir);
cd(basedir);
[~, basename] = fileparts(pwd);

try
	load ./mouseStr.mat
	load ./sessionStr.mat
catch
	warning(['Unable to find .mat files in ' basedir]);
	return
end

% extract times of nosepoke entries
Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
Lrewards = getEventTimes('leftReward_nL', [basename '.txt']);
Rrewards = getEventTimes('rightReward_nL', [basename '.txt']);

trialStarts = getEventTimes('TrialAvailable');


%% plotting
close all
histvec = 0:2:trialStarts(end)+120;
norm = 'count';


f1 = figure;
if ~exist('visibleON')
	f1.Visible = 'off';
end

f1.InnerPosition = [291 256 1959 942]; % these just set the window size so it's bigger for the PNG
f1.OuterPosition = [283 248 1975 1035];

% trial starts
Thist = histc(trialStarts, histvec);
Tshade = cumsum(Thist);
Tshade(mod(Tshade, 2)==1) = 9999;
Tshade(mod(Tshade, 2)==0) = 0;

%% first subplot
a(1) = subplot(3,1,1);

% plot L pokes
Lhist = histc(Lpokes, histvec);
if isempty(Lhist)
	Lhist = zeros(size(histvec));
end
h1 = plot(histvec, Lhist, 'b'); hold on
h1.Color(4) = 0.5; % setting alpha (transparency)

% plot R pokes
Rhist = histc(Rpokes, histvec);
if isempty(Rhist)
	Rhist = zeros(size(histvec));
end
h2 = plot(histvec, Rhist, 'r');
h2.Color(4) = 0.5; 

% plot I pokes
Ihist = histc(Ipokes, histvec);
if isempty(Ihist)
	Ihist = zeros(size(histvec));
end
h3 = plot(histvec, Ihist, 'g');
% x1 = xlabel('Time (seconds)');

t1 = title([basename ', trainingPhase ' num2str(sessionStr.trainingPhase)]);
t1.Interpreter = 'none';
a(1).XTickLabel = [];
ylabel('Nosepokes');
a(1).XLim = a(1).XLim; % so limits don't change when overlaying the trial boundaries
a(1).YLim = a(1).YLim;

% plot trial background
b1 = area(histvec, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';

legend('L pokes', 'R pokes', 'I pokes');

%% second subplot - rewards

% plot trial starts
a(2) = subplot(3,1,2);

% h4 = bar(histvec, Thist*2, 'k'); hold on % used to plot trial boundaries this way
% plot rewards
LrewardHist = histc(Lrewards, histvec);
if isempty(LrewardHist)
	LrewardHist = zeros(size(histvec));
end

h5 = plot(histvec, LrewardHist, 'b'); hold on
h5.Color(4) = 0.5;
% h5 = area(histvec, LrewardHist);
a(2).YLim = [-0.2 1.2];

RrewardHist = histc(Rrewards, histvec);
if isempty(RrewardHist)
	RrewardHist = zeros(size(histvec));
end
h6 = plot(histvec, RrewardHist, 'r');
h6.Color(4) = 0.5;


a(2).XTickLabel = [];
a(2).YTick = [];
% x1 = xlabel('Time (seconds)');

% plot trial background
b1 = area(histvec, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';
% legend('Trial Starts', 'L rewards', 'R rewards');
legend('L rewards', 'R rewards');


%% third subplot
% plot trial starts
a(3) = subplot(3,1,3);

Thist = histc(trialStarts, histvec);
h4 = plot(histvec, cumsum(Thist), 'k'); hold on
% plot rewards
% LrewardHist = histc(Lrewards, histvec);
h5 = plot(histvec, cumsum(LrewardHist), 'b');
h5.Color(4) = 0.5;

% RrewardHist = histc(Rrewards, histvec);
h6 = plot(histvec, cumsum(RrewardHist), 'r');
h6.Color(4) = 0.5;

h7 = plot(histvec, cumsum(LrewardHist(:) + RrewardHist(:)), 'g');


x1 = xlabel('Time (seconds)');
y1 = ylabel('Number of trials/rewards');

a(3).XLim = a(3).XLim; % so limits don't change when overlaying the trial boundaries
a(3).YLim = a(3).YLim;


% plot trial background
b1 = area(histvec, Tshade);
b1.EdgeAlpha = 0;
b1.FaceAlpha = 0.1;
b1.FaceColor = 'k';

L3 = legend('Trial Starts', 'L rewards', 'R rewards', 'all rewards');
L3.Location = 'northwest';

ZoomHandle = zoom(f1);
set(ZoomHandle, 'Motion', 'horizontal')
linkaxes(a, 'x');

%% saving plot to disk
savefig(f1, [basename '_pokeplot1.fig'], 'compact');
cd(startdir);
if exist('figures', 'dir') ~= 7
	mkdir('figures');
end
cd('figures');
print([basename '_pokeplot1.png'], '-dpng');
close(f1);


disp(['Finished pokeplot1 for ', basename]);







