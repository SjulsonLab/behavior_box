# importing stuffimport timeimport datetime
import time
import datetime
import os, sys
import importlib   # for reloading modules
import serial      # for communication with arduino
import collections # for ordered dicts (session_info)
import pysistence  # for immutable dict (mouse_info)
import warnings
import box_utils   # box_utils.py must be in the same folder as this file
import socket
import random
import traceback
import colorama
from colorama import Fore, Style
from sys import platform
import numpy as np



# defining immutable mouse dict (once defined for a mouse, this should never change)
mouse_info = pysistence.make_dict({'mouseName': 'test',
                 'requiredVersion': 8,
                 'leftVisCue': 3,
                 'rightVisCue': 0,
                 'leftAudCue': 0,
                 'rightAudCue': 3})

# Information for this session (the user should edit this each session)
session_info                              = collections.OrderedDict()
session_info['mouseName']                 = mouse_info['mouseName']
session_info['trainingPhase']             = 4
session_info['weight']                    = 32.18
session_info['date']                      = datetime.datetime.now().strftime("%Y%m%d")
session_info['time']                      = datetime.datetime.now().strftime('%H%M%S')
session_info['basename']                  = mouse_info['mouseName'] + '_' + session_info['date'] + '_' + session_info['time']
session_info['box_number']                = 1      # put the number of the behavior box here
session_info['computer_name']             = socket.gethostname()
session_info['correctBias']               = 1
session_info['blocks_reward']             = 1      #flag to do blocks of reward, i.e., increase reward on the left and decrease on the right for a certain number of trials
trials_since_block                        = 1      #number of trials since block change
change_point                              = 0      #when to change the block of different rewards
resetTimeYN                               = 1      # whether or not to restart arduino timer at beginning of session

box_utils.set_COM_port(session_info)                # looking up the COM port in the list in box_utils.py

# parameters for training in stages 3-4
phase3_go_to_pokes_length                      = 30 * 1000  # goal is to reduce to 4000 ms
session_info['phase4_num_rewards_to_advance']  = 10
session_info['phase4_fake_rewards']            = 0

# other parameters
session_info['maxSessionLength_min']      = 60     # in minutes
session_info['maxTrials']                 = 1000   # program terminates when either maxSessionLength_min or maxTrials is reached
session_info['maxRewards']                = 1000    # program also terminates if maxRewards is reached
session_info['interTrialInterval_mean']   = 0      # number of extra seconds between trials
session_info['interTrialInterval_SD']     = 0    # standard deviation of seconds between trials
session_info['punishForErrorPokeYN']      = 0      # 0 = no, 1 = yes for stage 5 only
session_info['cueWithdrawalPunishYN']     = 0      # only 1 in phase 4-5
session_info['initPokePunishYN']          = 0      # whether to punish for init poke between trials
nTrial                                    = 1      # the number of the first trial
session_info['nTrial']                    = []     # just leave this blank


# initializing trial L/R parameters, will set them later
session_info['trialLRtype']               = [1,3] # (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL).
session_info['trialLRtype_info']          = '(1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)'
session_info['LrewardCode']               = [] # will be set automatically later
session_info['RrewardCode']               = []
session_info['IrewardCode']               = []

# this is planning for the future, when we will likely want two auditory
# stimuli and two visual stimuli. For now, just leave it as all 3's
session_info['trialAVtype']               = [3]  # 1 = auditory only, 2 = visual only, 3 = both aud + vis
session_info['trialAVtype_info']          = '1 = auditory only, 2 = visual only, 3 = both aud + vis'

# will use this later, when we do optogenetic manipulation
session_info['laserOnCode']            = [0]

# reward parameters for first trial
session_info['LrewardSize_nL']         = [5000] # the starting value, which will be updated over time
session_info['RrewardSize_nL']         = [5000]
session_info['IrewardSize_nL']         = [0000]
session_info['L_nL_mean']              = [3000]
session_info['R_nL_mean']              = [3000]
session_info['rewardSizeMax_nL']       = [3000]
session_info['rewardSizeMin_nL']       = [500]
session_info['rewardSizeDelta_nL']     = [500] # the number of nanoliters to adjust reward size by 
session_info['deliveryDuration_ms']    = 250
session_info['syringeSize_mL']         = 5
session_info['rand_reward_size']       = 1

# time intervals
session_info['readyToGoLength']        = 1000*10*60
session_info['punishDelayLength']      = 1000*4
session_info['goToPokesLength']        = 1000*60
session_info['rewardCollectionLength'] = 1 #000*5

