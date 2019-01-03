function trial_dict = makeTrialDict(sessionStr, nTrial)

% function trial_dict = makeTrialDict(sessionStr, nTrial)
%
% makes a new python dict to be passed to the arduino for each trial.

trial_dict = py.dict; % empty python dict that fills only w/parameters that
% are updated in the current trial.

trial_dict.update(pyargs('nTrial', sessionStr.trialNum(nTrial)));
trial_dict.update(pyargs('trainingPhase', sessionStr.trainingPhase));
trial_dict.update(pyargs('goToPokesLength', sessionStr.goToPokesLength));

% info about trial type - sent to arduino only so that they get
% saved in text log file
trial_dict.update(pyargs('trialLRtype', sessionStr.trialLRtype(nTrial)));
trial_dict.update(pyargs('trialAVtype', sessionStr.trialAVtype(nTrial)));

% % reward info - defunct, as we're no longer using init rewards
% if sessionStr.trainingPhase==1
%     trial_dict.update(pyargs('IrewardCode', 1));
% elseif sessionStr.trainingPhase==2
%     trial_dict.update(pyargs('IrewardCode', 2));
% elseif sessionStr.trainingPhase>2
%     trial_dict.update(pyargs('IrewardCode', 0));
% end

% trial_dict.update(pyargs('IrewardSize_nL', sessionStr.IrewardSize_nL));
trial_dict.update(pyargs('LrewardCode', sessionStr.LrewardCode(nTrial)));
trial_dict.update(pyargs('LrewardSize_nL', sessionStr.LrewardSize_nL(nTrial)));
trial_dict.update(pyargs('RrewardCode', sessionStr.RrewardCode(nTrial)));
trial_dict.update(pyargs('RrewardSize_nL', sessionStr.RrewardSize_nL(nTrial)));

% cue info
trial_dict.update(pyargs('slot1_vis', sessionStr.slot1_vis(nTrial)));
trial_dict.update(pyargs('slot1_aud', sessionStr.slot1_aud(nTrial)));
trial_dict.update(pyargs('slot2_vis', sessionStr.slot2_vis(nTrial)));
trial_dict.update(pyargs('slot2_aud', sessionStr.slot2_aud(nTrial)));
trial_dict.update(pyargs('slot3_vis', sessionStr.slot3_vis(nTrial)));
trial_dict.update(pyargs('slot3_aud', sessionStr.slot3_aud(nTrial)));

trial_dict.update(pyargs('cueWithdrawalPunishYN', sessionStr.cueWithdrawalPunishYN));
trial_dict.update(pyargs('preCueLength', sessionStr.preCueLength(nTrial)));
trial_dict.update(pyargs('slot1Length', sessionStr.slot1Length(nTrial)));
trial_dict.update(pyargs('slot2Length', sessionStr.slot2Length(nTrial)));
trial_dict.update(pyargs('slot3Length', sessionStr.slot3Length(nTrial)));
trial_dict.update(pyargs('postCueLength', sessionStr.postCueLength(nTrial)));

