function init_latency(basedir,startdir)  

if nargin<2
	startdir = pwd;
    basedir = pwd;
end

cd(startdir);
cd(basedir);

[~,basename] = fileparts(pwd);

% extract times of nosepoke entries
Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
Lrewards = getEventTimes('leftRewardCollected', [basename '.txt']);
Rrewards = getEventTimes('rightRewardCollected', [basename '.txt']);
% extract times of trial starts
trial_avail = getEventTimes('TrialAvailable', [basename '.txt']);
trialStarts = getEventTimes('TrialStarted', [basename '.txt']);
miss_Before_Start = getEventTimes('TrialMissedBeforeInit_ms', [basename '.txt']);
missAfterStart = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);

%latency to init (Edith) 
trial_add_up_with_cat = zeros(2,length(trialStarts)+length(miss_Before_Start));
trial_add_up_with_cat(1,:) = cat(2,zeros(size(miss_Before_Start)),ones(size(trialStarts)));
trial_add_up_with_cat(2,:) = cat(2,miss_Before_Start,trialStarts);
[~,I] = sort(trial_add_up_with_cat(2,:));
trial_add_up_with_cat = trial_add_up_with_cat(:,I);

trial_start_info_in_trial_avail = find(trial_add_up_with_cat(1,:)==1);
trial_missed_before_start_info_in_trial_avail = find(trial_add_up_with_cat(1,:)==0);

latency_to_init_poke = trial_add_up_with_cat(2,trial_start_info_in_trial_avail)-trial_avail(trial_start_info_in_trial_avail);
hist(latency_to_init_poke/1000)

latency_to_miss_Before_Start = trial_add_up_with_cat(2,trial_missed_before_start_info_in_trial_avail)-trial_avail(trial_missed_before_start_info_in_trial_avail);
hist(latency_to_miss_Before_Start/1000)

total_init_points = cat(2,latency_to_init_poke,latency_to_miss_Before_Start); 
hist(total_init_points/1000,[0:10 10014/1000 11014/1000]) 
xlabel('time(sec)')
title('Latency to init')


%latency to sides after init 
%zeros mean left rewards, ones mean right rewards, twos mean missed after
%start

LRreward = zeros(2,length(Lrewards)+length(Rrewards)+length(missAfterStart));
LRreward(2,:) = cat(2,Lrewards,Rrewards,missAfterStart);
LRreward(1,:) = cat(2,zeros(size(Lrewards)),ones(size(Rrewards)),ones(size(missAfterStart))*2);

[~,I] = sort(LRreward(2,:));

LRreward = LRreward(:,I);

auxDur = find(LRreward(1,:)==0 | LRreward(1,:)==1);
trialDur = LRreward(2,auxDur) - trialStarts(auxDur);

auxIntPk(1,:) = cat(2,zeros(size(Lpokes)),ones(size(Rpokes)));
auxIntPk(2,:) = cat(2,Lpokes,Rpokes);
[~,I] = sort(auxIntPk(2,:));
auxIntPk = auxIntPk(:,I);

trialStarts2 = trialStarts(auxDur);
LRreward2 = LRreward(:,auxDur);

end
