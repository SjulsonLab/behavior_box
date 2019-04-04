function acc_score(choices, trials) 

% This function calculates the percentage of the matched dataset (animals' choices) within the
% total dataset (assigned trials) and gives a null distribution. 
% You can further do random permutation of a dataset to see if there is a relationship between choices and trials. 
% N0 = no relationship 
% NA = relationship 
% Calculate the probability distribution, set confidence interval as 95%. 
% Find the P-value and see the proporatin of data that is larger than the
% P-value. This proportion would be the true accuracy of animal's preference. 

% i.e. The senario is that we wanted to see if the percentages of assigned trials have
% influences on animals' choices. If the reward sides were assigned disproportionaely across different time points,
% it is very likely that the animals choices do not reflect the percentages they actually prefer.
% We wanted to know if there preferences to any port is actually correct or by chance. 

% Edited by Edith 2019/03/05


[~,basename] = fileparts(pwd);

%extract poke info
L.Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
L.Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
L.Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
[L.Lreward_pokes, ~, L.Lreward_poke_trialnum] = getEventTimes('leftRewardCollected', [basename '.txt']);
[L.Rreward_pokes, ~, L.Rreward_poke_trialnum] = getEventTimes('rightRewardCollected', [basename '.txt']);
% extract times of trial starts
L.trial_avails = getEventTimes('TrialAvailable', [basename '.txt']);
[L.trial_starts, ~, L.trial_start_nums] = getEventTimes('TrialStarted', [basename '.txt']);
L.trial_stops = [];

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

%L.R_incorrect_in_trials = Restrict(L.Rpokes_incorrect, [L.trial_starts' L.trial_stops']);
R_in_trial_YN = InIntervals(L.Rpokes_incorrect, intvals);
L.R_incorrect_in_trials = L.Rpokes_incorrect(R_in_trial_YN)  
%L.Rpokes_incorrect(~R_in_trial_YN)
%left 
%L.L_incorrect_in_trials = Restrict(L.Lpokes_incorrect, [L.trial_starts' L.trial_stops']);
L_in_trial_YN = InIntervals(L.Lpokes_incorrect, intvals);
L.L_incorrect_in_trials = L.Lpokes_incorrect(L_in_trial_YN)  
%L.Lpokes_incorrect(~L_in_trial_YN)

%% right accuracy 

% find all the rewarded one in trial start first 
L.R_reward= zeros(2,length(L.Rpokes_correct)+length(miss_after_start));
L.R_reward(2,:) = cat(2,L.Rpokes_correct,miss_after_start);
L.R_reward(1,:) = cat(2,zeros(size(L.Rpokes_correct)),ones(size(miss_after_start))*2); 
[~,I] = sort(L.R_reward(2,:));   
L.R_reward= L.R_reward(:,I);  
 

L.auxDur_R = find(L.R_reward(1,:)==0); %
L.trialDur_R = L.R_reward(2,L.auxDur_R) - L.trial_starts(L.auxDur_R); %the time from trialstart to reward 

%look inside all the Rpoke 
L.right_auxIntPk(1,:) = cat(2,ones(size(L.Rpokes))); %R poke num 
L.right_auxIntPk(2,:) = cat(2,L.Rpokes); %R poke time 
[~,I] = sort(L.right_auxIntPk(2,:));
L.right_auxIntPk = L.right_auxIntPk(:,I);


% within trial start, we only look into the R rewarded trial 
L.trial_starts2_R = L.trial_starts(L.auxDur_R); 
L.R_reward2 = L.R_reward(:,L.auxDur_R); 

%inside the rewarded ones, find the ones that animal pokes the first to the right  
for i = int16(1:length(L.trial_starts2_R)) %remove trials that weren't finished
    L.temp_R = Restrict(L.right_auxIntPk(2,:),[L.trial_starts2_R(i)',L.R_reward2(2,i)']); %R pokes points from trialstart to collect 
%     if ~isempty(temp)
        L.temp2_R = find(L.right_auxIntPk(2,:)==L.temp_R(1)); %find the first poke of R in all R pokes   
        L.right_firstPoke(1,i) = L.right_auxIntPk(1,L.temp2_R); %which trial the animal poked  (first choices correct) 
        L.right_firstPoke(2,i) = L.R_reward2(1,i); %which it was supposed to be  (the R rewarded/correct/assign trial within trial starts) 
        L.right_firstPoke(3,i) = L.right_auxIntPk(2,L.temp2_R); % just the time of the first poke of R in all R pokes   
%     else
        
%     end
    
end

temp_right = L.right_firstPoke(1,:) - L.right_firstPoke(2,:);
observed_right_accuracy = length(find( (temp_right) == 0))/length(L.trial_starts2_R);

for i = 1:10000 
    L.right_aux = randperm(length(L.right_firstPoke(2,:)));
    temp_right = L.right_firstPoke(1,L.right_aux) - L.right_firstPoke(2,:);
    R_null_distribution(i) = length(find( (temp_right) == 0  ))/length(L.trial_starts2_R);
end


hist(R_null_distribution,100)
[R_auxND,x] = hist(R_null_distribution,100);
R_auxND = auxND./sum(R_auxND);
%f = fit(x',auxND','gauss1');
y = cumsum(R_auxND);
R_tempPV = find(y>=0.95);
p5=x(R_tempPV(1));
observed_right_accuracy>=p5
observed_right_accuracy
expected_right_accuracy = median(R_null_distribution)
pval = sum(R_null_distribution >= observed_right_accuracy) ./ length(R_null_distribution)



%%left or right accuracy 

L_trial = find(L.trialLR_types(1,:)==3)  %31  
%zeros(size(L_trial))

%L.trialLR_types_in_trials = Restrict(L.trialLR_types, [L.trial_starts' L.trial_stops']);


Ltemp = Restrict(L.Lpokes, [L.trial_starts(L.trial_start_nums(idx)) L.trial_stops(L.trial_start_nums(idx))])
Rtemp = Restrict(L.Rpokes, [L.trial_starts(L.trial_start_nums(idx)) L.trial_stops(L.trial_start_nums(idx))])
L.trialLR_types(L.trial_start_nums(idx))  %within the trial starts left happens first 






   




