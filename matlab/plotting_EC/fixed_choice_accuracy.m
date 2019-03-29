function fixed_choice_accuracy(basedir,startdir)

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

%calculating fixed choice accuracy
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

temp = firstPoke(1,:) - firstPoke(2,:);
observed_accuracy = length(find( (temp) == 0  ))/length(trialStarts2);
for i = 1:10000 
    aux = randperm(length(firstPoke(2,:)));
    temp = firstPoke(1,aux) - firstPoke(2,:);
    null_distribution(i) = length(find( (temp) == 0  ))/length(trialStarts2);
    %S= std (firstPoke(1,:)), (firstPoke(2,:))
%     stderror = std(firstPoke(2,:))/sqrt(length(firstPoke(2,:)));
%     null_distribution(i) = [mean(firstPoke(1,:)) - mean(firstPoke(2,:))]/stderror;
end
hist(null_distribution)




hist(null_distribution,100)
[auxND,x] = hist(null_distribution,100);
auxND = auxND./sum(auxND);
%f = fit(x',auxND','gauss1');
y = cumsum(auxND);
tempPV = find(y>=0.95);
p5=x(tempPV(1));
observed_accuracy>=p5
observed_accuracy
expected_accuracy = median(null_distribution)
pval = sum(null_distribution >= observed_accuracy) ./ length(null_distribution)


% for i = 1:length(trialStarts)
%     interPoke(i).auxL = Restrict(Lpokes,[trialStarts(i)',LRreward(2,i)']);
%     interPoke(i).auxR = Restrict(Rpokes,[trialStarts(i)',LRreward(2,i)']);
%     interPoke(i).auxI = Restrict(Ipokes,[trialStarts(i)' LRreward(2,i)']);
% end
% 
% TrialsCompleted = length(Lrewards)+length(Rrewards);
% auxLe = find(LRreward(1,:)==0);
% auxRe = find(LRreward(1,:)==1);
% 
% if ~isempty(auxLe)
%     for i = 1:length(auxLe)
%         wrongPokesL(i).aux = interPoke(auxLe(i)).auxL-trialStarts(auxLe(i));
%     end
% end
% 
% if ~isempty(auxRe)
%     for i = 1:length(auxRe)
%         wrongPokesR(i).aux = interPoke(auxRe(i)).auxL-trialStarts(auxRe(i));
%     end
% end

%plotting
figure;subplot(2,2,1);
[N,X]=hist(trialDur/1000,[0:2:60]);bar(X,N,'facecolor','k')
xlabel('time')
title('Time to correct side NP')

subplot(2,2,2)
accLeft = length(find(firstPoke(2,:)==0 & firstPoke(1,:)==0))/length(find(firstPoke(2,:)==0));
accRight = length(find(firstPoke(2,:)==1 & firstPoke(1,:)==1))/length(find(firstPoke(2,:)==1));
bar(1,accLeft,'facecolor','b');hold on
bar(2,accRight,'facecolor','r')
xticks([1 2])
xticklabels({'Left','Right'})
ylabel('Accuracy')

subplot(2,2,3);
[N,X]=hist((firstPoke(3,:)-trialStarts2)/1000,[0:2:60]);bar(X,N,'facecolor','k')
xlabel('time')
title('Time to first NP after init')
end


