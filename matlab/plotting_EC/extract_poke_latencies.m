




% function L = extract_poke_latencies(basedir, basename)


% % for testing
clear all
basename = 'ADR45M591_20190328_152930';
basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior\ADR45M591\ADR45M591_20190328_152930';


cd(basedir);

% extract times of nosepoke entries
L.Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
L.Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
L.Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
L.Lreward_pokes = getEventTimes('leftRewardCollected', [basename '.txt']);
L.Rreward_pokes = getEventTimes('rightRewardCollected', [basename '.txt']);
% extract times of trial starts
L.trial_avails = getEventTimes('TrialAvailable', [basename '.txt']);
L.trial_starts = getEventTimes('TrialStarted', [basename '.txt']);

L.trialLR_types = getEventTimes('trialLRtype', [basename '.txt']);

% miss_Before_Start = getEventTimes('TrialMissedBeforeInit_ms', [basename '.txt']);
% missAfterStart = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);



%% extract latencies for each init poke that resulted in a trial start
L.trial_start_latencies = zeros(size(L.trial_starts));
for idx = 1:length(L.trial_starts)
	tempvec = L.trial_starts(idx) - L.trial_avails;
	tempvec(tempvec<0) = Inf;
	L.trial_start_latencies(idx) = min(tempvec); % finding the closest trial_avail that preceded the trial start
end

%% extract latencies for each left and right reward collection
L.Lreward_pokes_latencies = zeros(size(L.Lreward_pokes));
for idx = 1:length(L.Lreward_pokes_latencies)
	tempvec = L.Lreward_pokes(idx) - L.trial_starts;
	tempvec(tempvec<0) = Inf;
	L.Lreward_pokes_latencies(idx) = min(tempvec); % finding the closest trial_start that preceded the L reward collection
end

L.Rreward_pokes_latencies = zeros(size(L.Rreward_pokes));
for idx = 1:length(L.Rreward_pokes_latencies)
	tempvec = L.Rreward_pokes(idx) - L.trial_starts;
	tempvec(tempvec<0) = Inf;
	L.Rreward_pokes_latencies(idx) = min(tempvec); % finding the closest trial_start that preceded the L reward collection
end

L.trial_starts = L.trial_starts;
L.trial_start_latencies = L.trial_start_latencies;


%% figure out which pokes are correct vs. incorrect