# cue lengths, etc. - for phases 4 and 5, they are changed below
session_info['preCueLength']           = 100
session_info['cue1Length']             = [100]
session_info['cue2Length']             = [100]
session_info['interOnsetInterval']     = [0]
session_info['postCueLength']          = 0
session_info['increase_hold_time' ]    = 1;

# cue volume and brightness
session_info['WNvolume']               = 50     # volumes are 0-255
session_info['lowCueVolume']           = 120
session_info['highCueVolume']          = 120
session_info['buzzerVolume']           = 90
session_info['cueLED1Brightness']      = 1023   # brightness is 0-1023
session_info['cueLED2Brightness']      = 1023
session_info['cueLED3Brightness']      = 1023
session_info['cueLED4Brightness']      = 1023

# setting parameters based on training phase
if session_info['trainingPhase'] == 1:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 0 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 60 * 1000
elif session_info['trainingPhase'] == 2:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 60 * 1000
elif session_info['trainingPhase'] == 3:
	session_info['punishForErrorPokeYN']      = 0 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = phase3_go_to_pokes_length
elif session_info['trainingPhase'] == 4:
	session_info['punishForErrorPokeYN']      = 1 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 4 * 1000
elif session_info['trainingPhase'] == 5:
	session_info['punishForErrorPokeYN']      = 1 # 0 = no, 1 = yes for stage 5 only
	session_info['cueWithdrawalPunishYN']     = 1 # only 1 in phase 4-5
	session_info['goToPokesLength']           = 4 * 1000
    
# initializing the cue/slot parameters
session_info['slot1_vis'] = []
session_info['slot1_aud'] = []
session_info['slot2_vis'] = []
session_info['slot2_aud'] = []
session_info['slot3_vis'] = []
session_info['slot3_aud'] = []
session_info['slot1Length'] = []
session_info['slot2Length'] = []
session_info['slot3Length'] = []

if session_info['trainingPhase'] == 5:
    box_utils.append_cue_slot_durations(session_info, 0)

# # figure out the COM port
# basedir  = 'C:\\Users\\lukes\\Desktop\\temp'
# COM_port = 'COM5'  # fix: update this later

# make directory to store logfile in
os.chdir(session_info['basedir'])
if os.path.isdir(session_info['basename']):
    warnings.warn('Data directory with the current date and time already exists. Proceeding anyway...')
else:
    os.mkdir(session_info['basename'])
os.chdir(session_info['basename'])

# making connection with arduino, checking that required version is correct
connection_speed = 115200    # tried 230400, and it didn't work
try:
    del arduino
except:
    pass
arduino = serial.Serial(session_info['COM_port'], connection_speed, timeout=10) # Establish the connection on a specific port
if platform == "win32":
    arduino.set_buffer_size(rx_size=10000000, tx_size=10000000)

time.sleep(1)  # required for connection to complete before transmitting
# arduino.write(b'calibrationLength;1000\n')  # for testing

# verify the arduino is running the correct version of the box code
arduino.flushInput()
arduino.write(bytes('checkVersion',encoding = 'utf-8'))
ver = int(arduino.readline())
if ver != mouse_info['requiredVersion']:
    raise Exception('This requires the arduino to run version ' + str(mouse_info['requiredVersion']) + \
                    ', but it is running ver ' + str(ver))
del ver

# initializing default box_params and sending to arduino
box_utils.set_box_defaults(arduino)

# create GUI to ask user to start trial
box_utils.ask_if_ready(session_info)

# start camera
box_utils.send_dict_to_arduino({'cameraRecordingYN' : 1}, arduino)


