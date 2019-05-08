function interPokePlots2(basedir,startdir)

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
% 
 if ~isempty(auxRe)
     for i = 1:length(auxRe)
         wrongPokesR(i).aux = interPoke(auxRe(i)).auxL-trialStarts(auxRe(i));
     end
 end


% plot
 figure;
 hold on
 for i = 1:length(trialStarts)
     if ~isempty(interPoke(i).auxL)
         plot(interPoke(i).auxL-trialStarts(i),i,'sb')
     end
 end
% 
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
% 
 for i = auxLe
    plot(LRreward(2,i)-trialStarts(i),i,'pb','markerfacecolor','b','markersize',10)
 end
% 
 for i = auxRe
    plot(LRreward(2,i)-trialStarts(i),i,'pr','markerfacecolor','r','markersize',10)
 end
 
for i = auxLe
    plot([0 LRreward(2,i)-trialStarts(i)],[i i],'--b')
 end
 
 for i = auxRe
    plot([0 LRreward(2,i)-trialStarts(i)],[i i],'--r')
 end
 
 %left poke estamation after init
 
 
 

 
 
 
