function sessionStr = setCueLengthsPhase4(sessionStr, nTrial, totalRewards)

% function sessionStr = setCueLengthsPhase4(sessionStr, nTrial, totalRewards)
%
% for setting cue delivery parameters for stage 4 training, where they vary
% as a function of the number of rewards the animal has received. Also
% works for stage 5.
%
% Luke Sjulson, 2018-10-29

% %% for testing
% Ntrial = 1;
% totalRewards = 300;
% sessionStr.fakeRewards = 1;
% sessionStr.numRewardsToAdvance = 10;


%% start of actual function

% 1: hold until end, 10 correct trials
% 2: add 25 ms precue, 25 ms postcue. Increment precue every 10
% correct trials until it's 75 ms.
% 3: increase interOnsetInterval by 10 ms every 10 correct trials
% until it's 125 ms

if sessionStr.trainingPhase == 4
	R = sessionStr.numRewardsToAdvance;
	if (totalRewards + sessionStr.fakeRewards) < R
		% no extra delays
		sessionStr.preCueLength(nTrial) = 0;
		sessionStr.postCueLength(nTrial) = 0;
	elseif (totalRewards + sessionStr.fakeRewards) >1*R && (totalRewards + sessionStr.fakeRewards) <= 2*R
		% add precue and postcue 25
		sessionStr.preCueLength(nTrial) = 25;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >2*R && (totalRewards + sessionStr.fakeRewards) <= 3*R
		% precue = 35
		sessionStr.preCueLength(nTrial) = 35;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >3*R && (totalRewards + sessionStr.fakeRewards) <= 4*R
		% precue = 45
		sessionStr.preCueLength(nTrial) = 45;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >4*R && (totalRewards + sessionStr.fakeRewards) <= 5*R
		% precue = 55
		sessionStr.preCueLength(nTrial) = 55;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >5*R && (totalRewards + sessionStr.fakeRewards) <= 6*R
		% precue = 65
		sessionStr.preCueLength(nTrial) = 65;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >6*R && (totalRewards + sessionStr.fakeRewards) <= 7*R
		% precue = 75
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >7*R && (totalRewards + sessionStr.fakeRewards) <= 8*R
		% IOI = 15
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 15;
	elseif (totalRewards + sessionStr.fakeRewards) >8*R && (totalRewards + sessionStr.fakeRewards) <= 9*R
		% IOI = 25
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 25;
	elseif (totalRewards + sessionStr.fakeRewards) >9*R && (totalRewards + sessionStr.fakeRewards) <= 10*R
		% IOI = 35
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 35;
	elseif (totalRewards + sessionStr.fakeRewards) >10*R && (totalRewards + sessionStr.fakeRewards) <= 11*R
		% IOI = 45
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 45;
	elseif (totalRewards + sessionStr.fakeRewards) >11*R && (totalRewards + sessionStr.fakeRewards) <= 12*R
		% IOI = 55
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 55;
	elseif (totalRewards + sessionStr.fakeRewards) >12*R && (totalRewards + sessionStr.fakeRewards) <= 13*R
		% IOI = 65
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 65;
	elseif (totalRewards + sessionStr.fakeRewards) >13*R && (totalRewards + sessionStr.fakeRewards) <= 14*R
		% IOI = 75
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 75;
	elseif (totalRewards + sessionStr.fakeRewards) >14*R && (totalRewards + sessionStr.fakeRewards) <= 15*R
		% IOI = 85
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 85;
	elseif (totalRewards + sessionStr.fakeRewards) >15*R && (totalRewards + sessionStr.fakeRewards) <= 16*R
		% IOI = 95
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 95;
	elseif (totalRewards + sessionStr.fakeRewards) >16*R && (totalRewards + sessionStr.fakeRewards) <= 17*R
		% IOI = 105
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 105;
	elseif (totalRewards + sessionStr.fakeRewards) >17*R && (totalRewards + sessionStr.fakeRewards) <= 18*R
		% IOI = 115
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 115;
	elseif (totalRewards + sessionStr.fakeRewards) >18*R % && (totalRewards + sessionStr.fakeRewards) <= 19*R
		% IOI = 125
		sessionStr.preCueLength(nTrial) = 75;
		sessionStr.postCueLength(nTrial) = 25;
		sessionStr.interOnsetInterval(nTrial) = 125;
	end
	
	% display status for phase 4
	disp(['Animal has ' num2str(totalRewards) ' real rewards and ' num2str(sessionStr.fakeRewards) ' fake ones. precue = ' ...
	num2str(sessionStr.preCueLength(nTrial)) ', postcue = ' num2str(sessionStr.postCueLength(nTrial)) ...
	', IOI = ' num2str(sessionStr.interOnsetInterval(nTrial))]);
	
elseif sessionStr.trainingPhase == 5
	sessionStr.preCueLength(nTrial) = 75;
	sessionStr.postCueLength(nTrial) = 25;
	sessionStr.interOnsetInterval(nTrial) = 125;
else
	error('sessionStr.trainingPhase needs to be 4 or 5 to use this function');
end




% %% for testing
% sessionStr.preCueLength(nTrial)
% sessionStr.postCueLength(nTrial)
% sessionStr.interOnsetInterval(nTrial)


