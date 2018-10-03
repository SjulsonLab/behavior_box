function sessionStr = makeRewardCodes(sessionStr)

% function sessionStr = makeRewardCodes(sessionStr)
%
% function to generate reward codes based on the sessionStr struct


% %% for testing
%
% sessionStr.trainingPhase = 3;
% startTrialNum            = 1;     % in case you stop and start on the same day
% resetTimeYN              = 'yes'; %
%
% sessionStr.basedir = m.basedir;
% sessionStr.timeString = m.timeString;
% sessionStr.dateString = m.dateString;
% sessionStr.IrewardSize_nL = 5000; %IrewardCode is determined by the training phase
%
% sessionStr.punishForErrorPoke = 0; % 0 for no, 1 for yes
%
% % info about trials
% sessionStr.trialLRtype  = [3 3 2 1 3 2 3 1 2 1 3 3 2 1]; % 1 = left, 2 = right, 3 = free choice (i.e. both)
% sessionStr.trialAVtype  = [3 3 3 3 3 3 3 3 3 3 3 3 3 3]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
%
% sessionStr.leftCueWhen  = [2 1 2 3 1 2 3 2 1 1 1 3 2 2]; % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots
% sessionStr.rightCueWhen = [2 2 1 1 1 2 3 1 2 3 1 2 3 1]; % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots


%% start of function

if strcmpi(sessionStr.punishForErrorPoke, 'no') % no punishment for incorrect poke
    LrewardCode = zeros(size(sessionStr.trialLRtype));
    RrewardCode = LrewardCode;
elseif strcmpi(sessionStr.punishForErrorPoke, 'yes')
    LrewardCode = -1 * ones(size(sessionStr.trialLRtype)); % punish for incorrect poke
    RrewardCode = LrewardCode;
else
    error('Can not interpret sessionStr.punishForErrorPoke');
end

if contains(sessionStr.phase3_firstblock, 'yes')
    LrewardCode(sessionStr.trialLRtype==1 | sessionStr.trialLRtype==3) = 3;
    RrewardCode(sessionStr.trialLRtype==2 | sessionStr.trialLRtype==3) = 3;
else
    LrewardCode(sessionStr.trialLRtype==1 | sessionStr.trialLRtype==3) = 4;
    RrewardCode(sessionStr.trialLRtype==2 | sessionStr.trialLRtype==3) = 4;
end


sessionStr.LrewardCode = LrewardCode;
sessionStr.RrewardCode = RrewardCode;

