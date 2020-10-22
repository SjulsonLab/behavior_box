 function [bsi,p] = bias_index(pokes)

% function bsi = bias_index(pokes)
%
% this function should calculate a bias index from the animal's behavior



 basedir = pwd; 
 pokes = extract_poke_info(basedir);
% pokes.trialLR_types([1:3:20]) = 6; % just to make sure it handles free choice trials 

%% start of actual function
N = 10000; % number of permutations to calculate

%% making cell array of which poke occurred first 
first_poke = {};
for idx = 1:length(pokes.trial_starts)
	t = 10; % also keeping pokes that occur within 10 ms before start and after end of trial
	Ltemp = Restrict(pokes.Lpokes, [pokes.trial_starts(idx)-t pokes.trial_stops(idx)+t]);
	Rtemp = Restrict(pokes.Rpokes, [pokes.trial_starts(idx)-t pokes.trial_stops(idx)+t]);

	if isempty(Rtemp) && isempty(Ltemp)
		first_poke{idx} = 'none';
	elseif isempty(Ltemp)
		first_poke{idx} = 'right';
	elseif isempty(Rtemp)
		first_poke{idx} = 'left';
	elseif min(Ltemp) < min(Rtemp)
		first_poke{idx} = 'left';
	elseif min(Rtemp) < min(Ltemp)
		first_poke{idx} = 'right';
	end

end

%% figure out what the accuracies are
% trial_type = pokes.trialLR_types(pokes.trial_start_nums); % extracting only trials that the animal initiated successfully
trial_type = pokes.trialLR_types;
L_YN    = trial_type == 1 | trial_type == 2;
R_YN    = trial_type == 3 | trial_type == 4;
% free_YN = trial_type == 5 | trial_type == 6;

% extract what the first pokes and trial types were
all_trials_types  = trial_type(L_YN | R_YN);
all_first_pokes   = {first_poke{L_YN | R_YN}};
left_first_pokes  = {first_poke{L_YN}}; % first pokes for left-cue trials, not trials where the animal poked left first
right_first_pokes = {first_poke{R_YN}};
new_L_YN          = all_trials_types == 1 | all_trials_types == 2; % whether the trials within all_trials-types are L or R
new_R_YN          = all_trials_types == 3 | all_trials_types == 4;

% determine if each trial was correct (1) or incorrect (0)
all_correctYN   = is_correct(all_first_pokes, all_trials_types); 
left_correctYN  = is_correct(left_first_pokes, ones(size(left_first_pokes)));
right_correctYN = is_correct(right_first_pokes, 3*ones(size(right_first_pokes)));

% calculate accuracies
all_accuracy    = sum(all_correctYN) ./ length(all_correctYN);
left_accuracy   = sum(left_correctYN) ./ length(left_correctYN);
right_accuracy  = sum(right_correctYN) ./ length(right_correctYN);

% bias index
index = right_accuracy-left_accuracy;

% contingency table 
x = sum(left_correctYN);  % # of 1 of left trial 
y = sum(right_correctYN); % # of 1 of right trial 
a = length(all_correctYN)-x; % # of 0 of left trial 
b = length(all_correctYN)-y; % # of 0 of right trial 
%t = table([x;y],[a;b],'VariableNames',{'Correct','Incorrect'},'RowNames',{'Left trial','Right trial'})
t = [x,y;a,b];

[h,p] = fishertest(t);
bsi = index;
% 0 does not reject the null hypothesis of no nonrandom association between the categorical variables
