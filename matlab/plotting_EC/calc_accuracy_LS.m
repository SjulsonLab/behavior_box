function acc = calc_accuracy_LS(pokes)

% function acc = calc_accuracy_LS(pokes)
%
% this function takes as input "pokes" the output from extract_poke_info().
% It returns "acc", which is a struct containing information about accuracy
% of behavioral performance.
%
% Luke Sjulson, 2019-04-02

% % for testing only
% clear all
% close all
% basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior\ADR45M591_20190326_155919';
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
trial_type = pokes.trialLR_types(pokes.trial_start_nums); % extracting only trials that the animal initiated successfully

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

%% now doing permutation tests

all_accuracy_null   = zeros(N, 1);  % pre-allocating vectors
left_accuracy_null  = zeros(N, 1);
right_accuracy_null = zeros(N, 1);

for idx = 1:N
 	temp_correct_all   = is_correct({all_first_pokes{randperm(length(all_first_pokes))}}, all_trials_types);
	temp_correct_left  = temp_correct_all(new_L_YN);
	temp_correct_right = temp_correct_all(new_R_YN);
	
	all_accuracy_null(idx)   = sum(temp_correct_all) ./ length(temp_correct_all);
	left_accuracy_null(idx)  = sum(temp_correct_left) ./ length(temp_correct_left);
	right_accuracy_null(idx) = sum(temp_correct_right) ./ length(temp_correct_right);
end

% calculate P-values
if isnan(all_accuracy)
    all_pval = 1;
else
    all_pval   = sum(all_accuracy <= all_accuracy_null) ./ N;
end

if isnan(left_accuracy)
    left_pval = 1;
else
    left_pval  = sum(left_accuracy <= left_accuracy_null) ./ N;
end

if isnan(right_accuracy)
    right_pval = 1;
else
    right_pval = sum(right_accuracy <= right_accuracy_null) ./ N;
end

%% copy everything into a struct (by doing this at the end, you control the order of fields)
acc.all = all_accuracy;
acc.all_info = 'accuracy for both left and right trials';
acc.all_chance = median(all_accuracy_null);
acc.all_chance_info = 'expected accuracy by chance alone';
acc.all_pval = all_pval;
acc.all_pval_info = 'p-value for both left and right trials';

acc.left = left_accuracy;
acc.left_info = 'accuracy for left trials only';
acc.left_chance = median(left_accuracy_null);
acc.left_chance_info = 'expected accuracy by chance alone';
acc.left_pval = left_pval;
acc.left_pval_info = 'p-value for left trials only';

acc.right = right_accuracy;
acc.right_info = 'accuracy for right trials only';
acc.right_chance = median(right_accuracy_null);
acc.right_chance_info = 'expected accuracy by chance alone';
acc.right_pval = right_pval;
acc.right_pval_info = 'p-value for right trials only';



