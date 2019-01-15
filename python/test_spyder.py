# -*- coding: utf-8 -*-
"""
Rewriting the behavioral box code in python

Luke Sjulson, 2018-12-28

"""

#%% importing stuff
from time import sleep
import serial      # for communication with arduino
import collections # for ordered dicts (sessionStr)
import pysistence  # for immutable dict (mouseStr)
import numpy as np 



#%% defining immutable mouse dict
mouse_dict = pysistence.make_dict({'mouseName': 'jaxmale08',
                 'requiredVersion': 6,
                 'leftVisCue': 0,
                 'rightVisCue': 3,
                 'leftAudCue': 3,
                 'rightAudCue': 0})

# defining session dict

resetTimeYN                             = 'yes'
sessionStr                              = collections.OrderedDict()
sessionStr['mouseName']                 = mouse_dict['mouseName']
sessionStr['trainingPhase']             = 2
sessionStr['startTrialNum']             = 1
sessionStr['maxSessionLength_min']      = 60  # in minutes
sessionStr['maxTrials']                 = 1000  # program terminates when either maxSessionLength_min or maxTrials is reached
sessionStr['maxRewards']                = 200    # program also terminates if maxRewards is reached
sessionStr['interTrialInterval_mean']   = 0   # number of extra seconds between trials
sessionStr['interTrialInterval_SD']     = 0   # standard deviatino of seconds between trials
sessionStr['punishForErrorPokeYN']      = 0  # 0 = no, 1 = yes for stage 5 only
sessionStr['cueWithdrawalPunishYN']     = 0 # only 1 in phase 4-5

allTrials = np.ones(sessionStr['maxTrials'])  # fix: get rid of allTrials later
sessionStr['trialNum']                  = [];

# info for specific trials - need to update this later
# for stages 1-2, this should be [1 3]. For stage 3 and higher, it should be [1:6]
# i.e. no free choice until stage 3
sessionStr['trialLRtype']      = [1, 3, 1, 3, 1, 3, 1, 3] # (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL).
sessionStr['trialLRtype_info'] = '(1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)'

# this is planning for the future, when we will likely want two auditory
# stimuli and two visual stimuli. For now, just leave it as all 3's
sessionStr['trialAVtype']      = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]  # 1 = auditory only, 2 = visual only, 3 = both aud + vis
sessionStr['trialAVtype_info'] = '1 = auditory only, 2 = visual only, 3 = both aud + vis'

#sessionStr.items()

# setting parameters based on training phase
if sessionStr['trainingPhase'] == 1:
	sessionStr['punishForErrorPokeYN']      = 0; # 0 = no, 1 = yes for stage 5 only
	sessionStr['cueWithdrawalPunishYN']     = 0; # only 1 in phase 4-5
	sessionStr['goToPokesLength']           = 60 * 1000;
elif sessionStr['trainingPhase'] == 2:
	sessionStr['punishForErrorPokeYN']      = 0; # 0 = no, 1 = yes for stage 5 only
	sessionStr['cueWithdrawalPunishYN']     = 0; # only 1 in phase 4-5
	sessionStr['goToPokesLength']           = 60 * 1000;
elif sessionStr['trainingPhase'] == 3:
	sessionStr['punishForErrorPokeYN']      = 0; # 0 = no, 1 = yes for stage 5 only
	sessionStr['cueWithdrawalPunishYN']     = 0; # only 1 in phase 4-5
	sessionStr['goToPokesLength']           = stage3_goToPokesLength;
elif sessionStr['trainingPhase'] == 4:
	sessionStr['punishForErrorPokeYN']      = 0; # 0 = no, 1 = yes for stage 5 only
	sessionStr['cueWithdrawalPunishYN']     = 1; # only 1 in phase 4-5
	sessionStr['goToPokesLength']           = 4 * 1000;
