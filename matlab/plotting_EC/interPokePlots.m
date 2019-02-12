%interpoke plots
%TO DO, all initiated plot until time out
[~,basename] = fileparts(cd)

Lpokes = getEventTimes('leftPokeEntry', [basename '.txt']);
Rpokes = getEventTimes('rightPokeEntry', [basename '.txt']);
Ipokes = getEventTimes('initPokeEntry', [basename '.txt']);
Lrewards = getEventTimes('leftRewardCollected', [basename '.txt']);
Rrewards = getEventTimes('rightRewardCollected', [basename '.txt']);


trialStarts = getEventTimes('TrialStarted_ms', [basename '.txt']);
missAfterStart = getEventTimes('TrialMissedAfterInit_ms', [basename '.txt']);

LRreward = zeros(2,length(Lrewards)+length(Rrewards)+length(missAfterStart));
LRreward(2,:) = cat(2,Lrewards,Rrewards,missAfterStart);
LRreward(1,:) = cat(2,zeros(size(Lrewards)),ones(size(Rrewards)),ones(size(missAfterStart))*2);
[~,I] = sort(LRreward(2,:));

LRreward = LRreward(:,I);

for i = 1:length(trialStarts)
    interPoke(i).auxL = Restrict(Lpokes,[trialStarts(i)',LRreward(2,i)']);
    interPoke(i).auxR = Restrict(Rpokes,[trialStarts(i)',LRreward(2,i)']);
    interPoke(i).auxI = Restrict(Ipokes,[trialStarts(i)' LRreward(2,i)']);
end

TrialsCompleted = length(Lrewards)+length(Rrewards);
auxLe = find(LRreward(1,:)==0);
auxRe = find(LRreward(1,:)==1);

if ~isempty(auxLe)
    for i = 1:length(auxLe)
        wrongPokesL(i).aux = interPoke(auxLe(i)).auxL-trialStarts(auxLe(i));
    end
end

if ~isempty(auxRe)
    for i = 1:length(auxRe)
        wrongPokesR(i).aux = interPoke(auxRe(i)).auxL-trialStarts(auxRe(i));
    end
end

%% plot
figure;
hold on
for i = 1:length(trialStarts)
    if ~isempty(interPoke(i).auxL)
        plot(interPoke(i).auxL-trialStarts(i),i,'sb')
    end
end

for i = 1:length(trialStarts)
    if ~isempty(interPoke(i).auxR)
        plot(interPoke(i).auxR-trialStarts(i),i,'sr')
    end
end

for i = 1:length(trialStarts)
    if ~isempty(interPoke(i).auxI)
        plot(interPoke(i).auxI-trialStarts(i),i,'sg')
    end
end

auxLe = find(LRreward(1,:)==0);
auxRe = find(LRreward(1,:)==1);

for i = auxLe
   plot(LRreward(2,i)-trialStarts(i),i,'pb','markerfacecolor','b','markersize',10)
end

for i = auxRe
   plot(LRreward(2,i)-trialStarts(i),i,'pr','markerfacecolor','r','markersize',10)
end

for i = auxLe
   plot([0 LRreward(2,i)-trialStarts(i)],[i i],'--b')
end

for i = auxRe
   plot([0 LRreward(2,i)-trialStarts(i)],[i i],'--r')
end
