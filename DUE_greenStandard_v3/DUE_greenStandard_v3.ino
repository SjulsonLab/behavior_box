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

// tell matlab version 9
#define VERSION     9

// include the functions
#include "toInclude/greenStandardFunctions_v3.cpp"

// for debugging
// #define DEBUG   //If you uncomment this line and recompile, you will get debugging messages (DPRINT and DPRINTLN lines)
#ifdef DEBUG
#define DPRINT(...)    Serial.print(__VA_ARGS__)     //DPRINT is a macro, debug print
#define DPRINTLN(...)  Serial.println(__VA_ARGS__)   //DPRINTLN is a macro, debug print with new line
#else
#define DPRINT(...)     //now defines a blank line
#define DPRINTLN(...)   //now defines a blank line
#endif



// state definitions
#define standby       		1  // standby - the inactive state
#define readyToGo     		2  // plays white noise, waits for init poke
#define missed        		3  // if trial times out or animal makes wrong choice. no buzzer.
#define punishDelay   		4  // additional timeout period after missed
#define preCue        		5  // time delay between white noise and cue
#define auditoryCue   		6  // auditory cue plays
#define visualCue     		7  // visual cue plays
#define noCue         		8  // no cue plays
#define postCue       		9  // additional time delay
#define goToPokes     		10 // nosepokes open, animal can approach and collect reward
#define letTheAnimalDrink   11 // waiting for animal to collect reward
#define buzzer  	        12 // play buzzer before switching to punishDelay

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
    0 - no reward
    1 - reward at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon nosepoke
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
//                                                                              FINITE STATE MACHINE >>
//===================================================================================================>>