elif sessionStr['trainingPhase'] == 5:
	sessionStr['punishForErrorPokeYN']      = 1; # 0 = no, 1 = yes for stage 5 only
	sessionStr['cueWithdrawalPunishYN']     = 1; # only 1 in phase 4-5
	sessionStr['goToPokesLength']           = 4 * 1000;


# just the starting values - they will be updated later
sessionStr['LrewardSize_nL']      = np.ones(1) * 5000; # the starting value, which will be updated over time
sessionStr['RrewardSize_nL']      = np.ones(1) * 5000;
sessionStr['rewardSizeMax_nL']    = np.ones(1) * 8000;
sessionStr['rewardSizeMin_nL']    = np.ones(1) * 2000;
sessionStr['rewardSizeDelta_nL']  = np.ones(1) * 500; # the number of nanoliters to adjust reward size by to prevent 

# cue lengths, etc. - for phases 4 and 5, they are changed below
sessionStr['preCueLength']         = 0 * allTrials; 
sessionStr['cue1Length']           = 100 * allTrials;
sessionStr['cue2Length']           = 100 * allTrials;
sessionStr['interOnsetInterval']   = 0 * allTrials; 
sessionStr['postCueLength']        = 0 * allTrials;

#sessionStr = makeRewardCodes_v5(sessionStr, 1:length(allTrials)); # fix - adding reward codes to the struct
sessionStr['LrewardCode'] = [0, 3, 0, 3, 0, 3, 3]
sessionStr['RrewardCode'] = [3, 0, 3, 0, 3, 0, 3]


#%% initializing boxParams

boxParams = dict()
boxParams['nTrial'] =            sessionStr['startTrialNum']
boxParams['resetTimeYN'] =       0 # setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
boxParams['initPokePunishYN'] =  0 # setting to 1 enables punishment for initpoke during standby
boxParams['cueWithdrawalPunishYN'] = 0 # setting to 1 enables punishment for poke withdrawal during cues

boxParams['WNvolume'] =      50
boxParams['lowCueVolume'] =  120
boxParams['highCueVolume'] = 120
boxParams['buzzerVolume'] =  90

boxParams['trainingPhase'] = 0
boxParams['laserOnCode'] = 0

# these are all in milliseconds
boxParams['readyToGoLength'] =        1000*30
boxParams['punishDelayLength'] =      1000*6
boxParams['preCueLength'] =           10
boxParams['slot1Length'] =             5
boxParams['slot2Length'] =             5
boxParams['slot3Length'] =             5
boxParams['postCueLength'] =          10
boxParams['goToPokesLength'] =        1000*60
boxParams['rewardCollectionLength'] = 1000*5

boxParams['IrewardCode'] =  0
boxParams['LrewardCode'] =  0
boxParams['RrewardCode'] =  0
# boxParams['extra4rewardCode'] =  0
# boxParams['extra5rewardCode'] =  0
# boxParams['extra6rewardCode'] =  0

boxParams['IrewardSize_nL'] =       1000*5
boxParams['LrewardSize_nL'] =       1000*5
boxParams['RrewardSize_nL'] =       1000*5
boxParams['deliveryDuration_ms'] =  1000
boxParams['syringeSize_mL'] =       5

boxParams['cueLED1Brightness'] =       1023
boxParams['cueLED2Brightness'] =       1023
boxParams['cueLED3Brightness'] =       1023
boxParams['cueLED4Brightness'] =       1023

#%% making connection with arduino
try:
    del arduino  # to prevent eror if the connection wasn't closed before
except:
    pass
arduino = serial.Serial('COM5', 115200, timeout=10) # Establish the connection on a specific port
arduino.set_buffer_size(rx_size=1000000, tx_size=1000000)
sleep(1)  # required for connection 
arduino.write(b'calibrationLength;1000\n')

#%% send boxParams to arduino
for i in boxParams:
#    print(bytes(i + ';' + str(boxParams[i]) + '\n', 'utf-8'))
    arduino.write(bytes(i + ';' + str(boxParams[i]) + '\n', 'utf-8'))
    
