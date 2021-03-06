% function L = extract_poke_info(basedir, basename)

% This function returns a struct "L", which contains the times of each 
% nosepoke, whether each poke was correct or not, etc. It contains that 
% info for left, right, and init pokes. 
% 
% Luke Sjulson, 2019-03-29



function L = extract_poke_info(basedir)


% % % for testing
% clear all
 %basename = 'ADR45M591_20190328_152930';
 %basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior\ADR45M591\ADR45M591_20190328_152930';
 %basedir = pwd; 
 
cd(basedir);
[~,basename] = fileparts(pwd);


% extract times of nosepoke entries
L.Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
L.Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
L.Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
[L.Lreward_pokes, ~, L.Lreward_poke_trialnum] = getEventTimes('leftRewardCollected', [basename '.txt']);
[L.Rreward_pokes, ~, L.Rreward_poke_trialnum] = getEventTimes('rightRewardCollected', [basename '.txt']);
% extract times of trial starts
L.trial_avails = getEventTimes('TrialAvailable', [basename '.txt']);
[L.trial_starts, ~, L.trial_start_nums] = getEventTimes('TrialStarted', [basename '.txt']);
L.trial_stops = [];

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


%% figure out which pokes are correct vs. incorrect

[~, L.trialLR_types] = getEventTimes('trialLRtype', [basename '.txt']);
miss_before_start = getEventTimes('TrialMissedBeforeInit_ms', [basename '.txt']);
miss_after_start = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);
standby     = getEventTimes('Standby', [basename '.txt']);

all_stops = [miss_before_start, miss_after_start, standby];

left_incorrect = L.Lpokes;
right_incorrect = L.Rpokes;
left_correct = [];
right_correct = [];

for idx = 1:length(L.trial_starts)
	ntrial = L.trial_start_nums(idx);
% 	if idx==14
% 		warning('warning');
% 	end
	tempstart = L.trial_starts(idx);
	tempvec = all_stops - tempstart;
	tempvec(tempvec<=0) = Inf;
% 	tempstop = min(tempvec);
	[~, i] = min(tempvec);
	tempstop = all_stops(i);
	L.trial_stops(idx) = tempstop;
    
	if any(L.trialLR_types(ntrial) == [1 2 5 6]) % left pokes are correct
		left_correct = [left_correct, left_incorrect(left_incorrect >= tempstart & left_incorrect <= tempstop)];
		left_incorrect = left_incorrect(left_incorrect < tempstart | left_incorrect > tempstop);
	end
	
	if any(L.trialLR_types(ntrial) == [3 4 5 6]) % right pokes are correct
		right_correct = [right_correct, right_incorrect(right_incorrect >= tempstart & right_incorrect <= tempstop)];
		right_incorrect = right_incorrect(right_incorrect < tempstart | right_incorrect > tempstop);
	end
	
end

L.Lpokes_correct = sort(left_correct);
L.Lpokes_incorrect = sort(left_incorrect);
L.Rpokes_correct = sort(right_correct);
L.Rpokes_incorrect = sort(right_incorrect);

intvals = [L.trial_starts' L.trial_stops']
%right
%R_incorrect_in_trials = Restrict(L.Rpokes_incorrect, intvals);

R_incorrect_in_trials = Restrict(L.Rpokes_incorrect, [L.trial_starts' L.trial_stops']);

R_in_trial_YN = InIntervals(L.Rpokes_incorrect, intvals);
L.Rpokes_incorrect(R_in_trial_YN)  
L.Rpokes_incorrect(~R_in_trial_YN)
%left 
%L_incorrect_in_trials = Restrict(L.Lpokes_incorrect, intvals);
L_in_trial_YN = InIntervals(L.Lpokes_incorrect, intvals);
L.Lpokes_incorrect(L_in_trial_YN)  
L.Lpokes_incorrect(~L_in_trial_YN)
%% figure out which init pokes actually initiated a trial
L.Ipokes_incorrect = L.Ipokes;
L.Ipokes_correct = [];


for idx = 1:length(L.trial_starts)
	tempstart = L.trial_starts(idx) - 20;  % if it's within 20 ms before trial start, it's ok
	tempstop  = L.trial_starts(idx) + 500; % if it's within 500 ms of trial start, it's ok
	correct_bool = L.Ipokes_incorrect >= tempstart & L.Ipokes_incorrect <= tempstop;
	L.Ipokes_correct = [L.Ipokes_correct, L.Ipokes_incorrect(correct_bool)];
	L.Ipokes_incorrect = L.Ipokes_incorrect(~correct_bool);
	
end




