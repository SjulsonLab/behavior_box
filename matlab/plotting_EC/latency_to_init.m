clear all

[~,basename] = fileparts(cd)


trial_avail = getEventTimes('TrialAvailable', [basename '.txt']);
trialStarts = getEventTimes('TrialStarted', [basename '.txt']);
miss_Before_Start = getEventTimes('TrialMissedBeforeInit_ms', [basename '.txt']);
missAfterStart = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);

%latency to init 
trial_add_up_with_cat = zeros(2,length(trialStarts)+length(miss_Before_Start));
trial_add_up_with_cat(1,:) = cat(2,zeros(size(miss_Before_Start)),ones(size(trialStarts)));
trial_add_up_with_cat(2,:) = cat(2,miss_Before_Start,trialStarts);
[~,I] = sort(trial_add_up_with_cat(2,:));
trial_add_up_with_cat = trial_add_up_with_cat(:,I);

trial_start_info_in_trial_avail = find(trial_add_up_with_cat(1,:)==1);
latency_to_init_poke = trial_add_up_with_cat(2,trial_start_info_in_trial_avail)-trial_avail(trial_start_info_in_trial_avail);









