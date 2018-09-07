//===================================================================================================>>
//                                          ARDUINO DUE + CUSTOM 'GREEN' SHIELD, THREE NOSEPOKE BOX  >>
//===================================================================================================>>

/*
  Daniela Cassataro v3 7/25/2018

  Controller ARDUINO DUE code for three nosepoke box, using five nosepoke box code.
  Based on Luke Sjulson's DUE_fivePoke_v3

  Updates:
  v1: . first version for custom arduino shield
    . derived from fivePoke v3
    . updated pin numbers
    . tells matlab version 9
    . no syringe pump code for 3D-printed pumps YET.

  v2: .
    .
    .
    .
    .

  To do:
    . ctrl+F "FIX:"
    . "sndCounter" resets to zero in many places. move the resetting of sndCounter to the standby exit statement?
    . remove the CR and CL stuff
    . remove the old function calls in matlab: initreward(), leftreward(), etc
    . fix: if the mouse nosepokes the center port, the init port syringe pump is activated. This is because the original box has only three pumps.

*/

// tell matlab version 10
#define VERSION     10

// include the functions
#include "toInclude/greenStandardFunctions_v4.cpp"

// state definitions
#define standby       		1  // standby - the inactive state
#define readyToGo     		2  // plays white noise, waits for init poke
#define punishDelay   		3  // timeout period after animal makes mistake
#define preCue        		4  // time delay between white noise and cue
#define cue1              5  // first cue
#define interCue          6  // time delay between the two cues
#define cue2              7  // second cue
#define postCue       		8  // additional time delay
#define goToPokes     		9  // nosepokes open, animal can approach and collect reward
#define letTheAnimalDrink 10 // waiting for animal to collect reward
#define calibration       11 // state for calibrating the sound and light cue levels
/*

////////////////////////////////////////////////////////////////////////////
  PHASE 1. white noise, init servo opens, prerewarded. reward code 1
  PHASE 2. hold init poke longer, reward at end of waiting long enough 
     in init poke. reward code 3.
  PHASE 3. block of "one side" trials. pre-reward only first block
            P=1, 5 uL, L or R random assigned/mouse
            only correct/single door open
            init no longer rewarded
            single cue, reward code 3 for the first block and reward code 4 after
  PHASE 4. random L/R, non-block trials, both doors open, 5 +/- 1 uL
            single cue, reward code 4 
  PHASE 5. decide on phase 5 based on how the mouse learned 1-4.
            vary reward size even more, over the course of the whole session.
            some trials will get double cue. reward code 4
////////////////////////////////////////////////////////////////////////////



reward codes - they are independent of which poke is rewarded
 -1 - punish for incorrect nosepoke during goToPokes
  0 - no reward
  1 - reward at ready signal
  2 - reward on init nose poke
  3 - reward at end of cue
  4 - reward only upon nosepoke

cue1_vis and cue2_vis codes
  0 - no visual cue
  1 - LEDs 1 and 2 on
  2 - LEDs 3 and 4 on
  3 - all LEDs on

cue1_aud and cue2_aud codes
  0 - no auditory cue
  1 - low tone
  2 - high tone
  3 - buzzer
  4 - white noise

*/


//===================================================================================================>>
//                                                                                        SETUP LOOP >>
//===================================================================================================>>