# loop over trials begins here
try:
    start_time = time.time()
    exit_loop = False
    total_rewards = 0
    reward_inRow  = 0
    deltaGain     = 0
    kDelta        = 0
    box_utils.send_dict_to_arduino({'resetTimeYN' : resetTimeYN}, arduino)

    while exit_loop == False:


        ## these get updated every trial
        # setting trial number
        session_info['nTrial'].append(nTrial)
        # for stages 1-2, this should be [1 3]. For stage 3 and higher, it should be [1:6]
        # i.e. no free choice until stage 3
        box_utils.append_random_LR(session_info)
        # set reward codes for this trial
        box_utils.append_reward_code(session_info)
        # set cue/slot identity codes for this trial
        box_utils.append_cue_codes(session_info, mouse_info)

        #if session_info['trainingPhase'] == 4:
            # set cue/slot duration cotes for this trial
           # box_utils.append_cue_slot_durations(session_info, total_rewards)

        if(session_info['trainingPhase']>=2 and session_info['correctBias'] == 1):
            box_utils.correctBias(session_info,nTrial)
        # fix: append new reward size here if it's going to 
        if session_info['blocks_reward']:
            if (trials_since_block>change_point):
                box_utils.reward_blocks(session_info,nTrial)
                change_point = int(np.random.uniform(50,75,1))
                trials_since_block = 0
                
        if session_info['rand_reward_size']:
            box_utils.assign_random_reward(session_info)
            
        if nTrial != 1:
            if (deltaGain == kDelta) and (reward_inRow<=5):
                reward_inRow += 1
            elif (deltaGain != kDelta):
                kDelta = deltaGain
                reward_inRow = 0
            elif (deltaGain == kDelta) and (reward_inRow>5):
                reward_inRow = 0
        

        # send session_info to arduino
        box_utils.send_dict_to_arduino(session_info, arduino)

        # open log file
        logfile = open(session_info['basename'] + '.txt', 'a+')

        # start the trial
        arduino.write(bytes('startTrialYN;1',encoding = 'utf-8'))


        # loop to log info from arduino while trial runs
        Astr = str('')  # declare temp string
        while not Astr.endswith('Standby;0'):
          if arduino.in_waiting > 0:
            time.sleep(0.010) # to prevent readline() from being called before the entire string is written
            Astr = arduino.readline().decode('utf-8').rstrip()
            if Astr.find('letTheAnimalDrink') >= 0: # meaning a reward was collected
                total_rewards += 1
                print(Style.BRIGHT + Astr + '\nTotal Rewards: ' + str(total_rewards) + Style.RESET_ALL)
                
            else:
                print(Astr)
                


            logfile.write(Astr + '\n')

          else:
            time.sleep(0.050)

        del Astr
        
        logfile.close()
        print(Fore.GREEN + Style.BRIGHT + 'Trial completed' + Style.RESET_ALL)
        nTrial += 1
        trials_since_block += 1
        deltaGain = nTrial - total_rewards
        
        
        
        
        
        # evaluate whether or not to exit the loop
        if time.time() - start_time > session_info['maxSessionLength_min']*60:
            print('Session reached maximum duration. Exiting.')
            exit_loop = True
        elif nTrial > session_info['maxTrials']:
            print('Maximum trial number reached. Exiting.')
            exit_loop = True
        elif total_rewards > session_info['maxRewards']:  # fix: have to put this in
            print('Maximum number of rewards reached. Exiting.')
            exit_loop = True

        # optionally add random extra ITI
        time.sleep(random.gauss(session_info['interTrialInterval_mean'], session_info['interTrialInterval_SD']))
        if session_info['increase_hold_time']:
            #print(Style.BRIGHT +'\nRewards in a row: ' + str(reward_inRow) + Style.RESET_ALL)
            if reward_inRow > 5:
                box_utils.increase_hold_time(session_info)


    # end of loop



    # stop camera
    box_utils.send_dict_to_arduino({'cameraRecordingYN': 0}, arduino)

    # save dicts to disk
    box_utils.save_mat_file('mouse_info.mat', mouse_info, 'mouse_info')
    box_utils.save_mat_file('session_info.mat', session_info, 'session_info')

    # close arduino
    time.sleep(1)
    arduino.close()
    del arduino

except (KeyboardInterrupt, SystemExit):
    print(Fore.RED + Style.BRIGHT + 'Ctrl-C detected. Stopping at end of trial (will wait up to 60 seconds).' + Style.RESET_ALL)
    if not logfile.closed:
        t = time.time()
        Astr = str('')  # declare temp string
        while (not Astr.endswith('Standby;0')) and time.time()-t < 60:
          if arduino.in_waiting > 0:
            time.sleep(0.010) # to prevent readline() from being called before the entire string is written
            Astr = arduino.readline().decode('utf-8').rstrip()
            print(Astr)
            logfile.write(Astr + '\n')

          else:
            time.sleep(0.050)
        logfile.close()
    if not arduino.closed:
        arduino.close()
        del arduino
    # save dicts to disk
    box_utils.save_mat_file('mouse_info.mat', mouse_info, 'mouse_info')
    box_utils.save_mat_file('session_info.mat', session_info, 'session_info')


# error handling
except Exception as ex:

    if not logfile.closed:
        logfile.close()
    if not arduino.closed:
        del arduino

    # Get current system exception
    ex_type, ex_value, ex_traceback = sys.exc_info()

    # Extract unformatter stack traces as tuples
    trace_back = traceback.extract_tb(ex_traceback)

    # Format stacktrace
    stack_trace = list()

    for trace in trace_back:
        stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))

    print("Exception type : %s " % ex_type.__name__)
    print("Exception message : %s" %ex_value)
    print("Stack trace : %s" %stack_trace)
    # save dicts to disk
    box_utils.save_mat_file('mouse_info.mat', mouse_info, 'mouse_info')
    box_utils.save_mat_file('session_info.mat', session_info, 'session_info')


