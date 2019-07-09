def set_COM_port(session_info):

# this is where we keep track of the COM ports and base data directories for the different computers    
    if session_info['computer_name'].lower() == 'Luke-HP-laptop'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'C:\\Users\\lukes\\Desktop\\temp'
        session_info['COM_port'] = 'COM5'
    elif session_info['computer_name'].lower() == 'bumbrlik01'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'G:\\My Drive\\lab-shared\\lab_projects\\rewardPrediction\\behavior'
        session_info['COM_port'] = 'COM13'
    elif session_info['computer_name'].lower() == 'bumbrlik02'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'G:\\My Drive\\lab-shared\\lab_projects\\rewardPrediction\\behavior'
        session_info['COM_port'] = 'COM13'
    elif session_info['computer_name'].lower() == 'bumbrlik03'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'G:\\My Drive\\lab-shared\\lab_projects\\rewardPrediction\\behavior'
        session_info['COM_port'] = 'COM4'
    elif session_info['computer_name'].lower() == 'bumbrlik03'.lower() \
        and session_info['box_number'] == 2:
        session_info['basedir'] = 'G:\\My Drive\\lab-shared\\lab_projects\\rewardPrediction\\behavior'
        session_info['COM_port'] = 'COM13'
    elif session_info['computer_name'].lower() == 'DESKTOP-RE9G846'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'C:\\Users\\lab\\Desktop\\temp'
        session_info['COM_port'] = 'COM11'
    elif session_info['computer_name'].lower() == 'fenrir'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = '//media//elie//SSD//testBehData'
        session_info['COM_port'] = '/dev/ttyACM1'
    elif session_info['computer_name'].lower() == 'DESKTOP-0K6KLC7'.lower() \
        and session_info['box_number'] == 1:
        session_info['basedir'] = 'C:\\Users\\fermi\\Data\\testBehavior'
        session_info['COM_port'] = 'COM3'
    else: 
        raise Exception('Correct combination of computer_name and box_number not found. Please see box_utils.py')