void loop() {

  t.update(); // update timer with each cycle

  // using polling to check for door, reward, and poke status.
  // we don't want to check too often, so we only check every "slowDTmicros" period.
  // micros() returns number of microseconds since the Arduino board began running the current program.(unsigned long)
  if (micros() - lastCheckTimeMicros >= slowDTmicros) {
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
      
      // this will no longer be needed:::::::::::::::::
      // prevent the animal from starting a trial before white noise/"readyToGo" state:
      if (initPoke == 1 && initPokePunishYN == 1) { // if animal init pokes when not cued to do so (before white noise)
        serLog("InitPokeDuringStndby");
        initPokeError = 1; // this prevents "Standby" from going in the log, so that matlab doesn't get confused and think the trial is over.
        switchTo(missed);
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

      break;


    ////////////////////
    // READY TO GO
    // white noise starts
    // wait for mouse to nosepoke to initiate a trial

    case readyToGo:

      playWhiteNoise();
      
      // if timeout, switch state to MISSED
      if ((millis() - tempTime) > readyToGoLength) { // if timeThisStateBegan_ms happened readyToGoLength_ms ago without a nosepoke, the mouse missed the trial.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        cameraLED.off();
        serLogNum("TrialMissedBeforeInit", millis() - trialAvailTime); // FIX: replace tempTime w/ trialAvailTime
        sndCounter = 0;
        switchTo(missed);
        uncollectedRewardYN = 1; // indicates the animal is leaving an uncollected reward behind so that another one is not delivered in the next trial - for training phase 1 only
      }

      // if mouse init-pokes, switch state to PRE-CUE
      if (initPoke == 1) {
      	uncollectedRewardYN = 0; // only relevant in training phase 1 - indicates the mouse collected the reward, so the port will get a reward next trial
        nosePokeInitTime = millis(); // record time when mouse begins the init poke specifically. used to make sure mouse holds long enough.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        cameraLED.off();
        serLogNum("TrialStarted", millis() - trialAvailTime);
        sndCounter = 0;
        giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) 

        switchTo(preCue);
      }

      break;


    ////////////////////
    // MISSED
    // pause for missed trial, does not play buzzer

    case missed:

      // wait for timeout, switch state to PUNISH DELAY
      if ((millis() - tempTime) > missedLength) {
        closePoke("all");
        serLog("PunishDelay");
        switchTo(punishDelay);
      }

      break;


    ////////////////////
    // BUZZER
    // plays a punishment buzzer, but not tested yet
    
    case buzzer:

      playBuzzer();

      // wait for timeout, switch state to PUNISH DELAY
      if ((millis() - tempTime) > buzzerLength) {
        closePoke("all");
        serLog("PunishDelay");
        switchTo(punishDelay);
      }

      break;


    ////////////////////
    // PRE-CUE
    // pause before the cue, check for nosepoke withdrawal

    case preCue:

      // if mouse withdraws nose too early, switch state to missed
      if ((initPoke == 0) && ((millis() - nosePokeInitTime) < nosePokeHoldLength)) {
        serLogNum("PreCueWithdrawal", millis() - nosePokeInitTime);
        sndCounter = 0; //FIX: reset sndCounter to zero in only one place? it's already in the standby exit state
        switchTo(missed);
      }

      // otherwise mouse held long enough:
      // start one of the cues when preCueLength time elapsed.
      else if ((millis() - tempTime) > preCueLength) {
        
        //::::::::idk if these work at all:::::::::
        // trigger the pulsepal(s) 
        if (laserOnCode == 1) {
          serLogNum("LaserTriggered", 1);
          triggerPulsePal(1);
        }
        if (laserOnCode == 2) {
          serLogNum("LaserTriggered", 2);
          triggerPulsePal(2);
        }
        if (laserOnCode == 3) {
          serLogNum("LaserTriggered", 1);
          serLogNum("LaserTriggered", 2);
          triggerPulsePal(1);
          triggerPulsePal(2);
        }

        if (auditoryOrVisualCue == 0) {
          serLog("NoCue");
          switchTo(noCue); // used for training phases
        }

        if (auditoryOrVisualCue == 1) {   // if giving AUDITORY CUE
          if (isLeftAuditory == 1) {      // if left is designated as the audi cue side (in matlab)
            serLog("LeftCue");            // log as a "left cue"
          }
          else {                          // if right is designated as the audi cue side (in matlab)
            serLog("RightCue");           // log as a "right cue"
          }
          digitalWrite(auditoryCueTTL, HIGH);
          serLog("AuditoryCue");
          switchTo(auditoryCue); // switch to give auditory cue
        }

        if (auditoryOrVisualCue == 2) { // if giving VISUAL CUE
          if (isLeftAuditory == 0) {    // if right is designated as the audi cue side (in matlab)
            serLog("LeftCue");          // log as a "left cue"
          }
          else {                        // if left is designated as the audi cue side (in matlab)
            serLog("RightCue");         // log as a "right cue"
          }
          digitalWrite(visualCueTTL, HIGH);
          serLog("VisualCue");
          switchTo(visualCue); // switch to give vis cue
        }
      }

      delayMicroseconds(pauseLengthMicros); // why do we need to delay after?
      break;


    ////////////////////
    // AUDITORY CUE
    // auditory stimulus given, check for nosepoke withdrawal

    case auditoryCue:
    //playLowTone();
      playHighTone();

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
    //    digitalWrite(lowCueTTL, LOW);
    //    digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }

      // stop pulsing the intan when the auditory cue is finished playing.
      else if ((millis() - tempTime) > auditoryCueLength) {
    //    digitalWrite(lowCueTTL, LOW);
    //    digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        switchTo(postCue);
      }
      break;

    ////////////////////
    // VISUAL CUE
    // visual stimulus given, check for nosepoke withdrawal

    case visualCue:

      cueLED1.on();
      cueLED2.on();
      cueLED3.on();
      cueLED4.on();

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        digitalWrite(visualCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }
      else if ((millis() - tempTime) > visualCueLength) {
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        //digitalWrite(lowCueTTL, LOW);
        //digitalWrite(highCueTTL, LOW);
        digitalWrite(visualCueTTL, LOW);
        switchTo(postCue);
      }
      break;

    ////////////////////
    // NO CUE
    // used for the training phases 1&2

    case noCue:

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
      //  digitalWrite(lowCueTTL, LOW);
      //  digitalWrite(highCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }

      // switching to postcue after length of time... using "visualCueLength" time
      else if ((millis() - tempTime) > visualCueLength) {
      //  digitalWrite(lowCueTTL, LOW);
      //  digitalWrite(highCueTTL, LOW);
        serLog("switchingToPostCue"); //testing ... :::::fix: remove
        switchTo(postCue);
      }
      break;

    ////////////////////
    // POSTCUE
    // pause after cue, check for nosepoke withdrawal

    case postCue:

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        sndCounter = 0;
        switchTo(missed);
      }

      // if mouse held long enough, possibility of opening the doors until the postcuelength is up.
      else if (millis() - tempTime > postCueLength) {
        if (LopenYN == 1)
          openPoke("left");
        if (RopenYN == 1)
          openPoke("right");
        if (extra4openYN == 1)
          openPoke("extraPoke4");
        if (extra5openYN == 1)
          openPoke("extraPoke5");
        //giveRewards(3); // give reward to the init/L/R pokes after cue/noCue has occurred and mouse held long enough
        if (trainingPhase < 3)
          giveRewards(3);
          switchTo(letTheAnimalDrink); //mouse will collect reward in the init port in phases 1 & 2
        if (trainingPhase > 2)
          giveRewards(3);
          switchTo(goToPokes); 
          //mouse will now go collect reward from pre-rewarded L/R (1st block phase 3), 
      	  //or after poking L/R, (in later blocks phase 3, or in phase 4 and above)
      }

      delayMicroseconds(pauseLengthMicros);
      break;


    ////////////////////
    // LETTHEANIMALDRINK
    // delay while animal collects reward

    case letTheAnimalDrink:

      if (millis() - tempTime > rewardCollectionLength) {
        closePoke("all");
        serLog("Standby");
        switchTo(standby);
      }
      delayMicroseconds(pauseLengthMicros);
      break;

    ////////////////////
    // PUNISHDELAY
    // delay period after error trial. fix::::::::: punishdelay according to my diagram i wrote down.

    case punishDelay:
      if (millis() - tempTime > punishDelayLength) {
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

      // if timeout, switch state to missed
      if (millis() - tempTime > goToPokesLength) {
        serLogNum("TrialMissedAfterInit", millis() - initPokeExitTime);
        sndCounter = 0;
        switchTo(missed);
      }

      // if trainingPhase == 0, the arduino wasn't set up properly
      if (trainingPhase == 0) {
        serLog("Error_trainingPhaseIsZero");
        goToStandby = 1;
      }

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
          //deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
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
          //deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
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
              //deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
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
              //deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
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

      // go to standby (instructed by either above code or by matlab)
      if (goToStandby == 1) {
        goToStandby = 0;
        closePoke("all");
        state = standby;
        serLog("Standby");
      }
      delayMicroseconds(pauseLengthMicros);
      break;
  }
}
