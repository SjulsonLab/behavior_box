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

load('session_info.mat')%to get whether poke withdrawal was punished + times

% extract times of nosepoke entries
L.Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
L.Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
L.Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
L.Ipokes_exit = getEventTimes('initPokeExit_ms', [basename '.txt']);
[L.Lreward_pokes, ~, L.Lreward_poke_trialnum] =   getEventTimes('leftRewardCollected', [basename '.txt']);
[L.Rreward_pokes, ~, L.Rreward_poke_trialnum] = getEventTimes('rightRewardCollected', [basename '.txt']);
% extract times of trial starts
L.trial_avails = getEventTimes('TrialAvailable', [basename '.txt']);
[L.trial_starts, ~, L.trial_start_nums] = getEventTimes('TrialStarted', [basename '.txt']);
L.trial_stops = [];

% extract times of early withdrawal
L.withdrawal = getEventTimes('Withdrawal', [basename '.txt']);

% extract reward size for each poke
[~,L.Ireward_size] = getEventTimes('initReward_nL', [basename '.txt']); %init poke reward size
[~,L.Lreward_size] = getEventTimes('leftReward_nL', [basename '.txt']); %left poke reward size
[~,L.Rreward_size] = getEventTimes('rightReward_nL', [basename '.txt']); %right poke reward size

[~,L.R_size] = getEventTimes('Rsize_nL', [basename '.txt']); %right poke reward size
[~,L.L_size] = getEventTimes('Lsize_nL', [basename '.txt']); %right poke reward size


%% extract latencies for each init poke that resulted in a trial start
L.trial_start_latencies = zeros(size(L.trial_starts));
for idx = 1:length(L.trial_starts)
	tempvec = L.trial_starts(idx) - L.trial_avails;
	tempvec(tempvec<0) = Inf;
	L.trial_start_latencies(idx) = min(tempvec); % finding the closest trial_avail that preceded the trial start
end

if length(L.Ipokes)>length(L.Ipokes_exit) %cutting Ipokes that finished after the session was over
    L.Ipokes = L.Ipokes(1:end-1); 
end
temp = ismember(L.Ipokes,L.trial_starts);


%extract how long the animal hold inside the nose poke
aux = [];
for a = 1:length(L.Ipokes)
   temp = Restrict(L.trial_starts,[L.Ipokes(a) L.Ipokes_exit(a)]);
   if ~isempty(temp)
       aux = [aux a];
   end
end
    
L.I_hold_time = L.Ipokes_exit(aux)-L.Ipokes(aux);
%% figure out which init pokes actually initiated a trial
L.Ipokes_correct = L.Ipokes(aux);
L.Ipokes_incorrect = L.Ipokes(~ismember(1:length(L.Ipokes),aux));

%% extract latencies for each left and right reward collection
L.Lreward_pokes_latencies = zeros(size(L.Lreward_pokes));
for idx = 1:length(L.Lreward_pokes_latencies)
	tempvec = L.Lreward_pokes(idx) - L.trial_starts;
	tempvec(tempvec<0) = Inf;
	L.Lreward_pokes_latencies(idx) = min(tempvec);% finding the closest trial_start that preceded the L reward collection
end

L.Rreward_pokes_latencies = zeros(size(L.Rreward_pokes));
for idx = 1:length(L.Rreward_pokes_latencies)
	tempvec = L.Rreward_pokes(idx) - L.trial_starts;
	tempvec(tempvec<0) = Inf;
	L.Rreward_pokes_latencies(idx) = min(tempvec);% finding the closest trial_start that preceded the L reward collection
end

L.trial_starts = L.trial_starts;
L.trial_start_latencies = L.trial_start_latencies;


%% figure out which pokes are correct vs. incorrect

%% 
[~, L.trialLR_types] = getEventTimes('trialLRtype', [basename '.txt']);
[~,L.requiredInitHold] = getEventTimes('requiredPokeHoldLength_ms', [basename '.txt']);
miss_before_start = getEventTimes('TrialMissedBeforeInit_ms', [basename '.txt']);
miss_after_start = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);
standby     = getEventTimes('Standby', [basename '.txt']);

all_stops = [miss_before_start, miss_after_start, standby];

left_incorrect = L.Lpokes;
right_incorrect = L.Rpokes;
left_correct = [];
right_correct = [];
left_pokes_wrong = [];
right_pokes_wrong = [];
for idx = 1:length(L.trial_starts)
	ntrial = L.trial_start_nums(idx);
	tempstart = L.trial_starts(idx);
	tempvec = all_stops - tempstart;
	tempvec(tempvec<=0) = Inf;
	[~, i] = min(tempvec);
	tempstop = all_stops(i);
	L.trial_stops(idx) = tempstop;
	
	if any(L.trialLR_types(idx) == [1 2 5 6]) % left pokes are correct
		left_correct = [left_correct, left_incorrect(left_incorrect >= tempstart & left_incorrect <= tempstop)];
		left_incorrect = left_incorrect(left_incorrect < tempstart | left_incorrect > tempstop);
	end
	
	if any(L.trialLR_types(idx) == [3 4 5 6]) % right pokes are correct
		right_correct = [right_correct, right_incorrect(right_incorrect >= tempstart & right_incorrect <= tempstop)];
		right_incorrect = right_incorrect(right_incorrect < tempstart | right_incorrect > tempstop);
    end
    
    %getting pokes that were the opposite of what was instructed
    if any(L.trialLR_types(idx) == [1 2])%left poke instruction
        right_pokes_wrong = [right_pokes_wrong, right_incorrect(right_incorrect>=tempstart & right_incorrect<=tempstop)];
		right_incorrect = right_incorrect(right_incorrect < tempstart | right_incorrect > tempstop);
    end
    
    if any(L.trialLR_types(idx) == [3 4])%right poke instruction
        left_pokes_wrong = [left_pokes_wrong, left_incorrect(left_incorrect>=tempstart & left_incorrect<=tempstop)];
		left_incorrect = left_incorrect(left_incorrect < tempstart | left_incorrect > tempstop);
    end
end

L.cueWithdrawalPunishYN = session_info.cueWithdrawalPunishYN;
L.Lpokes_correct   = sort(left_correct);
L.Lpokes_incorrect = sort(left_incorrect);
L.Lpokes_wrong     = sort(left_pokes_wrong);
L.Rpokes_correct   = sort(right_correct);
L.Rpokes_incorrect = sort(right_incorrect);
L.Rpokes_wrong     = sort(right_pokes_wrong);


if session_info.cueWithdrawalPunishYN
    holdTime = session_info.preCueLength+session_info.cue1Length+session_info.postCueLength;
    idx = ismember(L.Ipokes,L.Ipokes_correct);
    temp2 = (L.Ipokes_exit(idx)-L.Ipokes(idx)) > holdTime;
    L.Ipokes_valid = L.Ipokes_correct(temp2);
    L.trial_starts_valid = L.trial_starts(temp2);
    L.trial_stops_valid = L.trial_stops(temp2);
    L.valid_trials_logic = temp2;
else
    L.Ipokes_valid = nan;
    L.trial_starts_valid = nan;
    L.trial_stops_valid = nan;
    L.valid_trials_logic = nan;
end

L.info_wrong_incorrect = ['pokes_wrong are nose pokes that were cued' ...
' to the other poke. e.g. left poke cue and the animal did right poke.' ...
'Incorrect pokes are any side pokes that are outside of the trial, i.e., '...
'side poke before init poke or side poke after the trial is completed/during punishment'];