def append_cue_codes(session_info, mouse_info):

    # function session_info = makeCue_v5(session_info, mouse_info, trialNums)
    #
    # Function to generate cue numbers to send to the arduino. The session_info
    # must have fields:
    #
    # trialLRtype (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)
    # trialAVtype (1 = aud only, 2 = vis only, 3 = aud+vis)
    # cue1Length
    # cue2Length
    # interOnsetInterval (the time between onset of cue 1 and cue2)
    #
    # the mouse_info must have the fields:
    #
    # leftVisCue (0 = nothing, 1 = LEDs 1+2, 2 = LEDs 3+4, 3 = LEDs 1-4)
    # leftAudCue (0 = nothing, 1 = low tone, 2 = high tone, 3 = buzzer, 4 = white noise)
    # rightVisCue
    # rightAudCue
    #
    # The fields added to session_info are: 
    # slot1_vis, slot2_vis, slot3_vis, slot1_aud, slot2_aud, slot3_aud  - to give to arduino
    # slot1Length, slot2Length, slot3Length  - also to give to arduino
    #
    # Luke Sjulson, 2018-10-19
    #
    # to fix: the numbering for the trialNums doesn't work correctly if the numbers
    # don't start with 1 and continue sequentially

    # for testing
    # clear all
    # clc

    # # # info from mouse struct
    # mouse_info = dict()
    # session_info = dict()
    # mouse_info['leftVisCue']  = 1
    # mouse_info['leftAudCue']  = 0
    # mouse_info['rightVisCue'] = 0
    # mouse_info['rightAudCue'] = 3
     
    # trialNums = [1, 2, 3, 4, 5, 6]

    # # info about trial types
    # session_info['trialLRtype']  = [1, 2, 3, 4, 5, 6] # can be 1-6
     
    # session_info['trialAVtype']  = [3, 2, 1, 2, 1, 3, 1, 2, 1, 1, 3] # 1 = auditory only, 2 = visual only, 3 = both aud + vis
    # #session_info['trialAVtype']        = [3, 3, 3, 3, 3, 3] # 1 = auditory only, 2 = visual only, 3 = both aud + vis
    # session_info['cue1Length']         = [100, 100, 100, 100, 100, 100]
    # session_info['cue2Length']         = [100, 100, 100, 100, 100, 100]
    # session_info['interOnsetInterval'] = [0, 10, 20, 30, 40, 50] # in stage 4, the interOnsetInterval increases gradually


    ####################################################################
    #&& start of actual function
    ####################################################################
    
    import warnings

    slot1_vis = 0
    slot1_aud = 0
    slot2_vis = 0
    slot2_aud = 0
    slot3_vis = 0
    slot3_aud = 0
    
    trialLRtype = session_info['trialLRtype'][-1]
    trialAVtype = session_info['trialAVtype'][-1]
    
    ## calculating lengths of slots
    slot1Length = min(session_info['cue1Length'][-1], session_info['interOnsetInterval'][-1])
    tempSlot = session_info['interOnsetInterval'][-1] - session_info['cue1Length'][-1]
    slot2Length = abs(tempSlot)
    
    if tempSlot < 0: # the two stimuli are overlapping
        slot2StimYN = 1 # stimuli on for slot 2
    else: # the stimuli are not overlapping
        slot2StimYN = 0 # stimuli off for slot 2
        tempSlot = 0
    
    slot3Length = session_info['cue2Length'][-1] + tempSlot
    
    if slot1Length<0 or slot2Length<0 or slot3Length<0:
        print('You attempted to generate a cue duration less than zero. No stimulus will be given on this trial.')
        slot1Length = 0
        slot2Length = 0
        slot3Length = 0
        
    ## figuring out which stimuli should be turned on in which slots
    
    if trialLRtype==1 or trialLRtype==5: # if left cue is played in first slot
        # if aud cue is played
        if trialAVtype==1 or trialAVtype==3:
            slot1_aud = mouse_info['leftAudCue']
            if slot2StimYN==1: # if it's played in the second slot
                slot2_aud = mouse_info['leftAudCue']

        # if vis cue is played
        if trialAVtype==2 or trialAVtype==3:
            slot1_vis = mouse_info['leftVisCue']
            if slot2StimYN==1: # if it's played in the second slot
                slot2_vis = mouse_info['leftVisCue']

    if trialLRtype==3 or trialLRtype==6: # if right cue is played in first slot
        # if aud cue is played
        if trialAVtype==1 or trialAVtype==3:
            slot1_aud = mouse_info['rightAudCue']
            if slot2StimYN==1: # if it's played in the second slot
                slot2_aud = mouse_info['rightAudCue']

        # if vis cue is played
        if trialAVtype==2 or trialAVtype==3:
            slot1_vis = mouse_info['rightVisCue']
            if slot2StimYN==1: # if it's played in the second slot
                slot2_vis = mouse_info['rightVisCue']

    if trialLRtype==2 or trialLRtype==6: # if left cue is played in third slot
        # if aud cue is played
        if trialAVtype==1 or trialAVtype==3:
            slot3_aud = mouse_info['leftAudCue']
            if slot2StimYN==1: # if it's played in the second slot
                if mouse_info['leftAudCue'] != 0:
                    if slot2_aud==0:
                        slot2_aud = mouse_info['leftAudCue']
                    else:
                        warnings.warn('Attempting to play two contradictory auditory stimuli simultaneously')

        # if vis cue is played
        if trialAVtype==2 or trialAVtype==3:
            slot3_vis = mouse_info['leftVisCue']
            if slot2StimYN==1: # if it's played in the second slot
                if mouse_info['leftVisCue'] != 0:
                    if slot2_vis==0:
                        slot2_vis = mouse_info['leftVisCue']
                    else:
                        warnings.warn('Attempting to play two contradictory visual stimuli simultaneously')

    if trialLRtype==4 or trialLRtype==5: # if right cue is played in third slot
        # if aud cue is played
        if trialAVtype==1 or trialAVtype==3:
            slot3_aud = mouse_info['rightAudCue']
            if slot2StimYN==1: # if it's played in the second slot
                if mouse_info['rightAudCue'] != 0:
                    if slot2_aud==0:
                        slot2_aud = mouse_info['rightAudCue']
                    else:
                        warnings.warn('Attempting to play two contradictory auditory stimuli simultaneously')
                    
                
        # if vis cue is played
        if trialAVtype==2 or trialAVtype==3:
            slot3_vis = mouse_info['rightVisCue']
            if slot2StimYN==1: # if it's played in the second slot
                if mouse_info['rightVisCue'] != 0:
                    if slot2_vis==0:
                        slot2_vis = mouse_info['rightVisCue']
                    else:
                        warnings.warn('Attempting to play two contradictory visual stimuli simultaneously')
                    
    ## append each new entry to the list
    session_info['slot1Length'].append(slot1Length)
    session_info['slot2Length'].append(slot2Length)
    session_info['slot3Length'].append(slot3Length)
    
    session_info['slot1_aud'].append(slot1_aud)
    session_info['slot2_aud'].append(slot2_aud)
    session_info['slot3_aud'].append(slot3_aud)
    session_info['slot1_vis'].append(slot1_vis)
    session_info['slot2_vis'].append(slot2_vis)
    session_info['slot3_vis'].append(slot3_vis)
        



