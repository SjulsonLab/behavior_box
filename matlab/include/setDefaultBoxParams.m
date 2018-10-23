function boxParams = setDefaultBoxParams(sessionStr)

% function boxParams = setDefaultBoxParams(sessionStr)
%
% returns a python dict containing the default box parameters
%
% Luke, 2018-10-23


boxParams = py.dict;
boxParams.update(pyargs('nTrial',            sessionStr.startTrialNum));
boxParams.update(pyargs('resetTimeYN',       0)); % setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
boxParams.update(pyargs('initPokePunishYN',  0)); % setting to 1 enables punishment for initpoke during standby
boxParams.update(pyargs('cueWithdrawalPunishYN', 0)); % setting to 1 enables punishment for poke withdrawal during cues

boxParams.update(pyargs('WNvolume',      50));
boxParams.update(pyargs('lowCueVolume',  120));
boxParams.update(pyargs('highCueVolume', 120));
boxParams.update(pyargs('buzzerVolume',  90));

boxParams.update(pyargs('trainingPhase', 0));
boxParams.update(pyargs('laserOnCode', 0));

% % stuff we're not using now that we don't have doors
% boxParams.update(pyargs('doorCloseSpeed',        1)); % original default was 10
% boxParams.update(pyargs('IopenYN', 0)); % 1 means open port, 0 means keep closed
% boxParams.update(pyargs('LopenYN', 0));
% boxParams.update(pyargs('RopenYN', 0));
% boxParams.update(pyargs('extra4openYN', 0));
% boxParams.update(pyargs('extra5openYN', 0));

% these are all in milliseconds
boxParams.update(pyargs('readyToGoLength',        1000*30));
boxParams.update(pyargs('punishDelayLength',      1000*6));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('slot1Length',             5));
boxParams.update(pyargs('slot2Length',             5));
boxParams.update(pyargs('slot3Length',             5));
boxParams.update(pyargs('postCueLength',          10));
boxParams.update(pyargs('goToPokesLength',        1000*60));
boxParams.update(pyargs('rewardCollectionLength', 1000*5));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('RrewardCode',  0));
% boxParams.update(pyargs('extra4rewardCode',  0));
% boxParams.update(pyargs('extra5rewardCode',  0));
% boxParams.update(pyargs('extra6rewardCode',  0));

boxParams.update(pyargs('IrewardSize_nL',       1000*5));
boxParams.update(pyargs('LrewardSize_nL',       1000*5));
boxParams.update(pyargs('RrewardSize_nL',       1000*5));
boxParams.update(pyargs('deliveryDuration_ms',  1000));
boxParams.update(pyargs('syringeSize_mL',       5));

boxParams.update(pyargs('cueLED1Brightness',       1023));
boxParams.update(pyargs('cueLED2Brightness',       1023));
boxParams.update(pyargs('cueLED3Brightness',       1023));
boxParams.update(pyargs('cueLED4Brightness',       1023));