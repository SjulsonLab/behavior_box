clear all

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
%calculating accuracy not by chance (randomization) 
temp = firstPoke(1,:) - firstPoke(2,:);
trueAccuracy = length(find( (temp) == 0  ))/length(trialStarts2);
for i = 1:10000
    aux = randperm(length(firstPoke(2,:))); 
    temp = firstPoke(1,aux) - firstPoke(2,:);
    null_distribution(i) = length(find( (temp) == 0  ))/length(trialStarts2);
end

plot(null_distribution)_ 
pval=sum(null_distribution>=0.1)/10000
    if pval >=0.05 
        disp("fail to reject null hypothesis.")
    else 
         disp("reject null hypothesis.")
    end 
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
