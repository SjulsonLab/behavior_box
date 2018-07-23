//===================================================================================================>>
//                                          ARDUINO DUE + CUSTOM 'GREEN' SHIELD, THREE NOSEPOKE BOX  >>
//===================================================================================================>>

/*
  Daniela Cassataro v3 7/13/2018

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
// #define DEBUG   //If you comment out this line, the DPRINT & DPRINTLN lines are defined as blank.
#ifdef DEBUG
#define DPRINT(...)    Serial.print(__VA_ARGS__)     //DPRINT is a macro, debug print
#define DPRINTLN(...)  Serial.println(__VA_ARGS__)   //DPRINTLN is a macro, debug print with new line
#else
#define DPRINT(...)     //now defines a blank line
#define DPRINTLN(...)   //now defines a blank line
#endif



// state definitions
#define standby       1  // standby - the inactive state
#define readyToGo     2  // plays white noise, waits for init poke
#define missed        3  // if trial times out or animal makes wrong choice. no buzzer.
#define punishDelay   4  // additional timeout period after missed
#define preCue        5  // time delay between white noise and cue
#define auditoryCue   6  // auditory cue plays
#define visualCue     7  // visual cue plays
#define noCue         8  // no cue plays
#define postCue       9  // additional time delay
#define goToPokes     10 // nosepokes open, animal can approach and collect reward
#define getReward     11 // waiting for animal to collect reward
#define buzzerState   12 // play buzzer before switching to punishDelay

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


////////////////////////////////////     O L D :     ///////////////////////////////////////

    phase 1: white noise, init poke pre-rewarded. Animal pokes init, then gets cue, and
    only one door opens, which is also pre-rewarded. Advance when animal gets reward quickly.

    phase 2: same as phase 1 except neither poke is pre-rewarded

    phase 3: same as phase 2 except two reward doors open, and only the correct one is rewarded. No punishment for
    picking the wrong door. Try to keep this short.

    phase 4: same as phase 3 except now the incorrect door is punished.

    phase 5: increasing init poke duration. Also, rewards become probabilistic. Only outer doors open.

    phase 6: no cue, only center door opens. Reward is probabilistic.

    phase 7: full task. All three doors open on every trial.
//////////////////////////////////////////////////////////////////////////////////////////////

  reward codes - they are independent of which poke is rewarded
    0 - no reward
    1 - reward init poke at ready signal
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
  pinMode(syringePumpInit, OUTPUT);   // init pump - fix: in phase 6-7, used for center port
  pinMode(syringePumpLeft, OUTPUT);   // left pump
  pinMode(syringePumpRight, OUTPUT);  // right pump
  pinMode(extraPump4, OUTPUT);        // not connected
  pinMode(extraPump5, OUTPUT);        // not connected
  pinMode(extraPump6, OUTPUT);        // not connected

  // signals to the intan for events that have occurred.
  pinMode(whiteNoiseTTL, OUTPUT);
  pinMode(auditoryCueTTL, OUTPUT);
  pinMode(visualCueTTL, OUTPUT);
  pinMode(lowCueTTL, OUTPUT);
  pinMode(highCueTTL, OUTPUT);
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
        giveRewards(1); // give a reward to the location(s) with reward codes "1" (the init poke before mouse has poked)
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
      }

      // if mouse init-pokes, switch state to PRE-CUE
      if (initPoke == 1) {
        nosePokeInitTime = millis(); // record time when mouse begins the init poke specifically. used to make sure mouse holds long enough.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        cameraLED.off();
        serLogNum("TrialStarted", millis() - trialAvailTime);
        sndCounter = 0;
        giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) 
        // NOTE ::::::::: I think that reward code 2 should become reward at the end of waiting the length of init hold time. 
        switchTo(preCue);
      }

      break;


    ////////////////////
    // MISSED
    // should play a punishment buzzer, but not tested yet

    case missed:

      // wait for timeout, switch state to PUNISH DELAY
      if ((millis() - tempTime) > missedLength) {
        closePoke("all");
        serLog("PunishDelay");
        switchTo(punishDelay);
      }

      break;


    case buzzerState:

      playBuzzer();

      // wait for timeout, switch state to PUNISH DELAY
      if ((millis() - tempTime) > missedLength) {
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
        if (cueHiLow == -1) { // -1 is low
          digitalWrite(lowCueTTL, HIGH);
          serLog("LowCue");
          if (isLeftLow == 1) { // if left is designated as the low cue side (in matlab)
            serLog("LeftCue");  // log as a "left cue"
          }
          else {                // if left is NOT designated as the low cue side (in matlab)
            serLog("RightCue"); // log as a "right cue"
          }
        }
        else if (cueHiLow == 1) { // 1 is high
          digitalWrite(highCueTTL, HIGH);
          serLog("HighCue");
          if (isLeftLow == 1) {   // if left is designated as the low cue side (in matlab)
            serLog("RightCue");   // log as a "right cue"
          }
          else {                  // if left is NOT designated as the low cue side (in matlab)
            serLog("LeftCue");    // log as a "left cue"
          }
        }

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
          switchTo(noCue); // what is noCue?
        }
        if (auditoryOrVisualCue == 1 && cueHiLow != 0) {
          digitalWrite(auditoryCueTTL, HIGH);
          serLog("AuditoryCue");
          switchTo(auditoryCue); // switch to give aud cue
        }
        if (auditoryOrVisualCue == 2 && cueHiLow != 0) {
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

      if (cueHiLow == -1)
        playLowTone();

      else if (cueHiLow == 1)
        playHighTone();

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }

      // stop pulsing the intan when the auditory cue is finished playing.
      else if ((millis() - tempTime) > auditoryCueLength) {
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        switchTo(postCue);
      }
      break;

    ////////////////////
    // VISUAL CUE
    // visual stimulus given, check for nosepoke withdrawal

    case visualCue:

      if (cueHiLow == 1) { // high LEDs
        cueLED1.on();
        cueLED3.on();
      }
      else if (cueHiLow == -1) { // low LEDs
        cueLED2.on();
        cueLED4.on();
      }

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(visualCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }
      else if ((millis() - tempTime) > visualCueLength) {
        cueLED1.off();
        cueLED2.off();
        cueLED3.off();
        cueLED4.off();
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(visualCueTTL, LOW);
        switchTo(postCue);
      }
      break;

    ////////////////////
    // NO CUE
    // used for the training phases..

    case noCue:

      // if mouse withdraws nose too early, switch state to missed
      if (initPoke == 0 && (millis() - nosePokeInitTime) < nosePokeHoldLength) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }

      // switching to postcue after length of time... using "visualCueLength" time
      else if (millis() - tempTime > visualCueLength) {
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
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

      // if mouse held long enough, possibility of opening the do this until the postcuelength is up.
      else if (millis() - tempTime > postCueLength) {
        if (LopenYN == 1)
          openPoke("left");
        if (extra4openYN == 1)
          openPoke("extraPoke4");
        if (RopenYN == 1)
          openPoke("right");
        if (extra5openYN == 1)
          openPoke("extraPoke5");
        //if (CopenYN == 1)
        //  openPoke("center");
        giveRewards(3); // give reward to the init poke
        switchTo(goToPokes);
      }

      delayMicroseconds(pauseLengthMicros);
      break;

    // GETREWARD: delay while animal collects reward
    case getReward:

      if (millis() - tempTime > rewardCollectionLength) {
        closePoke("all");
        serLog("Standby");
        switchTo(standby);
      }
      delayMicroseconds(pauseLengthMicros);
      break;

    // PUNISHDELAY: delay period after error trial. fix: punishdelay according to my diagram i wrote down.
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




















    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                          GO TO POKES - animal is free to nosepoke the reward pokes                            //
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////



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
      // L/R prerewarded
      // if (trainingPhase == 1) {
      //   if (LrewardCode == 3 && leftPoke == 1) {
      //     serLogNum("Correct", millis() - initPokeExitTime);
      //     serLogNum("LeftRewardCollected", deliveryDuration_ms);
      //     switchTo(getReward);
      //   }
      //   if (RrewardCode == 3 && rightPoke == 1) {
      //     serLogNum("Correct", millis() - initPokeExitTime);
      //     serLogNum("RightRewardCollected", deliveryDuration_ms);
      //     switchTo(getReward);
      //   }

      //   if (LrewardCode != 3 && RrewardCode != 3) {
      //     serLog("Error_reward_codes_set_incorrectly");
      //     goToStandby = 1;
      //   }
      // }

      // trainingPhase 2-3: ports are only rewarded after nosepoke, no punishment. In phase2, 1 door opens. In phase3, 2 doors open.
      // L/R not prerewarded but there's no error penalty
      if (trainingPhase == 2 || trainingPhase == 3) {
        if (LrewardCode == 4 && leftPoke == 1) {
          deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("LeftRewardCollected", deliveryDuration_ms);
          switchTo(getReward);
        }
        if (RrewardCode == 4 && rightPoke == 1) {
          deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("RightRewardCollected", deliveryDuration_ms);
          switchTo(getReward);
        }
        if (LrewardCode != 4 && RrewardCode != 4) {
          serLog("Error_reward_codes_set_incorrectly");
          goToStandby = 1;
        }
      }

      // trainingPhases 4-7: punishment tone for incorrect door choice
      if (trainingPhase >= 4) {

        if (probsWritten == 0) {
          serLogNum(String("LrewardProb"), LrewardProb);
          //serLogNum(String("CrewardProb"), CrewardProb);
          serLogNum(String("RrewardProb"), RrewardProb);
          //serLogNum(String("CLrewardProb"), CLrewardProb);
          //serLogNum(String("CRrewardProb"), CRrewardProb);
          probsWritten = 1;
        }

        // left side cued
        if ((isLeftLow == 1 && cueHiLow == -1) || (isLeftLow == 0 && cueHiLow == 1)) {
          if (rightPoke == 1) {
            serLogNum("ErrorPoke", millis() - initPokeExitTime);
            sndCounter = 0;
            switchTo(buzzerState);
          }
          if (leftPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if ((LrewardCode == 4) && (random(100) < LrewardProb)) {
              deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
              serLogNum("LeftRewardCollected", deliveryDuration_ms);
              switchTo(getReward);
            }
            else {
              serLog("LeftPokeNoReward");
              delay(300);
              goToStandby = 1;
            }
          }
        }

        // right side cued
        if ((isLeftLow == 1 && cueHiLow == 1) || (isLeftLow == 0 && cueHiLow == -1)) {
          if (leftPoke == 1) {
            serLogNum("ErrorPoke", millis() - initPokeExitTime);
            sndCounter = 0;
            switchTo(buzzerState);
          }
          if (rightPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if ((RrewardCode == 4) && (random(100) < RrewardProb)) {
              deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
              serLogNum("RightRewardCollected", deliveryDuration_ms);
              switchTo(getReward);
            }
            else {
              serLog("RightPokeNoReward");
              delay(300);
              goToStandby = 1;
            }
          }
        }


/*        // center poke (regardless of which cue given)
        if (centerPoke == 1) {
          serLogNum("CenterPoke", millis() - initPokeExitTime);

          if ((CrewardCode == 4) && (random(100) < CrewardProb)) { // if reward given
            serLogNum("CenterRewardCollected", deliveryDuration_ms);
            deliverReward_dc(volumeCenter_nL, deliveryDuration_ms, syringeSize_mL, syringePumpCenter);
            switchTo(getReward);
          }

          else {  // if reward not given
            serLog("CenterPokeNoReward");
            delay(300);
            goToStandby = 1;
          }
        }*/
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