def set_box_defaults(arduino):
    
    import time
    box_params = dict()
    box_params['nTrial'] =                0
    box_params['resetTimeYN'] =           0 # setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
    box_params['initPokePunishYN'] =      0 # setting to 1 enables punishment for initpoke during standby
    box_params['cueWithdrawalPunishYN'] = 0 # setting to 1 enables punishment for poke withdrawal during cues

    box_params['WNvolume'] =      50
    box_params['lowCueVolume'] =  120
    box_params['highCueVolume'] = 120
    box_params['buzzerVolume'] =  90

    box_params['trainingPhase'] = 0
    box_params['laserOnCode'] = 0

    # these are all in milliseconds
    box_params['readyToGoLength'] =        1000*30
    box_params['punishDelayLength'] =      1000*6
    box_params['preCueLength'] =           10
    box_params['slot1Length'] =             5
    box_params['slot2Length'] =             5
    box_params['slot3Length'] =             5
    box_params['postCueLength'] =          10
    box_params['goToPokesLength'] =        1000*60
    box_params['rewardCollectionLength'] = 1000*5

    # box_params['IrewardCode'] =  0
    box_params['LrewardCode'] =  0
    box_params['RrewardCode'] =  0
    # box_params['extra4rewardCode'] =  0
    # box_params['extra5rewardCode'] =  0
    # box_params['extra6rewardCode'] =  0

    # box_params['IrewardSize_nL'] =       1000*5
    box_params['LrewardSize_nL'] =       1000*5
    box_params['RrewardSize_nL'] =       1000*5
    box_params['deliveryDuration_ms'] =  1000
    box_params['syringeSize_mL'] =       5

    box_params['cueLED1Brightness'] =       1023
    box_params['cueLED2Brightness'] =       1023
    box_params['cueLED3Brightness'] =       1023
    box_params['cueLED4Brightness'] =       1023

    # send box_params to arduino
    for i in box_params:
    #    print(bytes(i + ';' + str(box_params[i]) + '\n', 'utf-8'))
        arduino.write(bytes(i + ';' + str(box_params[i]) + '\n',encoding ='utf-8'))
        time.sleep(0.010) # this is necessary to prevent buffer overrun



def send_dict_to_arduino(send_this, arduino):
    import warnings
    import time
    for i in send_this:
        if isinstance(send_this[i], int): # if it's an int, just send it
            # print(bytes(i + ';' + str(send_this[i]) + '\n', 'utf-8'))
            arduino.write(bytes(i + ';' + str(send_this[i]) + '\n',encoding = 'utf-8'))
        elif isinstance(send_this[i], list): # if it's a list, send the last entry
            try:
                #print(bytes(i + ';' + str(send_this[i][-1]) + '\n', 'utf-8'))
                arduino.write(bytes(i + ';' + str(send_this[i][-1]) + '\n', encoding = 'utf-8'))
            except:
                warnings.warn('Warning: ' + i + ' did not load')
        elif isinstance(send_this[i], str): # if it's a string, do nothing
            pass
        else: 
            warnings.warn(i + 'not recognized as acceptable variable type')
        time.sleep(0.010) # this is necessary to prevent buffer overrun