sleep(1)  # unsure if that's necessary


#%% start loop over trials
nTrial = 1
sessionStr['trialNum'].append(nTrial - 1 + sessionStr['startTrialNum'])

# fix: make cue vectors here 
sessionStr['slot1_vis'] = [1, 2, 3, 1, 2, 3]
sessionStr['slot1_aud'] = [1, 2, 3, 1, 2, 3]
sessionStr['slot2_vis'] = [1, 2, 3, 1, 2, 3]
sessionStr['slot2_aud'] = [1, 2, 3, 1, 2, 3]
sessionStr['slot3_vis'] = [1, 2, 3, 1, 2, 3]
sessionStr['slot3_aud'] = [1, 2, 3, 1, 2, 3]

sessionStr['slot1Length'] = [100, 100, 100, 100]
sessionStr['slot2Length'] = [100, 100, 100, 100]
sessionStr['slot3Length'] = [100, 100, 100, 100]



# make the dict for each trial
trial_dict = dict() # empty python dict that fills only w/parameters that
# are updated in the current trial.

trial_dict['nTrial'] = sessionStr['trialNum'][nTrial-1]
trial_dict['trainingPhase'] = sessionStr['trainingPhase']
trial_dict['goToPokesLength'] = sessionStr['goToPokesLength']

# info about trial type - sent to arduino only so that they get
# saved in text log file
trial_dict['trialLRtype'] = sessionStr['trialLRtype'][nTrial-1]
trial_dict['trialAVtype'] = sessionStr['trialAVtype'][nTrial-1]

# reward info
if sessionStr['trainingPhase'] == 1:
    trial_dict['IrewardCode'] = 1
elif sessionStr['trainingPhase'] == 2:
    trial_dict['IrewardCode'] = 2
elif sessionStr['trainingPhase'] > 2:
    trial_dict['IrewardCode'] = 0


trial_dict['LrewardCode'] = sessionStr['LrewardCode'][nTrial-1]
trial_dict['LrewardSize_nL'] = sessionStr['LrewardSize_nL'][nTrial-1]
trial_dict['RrewardCode'] = sessionStr['RrewardCode'][nTrial-1]
trial_dict['RrewardSize_nL'] = sessionStr['RrewardSize_nL'][nTrial-1]

# cue info
trial_dict['slot1_vis'] = sessionStr['slot1_vis'][nTrial-1]
trial_dict['slot1_aud'] = sessionStr['slot1_aud'][nTrial-1]
trial_dict['slot2_vis'] = sessionStr['slot2_vis'][nTrial-1]
trial_dict['slot2_aud'] = sessionStr['slot2_aud'][nTrial-1]
trial_dict['slot3_vis'] = sessionStr['slot3_vis'][nTrial-1]
trial_dict['slot3_aud'] = sessionStr['slot3_aud'][nTrial-1]

trial_dict['cueWithdrawalPunishYN'] = sessionStr['cueWithdrawalPunishYN']
trial_dict['preCueLength'] = sessionStr['preCueLength'][nTrial-1]
trial_dict['slot1Length'] = sessionStr['slot1Length'][nTrial-1]
trial_dict['slot2Length'] = sessionStr['slot2Length'][nTrial-1]
trial_dict['slot3Length'] = sessionStr['slot3Length'][nTrial-1]
trial_dict['postCueLength'] = sessionStr['postCueLength'][nTrial-1]

# send boxParams to arduino
for i in trial_dict:
#    print(bytes(i + ';' + str(boxParams[i]) + '\n', 'utf-8'))
    arduino.write(bytes(i + ';' + str(trial_dict[i]) + '\n', 'utf-8'))
    
sleep(1)    


arduino.write(bytes('startTrialYN;1', 'utf-8'))











arduino.readline()



arduino.close()