// runs once on initial setup
void setup() {

  Serial.begin(115200); // begin serial with 115200 baud rate
  Serial.setTimeout(100); // wait 100 ms for timeout (was originally 20 ms)

  randomSeed(analogRead(1)); // seed rng with reading from pin 1
  analogWriteResolution(12); // set DACs to 12-bit resolution
  analogWrite(DAC0, 0);      // just to initialize this DAC

  // servos have been made into objects of class: servo in the functions file.
  // attach the servo objects to their pins, and set the servos closed.
  // close all doors (make a function for this later).
  servoInit.attach(servoPin1); //attach servo to pin
  servoInit.write(ServoClosed); //set to closed
  servoLeft.attach(servoPin2);
  servoLeft.write(ServoClosed);
  servoRight.attach(servoPin3);
  servoRight.write(ServoClosed);
  extraServo4.attach(servoPin4);
  extraServo4.write(ServoClosed);
  extraServo5.attach(servoPin5);
  extraServo5.write(ServoClosed);


  // configure all pins as input/output:

  // signals to the arduino that pokes have occurred.
  pinMode(initPokeTTL, INPUT);
  pinMode(leftPokeTTL, INPUT);
  pinMode(rightPokeTTL, INPUT);
  pinMode(extraPoke4TTL, INPUT);
  pinMode(extraPoke5TTL, INPUT);
  pinMode(extraPoke6TTL, INPUT);

  // signals to the syringe pumps to move.
  pinMode(syringePumpInit, OUTPUT);   // init pump
  pinMode(syringePumpLeft, OUTPUT);   // left pump
  pinMode(syringePumpRight, OUTPUT);  // right pump
  pinMode(extraPump4, OUTPUT);        // not connected
  pinMode(extraPump5, OUTPUT);        // not connected
  pinMode(extraPump6, OUTPUT);        // not connected

  // signals to the intan for events that have occurred.
  pinMode(whiteNoiseTTL, OUTPUT);
  pinMode(auditoryCueTTL, OUTPUT);
  pinMode(visualCueTTL, OUTPUT);
  pinMode(lowCueTTL, OUTPUT);   //no longer needed ::: fix::::
  pinMode(highCueTTL, OUTPUT);  //no longer needed ::: fix::::
  pinMode(pulsePal1, OUTPUT);
  pinMode(pulsePal2, OUTPUT);
  pinMode(triggerPin, OUTPUT);

  // turn all LEDs off.
  cueLED1.off();
  cueLED2.off();
  cueLED3.off();
  cueLED4.off();
  cameraLED.off();

  // default state
  state = standby;
}

//===================================================================================================>>
//                                      FINITE STATE MACHINE                                         >>
//===================================================================================================>>


