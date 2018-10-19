function sessionStr = makeRewardCodes_v5(sessionStr, trialNums)

% function sessionStr = makeRewardCodes_v5(sessionStr, trialNums)
%
% takes a sessionStr and a vector of trial numbers (or just one) and
% adds the LrewardCode and RrewardCode fields to sessionStr so they
% can be passed to the arduino.
%
% Luke Sjulson, 2018-10-19


% %% for testing
% clear all
% sessionStr.trainingPhase = 3;
% startTrialNum            = 1;     % in case you stop and start on the same day
% resetTimeYN              = 'yes'; %
% 
% % sessionStr.basedir = m.basedir;
% % sessionStr.timeString = m.timeString;
% % sessionStr.dateString = m.dateString;
% % sessionStr.IrewardSize_nL = 5000; %IrewardCode is determined by the training phase
% 
% sessionStr.punishForErrorPoke = 0; % 0 for no, 1 for yes
% 
% % info about trials
% sessionStr.trialLRtype  = makeRandomVector(1:6, 30);
% sessionStr.trialAVtype  = 3 * ones(1, 30); % 1 = auditory only, 2 = visual only, 3 = both aud + vis
% 
% trialNums = 1:30;



%% start of function
if sessionStr.punishForErrorPokeYN==0  % no punishment for incorrect poke
	defCode = 0;
else 
	defCode = -1;
end
	

for idx = 1:length(trialNums)
	nTrial = trialNums(idx);
	
	% if left reward will be given
	if any(sessionStr.trialLRtype(nTrial) == [1 2 5 6])
		sessionStr.LrewardCode(nTrial) = 4;
	end
	
	% if right reward will be given
	if any(sessionStr.trialLRtype(nTrial) == [3 4 5 6])
		sessionStr.RrewardCode(nTrial) = 4;
	end
	
	% for punishment
	if any(sessionStr.trialLRtype(nTrial) == [1 2])
		sessionStr.RrewardCode(nTrial) = defCode;
	elseif any(sessionStr.trialLRtype(nTrial) == [3 4])
		sessionStr.LrewardCode(nTrial) = defCode;
	end
		
		


end