def append_reward_code(session_info):
    # this function takes session_info and appends an extra entry onto the end of
    # LrewardCode and RrewardCode, based on which type of trial it is.

    if session_info['punishForErrorPokeYN'] == 0:  # no punishment for incorrect poke
        wrong_poke_code = 0
    else: 
        wrong_poke_code = -1  # -1 means punishment for incorrect poke
        
#    if session_info['trainingPhase'] in [1, 2]:
#        Rnum = 3 # reward code of 3 for phases 1 or 2 - reward at end of cue delivery
#    else:
    Rnum = 4
        
    # set code for Left poke
    if session_info['trialLRtype'][-1] in [1, 2, 5, 6]:
        session_info['LrewardCode'].append(Rnum)
    else: 
        session_info['LrewardCode'].append(wrong_poke_code)  

    # set code for right poke
    if session_info['trialLRtype'][-1] in [3, 4, 5, 6]:
        session_info['RrewardCode'].append(Rnum)
    else:
        session_info['RrewardCode'].append(wrong_poke_code)

    # set code for init poke
    if session_info['trainingPhase'] in [2]:
        session_info['IrewardCode'].append(2)
    else:
        session_info['IrewardCode'].append(0)

def append_random_LR(session_info):
    import random

    if session_info['trainingPhase'] in [1, 2]:
        options = [1, 3]
    elif session_info['trainingPhase'] in [3, 4, 5, 6]:
        options = [1, 2, 3, 4, 5, 6]
    elif session_info['trainingPhase'] in [201]:
        options = [201]
    else: 
        warnings.warn('Incorrect training phase')
        options = [1]
    session_info['trialLRtype'].append(random.choice(options))


def ask_if_ready(session_info):
    import time
    import tkinter
    from tkinter import Tk
    from tkinter import Toplevel
    from tkinter import messagebox
    root = Tk()
    texto = Toplevel(root)

    ready_to_go = False
    while ready_to_go == False:
        time.sleep(0.1)
        ready_to_go = messagebox.askokcancel(session_info['mouseName'] + ', Phase ' + str(session_info['trainingPhase']), \
                               'Start camera and recordings now, then hit OK to start the trials', default='cancel', master=texto)
        root.update()
    root.destroy()


def stop_dialog(session_info):
    import time
    import tkinter
    from tkinter import Tk
    from tkinter import Toplevel
    from tkinter import messagebox
    root = Tk()
    texto = Toplevel(root)
    ready_to_go = messagebox.askokcancel(session_info['mouseName'] + ', Phase ' + str(session_info['trainingPhase']), \
                'Start camera and recordings now, then hit OK to start the trials', default='cancel', master=texto)
    #root.update()
    #return root

def save_mat_file(filename, dict_to_save, struct_name):
    import scipy.io 
    scipy.io.savemat(filename, {struct_name: dict_to_save})


# def check_keyboard(keyqueue):
#     import msvcrt

#         x = msvcrt.getch()
#         keyqueue.append(x)
#         keyqueue.pop(0)

#         print('keyqueue is: ' + str(keyqueue))
#         if keyqueue[0] == keyqueue[1] == keyqueue[2] == keyqueue[3] == keyqueue[4] == 'x':
#             exit = 1
#         else: 
#             exit = 0
#         return exit
#             


