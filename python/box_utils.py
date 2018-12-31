def makeCues_v5(session_info, mouse_info, trialNums):

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

    # declaring extra list fields in the session_info dict
    session_info['slot1Length'] = []
    session_info['slot2Length'] = []
    session_info['slot3Length'] = []

    session_info['slot1_aud'] = []
    session_info['slot2_aud'] = []
    session_info['slot3_aud'] = []
    session_info['slot1_vis'] = []
    session_info['slot2_vis'] = []
    session_info['slot3_vis'] = []


    for nTrial in trialNums:
        
        slot1_vis = 0
        slot1_aud = 0
        slot2_vis = 0
        slot2_aud = 0
        slot3_vis = 0
        slot3_aud = 0
        
        trialLRtype = session_info['trialLRtype'][nTrial-1]
        trialAVtype = session_info['trialAVtype'][nTrial-1]
        
        ## calculating lengths of slots
        slot1Length = min(session_info['cue1Length'][nTrial-1], session_info['interOnsetInterval'][nTrial-1])
        tempSlot = session_info['interOnsetInterval'][nTrial-1] - session_info['cue1Length'][nTrial-1]
        slot2Length = abs(tempSlot)
        
        if tempSlot < 0: # the two stimuli are overlapping
            slot2StimYN = 1 # stimuli on for slot 2
        else: # the stimuli are not overlapping
            slot2StimYN = 0 # stimuli off for slot 2
            tempSlot = 0
        
        slot3Length = session_info['cue2Length'][nTrial-1] + tempSlot
        
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
                            warning('Attempting to play two contradictory auditory stimuli simultaneously')

            # if vis cue is played
            if trialAVtype==2 or trialAVtype==3:
                slot3_vis = mouse_info['leftVisCue']
                if slot2StimYN==1: # if it's played in the second slot
                    if mouse_info['leftVisCue'] != 0:
                        if slot2_vis==0:
                            slot2_vis = mouse_info['leftVisCue']
                        else:
                            warning('Attempting to play two contradictory visual stimuli simultaneously')

        if trialLRtype==4 or trialLRtype==5: # if right cue is played in third slot
            # if aud cue is played
            if trialAVtype==1 or trialAVtype==3:
                slot3_aud = mouse_info['rightAudCue']
                if slot2StimYN==1: # if it's played in the second slot
                    if mouse_info['rightAudCue'] != 0:
                        if slot2_aud==0:
                            slot2_aud = mouse_info['rightAudCue']
                        else:
                            warning('Attempting to play two contradictory auditory stimuli simultaneously')
                        
                    
            # if vis cue is played
            if trialAVtype==2 or trialAVtype==3:
                slot3_vis = mouse_info['rightVisCue']
                if slot2StimYN==1: # if it's played in the second slot
                    if mouse_info['rightVisCue'] != 0:
                        if slot2_vis==0:
                            slot2_vis = mouse_info['rightVisCue']
                        else:
                            warning('Attempting to play two contradictory visual stimuli simultaneously')
                        
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
        arduino.write(bytes(i + ';' + str(box_params[i]) + '\n', 'utf-8'))
        time.sleep(0.010) # this is necessary to prevent buffer overrun



def send_dict_to_arduino(send_this, arduino):
    import warnings
    import time
    for i in send_this:
        if isinstance(send_this[i], int): # if it's an int, just send it
            # print(bytes(i + ';' + str(send_this[i]) + '\n', 'utf-8'))
            arduino.write(bytes(i + ';' + str(send_this[i]) + '\n', 'utf-8'))
        elif isinstance(send_this[i], list): # if it's a list, send the last entry
            try:
                #print(bytes(i + ';' + str(send_this[i][-1]) + '\n', 'utf-8'))
                arduino.write(bytes(i + ';' + str(send_this[i][-1]) + '\n', 'utf-8'))
            except:
                warnings.warn('Warning: ' + i + ' did not load')
        elif isinstance(send_this[i], str): # if it's a string, do nothing
            pass
        else: 
            warnings.warn(i + 'not recognized as acceptable variable type')
        time.sleep(0.010) # this is necessary to prevent buffer overrun