void loop() {

  t.update(); // update timer with each cycle

  /////////////////////////////////////////////////////////////
  // polling to check for door, reward, and poke status.

  if (micros() - lastCheckTimeMicros >= slowDTmicros) {
    // we don't want to check too often, so we only check every "slowDTmicros" period.
   // micros() returns number of microseconds since the Arduino board began running the current program.(unsigned long)
    checkDoors();   // update door state as per matlab instruction
    checkRewards(); // update reward state as per matlab instruction
    checkPokes();   // check nosepokes
    // set new, most recent timepoint we polled the doors/rewards/pokes status:
    lastCheckTimeMicros = micros();


  }

  switch (state) {

    ////////////////////
    // STANDBY
    // the default state when not running trials
    // wait for matlab instructions, initialize trial counter as per matlab, wait for go signal

    case standby:

      processMessage();
      delayMicroseconds(pauseLengthMicros);

      // it's specified in matlab when the timer is reset to zero. (start of session, or could be start of trial)
      // if timer has been reset by matlab:
      if (resetTimeYN == 1) {
        DPRINTLN("time reset");
        resetTimeYN = 0;                  // change timer back to "non-reset" & start counting up
        startTime = millis();             // assign start time of standby as millis, (the time since arduino set up)
        digitalWrite(triggerPin, HIGH);   // 20ms pulse to Intan at the start of the trial.
        delay(20);
        digitalWrite(triggerPin, LOW);
        uncollectedRewardYN = 0;          // clear any uncollected rewards when timer is reset
      }
      

      // prevent the animal from starting a trial before white noise/"readyToGo" state:
      if (initPoke == 1 && initPokePunishYN == 1) { // if animal init pokes when not cued to do so (before white noise)
        serLog("InitPokeDuringStndby");
        initPokeError = 1; // this prevents "Standby" from going in the log, so that matlab doesn't get confused and think the trial is over.
        switchTo(punishDelay);
        serLogNum("punishDelayLength", punishDelayLength);
        sndCounter = 0;
      }

      // start a trial if triggered by matlab, switch state to READY TO GO
      else if (startTrialYN == 1) { // if matlab wants to start a trial
        serLog("TrialAvailable");
        serLogNum("TrainingPhase", trainingPhase);
        serLogNum("NosePokeHoldLength", nosePokeHoldLength);
        digitalWrite(whiteNoiseTTL, HIGH); // tell the intan you're going to the readyToGo state/you're about to start the white noise
        cameraLED.on();
        sndCounter = 0; // reset sound counter
        startTrialYN = 0; // reset startTrial
        if (uncollectedRewardYN==0) {
     	   giveRewards(1); // give a reward to the location(s) with reward codes "1" (the init poke before mouse has poked)
    	   }
        probsWritten = 0; // this is a variable that switches off (to zero) after writing the probability once so it's not writing the probability on every loop
        trialAvailTime = millis(); // assign time in ms when trial becomes available/when you're switching to readyToGo state.
        switchTo(readyToGo);
        openPoke("init"); //open init door.
      }

      // for calibrating the volume levels and cue light brightness
      if (calibrationLength > 0) {
        cueLED1.on();
        cueLED2.on();
        cueLED3.on();
        cueLED4.on();
        WNvolume = 128;
        switchTo(calibration);
      }

      break;


    ////////////////////
    // READY TO GO
    // white noise starts
    // wait for mouse to nosepoke to initiate a trial

    case readyToGo:

      playWhiteNoise();
      
      // if timeout, switch state to punishDelay
      if ((millis() - tempTime) > readyToGoLength) { // if timeThisStateBegan_ms happened readyToGoLength_ms ago without a nosepoke, the mouse missed the trial.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        cameraLED.off();
        serLogNum("TrialMissedBeforeInit", millis() - trialAvailTime); // FIX: replace tempTime w/ trialAvailTime
        sndCounter = 0;
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
        uncollectedRewardYN = 1; // indicates the animal is leaving an uncollected reward behind so that another one is not delivered in the next trial - for training phase 1 only
      }


      // if mouse init-pokes, switch state to PRE-CUE
      if (initPoke == 1) {

        // if trainingPhase == 0, the arduino wasn't set up properly
        if (trainingPhase == 0) {
          serLog("Error_trainingPhaseIsZero");
          switchTo(standby);
        }

        nosePokeInitTime = millis(); // record time when mouse begins the init poke specifically. used to make sure mouse holds long enough.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        cameraLED.off();

        // if training phase 1 and mouse pokes, switch state directly to letTheAnimalDrink
        if (trainingPhase==1) {
          uncollectedRewardYN = 0; // only relevant in training phase 1 - indicates the mouse collected the reward, so the port will get a reward next trial
          serLogNum("Phase1RewardCollected", millis() - trialAvailTime);
          switchTo(letTheAnimalDrink);
        }
        // for other training phases, go to preCue 
        else {
          serLogNum("TrialStarted", millis() - trialAvailTime);
          sndCounter = 0;
          giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) 
          switchTo(preCue);
        }
      }

      break;






    ////////////////////
    // PRE-CUE
    // pause before the cue, check for nosepoke withdrawal

    case preCue:

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0) {
        serLogNum("PreCueWithdrawal", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
      // start one of the cues when preCueLength time elapsed.
      else if ((millis() - tempTime) > preCueLength) {
        switchTo(cue1);

        // turn on visual cues
        if (cue1_vis==1) {
          cueLED1.on();
          cueLED2.on();
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (cue1_vis==2) {
          cueLED3.on();
          cueLED4.on();
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (cue1_vis==3) {
          cueLED1.on();
          cueLED2.on();
          cueLED3.on();
          cueLED4.on();
          digitalWrite(visualCueTTL, HIGH);
        }
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


    ////////////////////
    // CUE1
    // First cue, check for nosepoke withdrawal

    case cue1:

      // play auditory cues
      if (cue1_aud==1) {
        playLowTone();
      }
      else if (cue1_aud==2) {
        playHighTone();
      }
      else if (cue1_aud==3) {
        playBuzzer();
      }
      else if (cue1_aud==4) {
        playWhiteNoise();
      }


      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0) {
        serLogNum("Cue1Withdrawal", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      else if ((millis() - tempTime) > cue1Length) {
        // turn off any visual cues
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        digitalWrite(visualCueTTL, LOW);

        sndCounter = 0;
        switchTo(interCue);
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


    ////////////////////
    // INTERCUE
    // pause between cues, check for nosepoke withdrawal

    case interCue:

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0) {
        serLogNum("InterCueWithdrawal", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
      // start one of the cues when interCueLength time elapsed.
      else if ((millis() - tempTime) > interCueLength) {
        switchTo(cue2);

        // turn on visual cues
        if (cue2_vis==1) {
          cueLED1.on();
          cueLED2.on();
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (cue2_vis==2) {
          cueLED3.on();
          cueLED4.on();
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (cue2_vis==3) {
          cueLED1.on();
          cueLED2.on();
          cueLED3.on();
          cueLED4.on();
          digitalWrite(visualCueTTL, HIGH);
        }
      }

      delayMicroseconds(pauseLengthMicros); 
      break;

    ////////////////////
    // CUE2
    // second cue, check for nosepoke withdrawal

    case cue2:

      // play auditory cues
      if (cue2_aud==1) {
        playLowTone();
      }
      else if (cue2_aud==2) {
        playHighTone();
      }
      else if (cue2_aud==3) {
        playBuzzer();
      }
      else if (cue2_aud==4) {
        playWhiteNoise();
      }

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0) {
        serLogNum("Cue2Withdrawal", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
      // start one of the cues when cue2Length time elapsed.
      else if ((millis() - tempTime) > cue2Length) {
        // turn off any visual cues
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        digitalWrite(visualCueTTL, LOW);

        sndCounter = 0;
        switchTo(postCue);
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


   ////////////////////
    // POSTCUE
    // pause after second cue, check for nosepoke withdrawal

    case postCue:

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0) {
        serLogNum("postCueWithdrawal", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
      // start one of the cues when postCueLength time elapsed.
      else if ((millis() - tempTime) > postCueLength) {
        giveRewards(3);
        if (trainingPhase==2) {
          switchTo(letTheAnimalDrink);
        }
        else {
          switchTo(goToPokes);  
        }
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


    ////////////////////
    // PUNISHDELAY
    // delay period after error trial. fix::::::::: punishdelay according to my diagram i wrote down.

    case punishDelay:
      if ((millis() - tempTime) > punishDelayLength) {
        switchTo(standby);
        if (initPokeError == 0) {
          serLog("Standby");
        }
        else {
          serLog("TO_STNDBY_FROM_PUNISH");
        }
        initPokeError = 0;
      }
      processMessage();
      //delayMicroseconds(pauseLengthMicros);
      break;



    ////////////////////
    // GOTOPOKES
    // animal is free to nosepoke the reward pokes
    // main place where training phase affects what happens

    case goToPokes:

      processMessage(); // read in input from matlab/console - allows canceling in middle of trial

      // if timeout, switch state to punishDelay
      if ((millis() - tempTime) > goToPokesLength) {
        serLogNum("TrialMissedAfterInit", millis() - initPokeExitTime);
        sndCounter = 0;
        serLogNum("punishDelayLength", punishDelayLength);
        switchTo(punishDelay);
      }

      // if left poke occurs
      if (leftPoke==1) {
        if (LrewardCode==4) {
          deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
          switchTo(letTheAnimalDrink);
        }
        else if (LrewardCode==-1) {
          serLogNum("LeftPokeError", 1);
          serLogNum("punishDelayLength", punishDelayLength);
          switchTo(punishDelay);
        }
      }

      // if right poke occurs
      if (rightPoke==1) {
        if (RrewardCode==4) {
          deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
          switchTo(letTheAnimalDrink);
        }
        else if (RrewardCode==-1) {
          serLogNum("RightPokeError", 1);
          serLogNum("punishDelayLength", punishDelayLength);
          switchTo(punishDelay);
        }
      }


/*
      // trainingPhase 1: correct means collecting from the pre-rewarded port
      // init prerewarded
       if (trainingPhase == 1) {
         if (IrewardCode == 1 && initPoke == 1) {
           serLogNum("Correct", millis() - initPokeExitTime);
           serLogNum("InitRewardCollected", deliveryDuration_ms);
           switchTo(letTheAnimalDrink);
         }
         if (IrewardCode != 1) {
           serLog("Error_reward_codes_set_incorrectly");
           goToStandby = 1;
         }
       }

      // trainingPhase 2: correct means collecting from the pre-rewarded port
      // reward init at end of nose hold.
       if (trainingPhase == 2) {
         if (IrewardCode == 3 && initPoke == 1) {
           serLogNum("Correct", millis() - initPokeExitTime);
           serLogNum("InitRewardCollected", deliveryDuration_ms);
           switchTo(letTheAnimalDrink);
         }
         if (IrewardCode != 3) {
           serLog("Error_reward_codes_set_incorrectly");
           goToStandby = 1;
         }
       }

      
      // trainingPhase 3: ports are only rewarded after nosepoke, no punishment. 1 door opens. 
      // no error penalty?
      // first block of phase 3 is prerewarded after cue (code3),
      // the rest are rewarded after correct poke (code4)

      if (trainingPhase == 3) {
        if (LrewardCode != 0 && leftPoke == 1) {
          //deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
          giveRewards(4); // luke0806. 
          //  
          // phase 3 is supposed to have only the first block be prerewarded (giverewards(3)) 
          // and then giverewards(4) should happen here.
          // however, 

          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("LeftRewardCollected", deliveryDuration_ms);
          switchTo(letTheAnimalDrink);
        }
        if (RrewardCode != 0 && rightPoke == 1) {
          //deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
          giveRewards(4); // luke0806
          // same as above block, but it actually 'works,' whatever that means
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("RightRewardCollected", deliveryDuration_ms);
          switchTo(letTheAnimalDrink);
        }
        if (LrewardCode != 3 && RrewardCode != 3) { //this error is old and should be updated
          serLog("Error_reward_codes_set_incorrectly");
          goToStandby = 1; 
        }
      }

      // trainingPhases 4-7: punishment tone for incorrect door choice
      if (trainingPhase >= 4) {

        // left side cued
        if ((isLeftAuditory == 1 && auditoryOrVisualCue == 1) || (isLeftAuditory == 0 && auditoryOrVisualCue == 2)) {
          if (rightPoke == 1) {
            serLogNum("ErrorPoke", millis() - initPokeExitTime);
            sndCounter = 0;
            switchTo(buzzer);
          }
          if (leftPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if (LrewardCode == 4) {
              //deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
              giveRewards(4); // luke0806
              // same things happen here where right pump turns for both correct pokes.
              serLogNum("LeftRewardCollected", deliveryDuration_ms);
              switchTo(letTheAnimalDrink);
            }
            else {
              serLog("LeftPokeNoReward");
              delay(300);
              goToStandby = 1;
            }
          }
        }

        // right side cued
        if ((isLeftAuditory == 1 && auditoryOrVisualCue == 2) || (isLeftAuditory == 0 && auditoryOrVisualCue == 1)) {
          if (leftPoke == 1) {
            serLogNum("ErrorPoke", millis() - initPokeExitTime);
            sndCounter = 0;
            switchTo(buzzer);
          }
          if (rightPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if (RrewardCode == 4) {
              //deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
              giveRewards(4); // luke0806
              // same things happen here where right pump turns for both correct pokes.
              serLogNum("RightRewardCollected", deliveryDuration_ms);
              switchTo(letTheAnimalDrink);
            }
            else {
              serLog("RightPokeNoReward");
              delay(300);
              goToStandby = 1;
            }
          }
        }
      }
      */

      // go to standby (instructed by either above code or by matlab)
      if (goToStandby == 1) {
        goToStandby = 0;
        closePoke("all");
        state = standby;
        serLog("Standby");
      }
      delayMicroseconds(pauseLengthMicros);
      break;


    ////////////////////
    // LETTHEANIMALDRINK
    // delay while animal collects reward

    case letTheAnimalDrink:

      if ((millis() - tempTime) > rewardCollectionLength) {
        closePoke("all");
        serLog("Standby");
        switchTo(standby);
      }
      delayMicroseconds(pauseLengthMicros);
    break;

    ///////////////////////////////////////////////
    // CALIBRATION
    // state for calibrating the sound and light cue levels

    case calibration:
      
      playWhiteNoise();

      if ((millis() - tempTime) > calibrationLength) {
        calibrationLength = 0;
        sndCounter = 0;
        switchTo(standby);
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
      }
    break;
  }
}