def append_cue_slot_durations(session_info, total_rewards):
    import colorama
    from colorama import Fore, Style

    if session_info['trainingPhase'] == 4:
        R = session_info['phase4_num_rewards_to_advance']
        if (total_rewards + session_info['phase4_fake_rewards']) < R:
            # no extra delays
            session_info['preCueLength'].append(0)
            session_info['postCueLength'].append(0)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >1*R and (total_rewards + session_info['phase4_fake_rewards']) <= 2*R:
            # add precue and postcue 25
            session_info['preCueLength'].append(25)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >2*R and (total_rewards + session_info['phase4_fake_rewards']) <= 3*R:
            # precue = 35
            session_info['preCueLength'].append(35)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >3*R and (total_rewards + session_info['phase4_fake_rewards']) <= 4*R:
            # precue = 45
            session_info['preCueLength'].append(45)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >4*R and (total_rewards + session_info['phase4_fake_rewards']) <= 5*R:
            # precue = 55
            session_info['preCueLength'].append(55)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >5*R and (total_rewards + session_info['phase4_fake_rewards']) <= 6*R:
            # precue = 65
            session_info['preCueLength'].append(65)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >6*R and (total_rewards + session_info['phase4_fake_rewards']) <= 7*R:
            # precue = 75
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(0)    
        elif (total_rewards + session_info['phase4_fake_rewards']) >7*R and (total_rewards + session_info['phase4_fake_rewards']) <= 8*R:
            # IOI = 15
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(15)
        elif (total_rewards + session_info['phase4_fake_rewards']) >8*R and (total_rewards + session_info['phase4_fake_rewards']) <= 9*R:
            # IOI = 25
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(25)
        elif (total_rewards + session_info['phase4_fake_rewards']) >9*R and (total_rewards + session_info['phase4_fake_rewards']) <= 10*R:
            # IOI = 35
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(35)
        elif (total_rewards + session_info['phase4_fake_rewards']) >10*R and (total_rewards + session_info['phase4_fake_rewards']) <= 11*R:
            # IOI = 45
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(45)
        elif (total_rewards + session_info['phase4_fake_rewards']) >11*R and (total_rewards + session_info['phase4_fake_rewards']) <= 12*R:
            # IOI = 55
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(55)
        elif (total_rewards + session_info['phase4_fake_rewards']) >12*R and (total_rewards + session_info['phase4_fake_rewards']) <= 13*R:
            # IOI = 65
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(65)
        elif (total_rewards + session_info['phase4_fake_rewards']) >13*R and (total_rewards + session_info['phase4_fake_rewards']) <= 14*R:
            # IOI = 75
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(75)
        elif (total_rewards + session_info['phase4_fake_rewards']) >14*R and (total_rewards + session_info['phase4_fake_rewards']) <= 15*R:
            # IOI = 85
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(85)
        elif (total_rewards + session_info['phase4_fake_rewards']) >15*R and (total_rewards + session_info['phase4_fake_rewards']) <= 16*R:
            # IOI = 95
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(95)
        elif (total_rewards + session_info['phase4_fake_rewards']) >16*R and (total_rewards + session_info['phase4_fake_rewards']) <= 17*R:
            # IOI = 105
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(105)
        elif (total_rewards + session_info['phase4_fake_rewards']) >17*R and (total_rewards + session_info['phase4_fake_rewards']) <= 18*R:
            # IOI = 115
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(115)
        elif (total_rewards + session_info['phase4_fake_rewards']) >18*R:
            # IOI = 125
            session_info['preCueLength'].append(75)
            session_info['postCueLength'].append(25)
            session_info['interOnsetInterval'].append(125)

        
        # display status for phase 4
        print(Fore.MAGENTA + Style.BRIGHT + 'Animal has ' + str(total_rewards) + ' real rewards and ' + str(session_info['phase4_fake_rewards']) + ' fake ones. precue = ' + \
        str(session_info['preCueLength'][-1]) + ', postcue = ' + str(session_info['postCueLength'][-1]) + \
        ', IOI = ' + str(session_info['interOnsetInterval'][-1]) + Style.RESET_ALL)
        
    elif session_info['trainingPhase'] == 5:
        session_info['preCueLength'].append(75)
        session_info['postCueLength'].append(25)
        session_info['interOnsetInterval'].append(125)
    else:
        raise Exception('session_info.trainingPhase needs to be 4 or 5 to use this function')


def getEventTimes(textString,fname):
    import numpy as np    
    # This function searches for textString in the logfile called fname.
    # It then returns the first column (which is the timestamp for
    # behavior box log files). 
    # based on getEventTimes LSjulson made on Matlab
    fid = open(fname,'r');
    fiLines = fid.readlines();
    fid.close()
    
    nLin = len(fiLines)
    c = 0;
    T = 0;
    for idx in range(0,nLin):
        tempLine = fiLines[idx];
        if textString in tempLine:
            if c == 0:
                aux = tempLine.index(';');
                T = int(tempLine[0:aux]);
                c += 1;
            else:
                aux = tempLine.index(';');
                T = np.append(T,int(tempLine[0:aux]));
    return T;

