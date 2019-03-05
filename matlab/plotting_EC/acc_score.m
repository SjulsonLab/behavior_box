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


[~,basename] = fileparts(cd)

Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
Lrewards = getEventTimes('leftRewardCollected', [basename '.txt']);
Rrewards = getEventTimes('rightRewardCollected', [basename '.txt']);


trialStarts = getEventTimes('TrialStarted', [basename '.txt']);
missAfterStart = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);

LRreward = zeros(2,length(Lrewards)+length(Rrewards)+length(missAfterStart));
LRreward(2,:) = cat(2,Lrewards,Rrewards,missAfterStart);
LRreward(1,:) = cat(2,zeros(size(Lrewards)),ones(size(Rrewards)),ones(size(missAfterStart))*2);
%zeros mean left rewards, ones mean right rewards, twos mean missed after
%start
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
%calculating accuracy
for i = 1:length(trialStarts2) %remove trials that weren't finished
    temp = Restrict(auxIntPk(2,:),[trialStarts2(i)',LRreward2(2,i)']);
%     if ~isempty(temp)
        temp2 = find(auxIntPk(2,:)==temp(1));
        firstPoke(1,i) = auxIntPk(1,temp2); %which trial the animal poked
        firstPoke(2,i) = LRreward2(1,i); %which it was supposed to be
        firstPoke(3,i) = auxIntPk(2,temp2);
%     else
        
%     end
    
end

choices = firstPoke(1,:); 
trials = firstPoke(2,:); 
temp = choices - trials;
null_distribution = length(find( (temp) == 0  ))/length(trialStarts2);
null_distribution
end 