def correctBias(session_info,nTrial):
    import numpy as np
    if (nTrial >= 2):
            sideRewardCollected = np.array(getEventTimes(str(nTrial-1)+';letTheAnimalDrink',session_info['basename']+'.txt'))
            
            if (sideRewardCollected.size == 1):
                trialStart_ts = np.array(getEventTimes(str(nTrial-1)+';TrialStarted_ms',session_info['basename']+'.txt'))
                tempL = np.array(getEventTimes(str(nTrial-1)+';leftPokeEntry',session_info['basename']+'.txt'))
                tempR = np.array(getEventTimes(str(nTrial-1)+';rightPokeEntry',session_info['basename']+'.txt'))
                
        
                #selecting pokes after trialStart
                leftPokes = tempL[tempL>trialStart_ts]
                rightPokes = tempR[tempR>trialStart_ts]
                
                #Was it a left (1) or right (3) poke type
                if (rightPokes.size == 0):
                    firstPokeType = 1
                elif (leftPokes.size == 0):
                    firstPokeType = 3
                elif (leftPokes[0] < rightPokes[0]):
                    firstPokeType = 1
                elif (leftPokes[0] > rightPokes[0]):
                    firstPokeType = 3
                
                #comparing trial types with first poke
                if (session_info['trialLRtype'][nTrial-2] == 1 and firstPokeType == 3):
                   session_info['trialLRtype'][nTrial-1] = 1;
                   session_info['LrewardCode'][nTrial-1] = session_info['LrewardCode'][nTrial-2];
                   session_info['RrewardCode'][nTrial-1] = session_info['RrewardCode'][nTrial-2];
                   session_info['slot1_vis'][nTrial-1] = session_info['slot1_vis'][nTrial-2];
                   session_info['slot1_aud'][nTrial-1] = session_info['slot1_aud'][nTrial-2];
                   session_info['slot2_vis'][nTrial-1] = session_info['slot2_vis'][nTrial-2];
                   session_info['slot2_aud'][nTrial-1] = session_info['slot2_aud'][nTrial-2];
                   session_info['slot3_vis'][nTrial-1] = session_info['slot3_vis'][nTrial-2];
                   session_info['slot3_aud'][nTrial-1] = session_info['slot3_aud'][nTrial-2];
                   session_info['slot1Length'][nTrial-1] = session_info['slot1Length'][nTrial-2];
                   session_info['slot2Length'][nTrial-1] = session_info['slot2Length'][nTrial-2];
                   session_info['slot3Length'][nTrial-1] = session_info['slot3Length'][nTrial-2];
                elif (session_info['trialLRtype'][nTrial-2] == 3 and firstPokeType == 1):
                   session_info['trialLRtype'][nTrial-1] = 3;
                   session_info['LrewardCode'][nTrial-1] = session_info['LrewardCode'][nTrial-2];
                   session_info['RrewardCode'][nTrial-1] = session_info['RrewardCode'][nTrial-2];
                   session_info['slot1_vis'][nTrial-1] = session_info['slot1_vis'][nTrial-2];
                   session_info['slot1_aud'][nTrial-1] = session_info['slot1_aud'][nTrial-2];
                   session_info['slot2_vis'][nTrial-1] = session_info['slot2_vis'][nTrial-2];
                   session_info['slot2_aud'][nTrial-1] = session_info['slot2_aud'][nTrial-2];
                   session_info['slot3_vis'][nTrial-1] = session_info['slot3_vis'][nTrial-2];
                   session_info['slot3_aud'][nTrial-1] = session_info['slot3_aud'][nTrial-2];
                   session_info['slot1Length'][nTrial-1] = session_info['slot1Length'][nTrial-2];
                   session_info['slot2Length'][nTrial-1] = session_info['slot2Length'][nTrial-2];
                   session_info['slot3Length'][nTrial-1] = session_info['slot3Length'][nTrial-2];
                   