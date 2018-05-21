/* controller code for three nosepoke box, using five nosepoke box code
    ONLY FOR ARDUINO DUE
    Luke Sjulson, updated by Daniela Cassataro 2018-04

    v1: first version for custom arduino shield
        derived from fivePoke v3
        updated pin numbers
        tells matlab version 9
        no syringe pump code for 3D-printed pumps YET.

    OF NOTE: if the mouse nosepokes the center port, the init port syringe
    pump is activated. This is because the original box has only three pumps.

*/

#define VERSION     9
#include "toInclude/greenStandardFunctions_v2.cpp"

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
#define missed        3  // if trial times out or animal makes wrong choice. Plays buzzer, goes to timeout
#define punishDelay   4  // additional timeout period after missed
#define preCue        5  // time delay between white noise and cue
#define auditoryCue   6  // auditory cue plays
#define visualCue     7  // visual cue plays
#define noCue         8  // no cue plays
#define postCue       9  // additional time delay
#define goToPokes     10 // nosepokes open, animal can approach and collect reward
#define getReward     11 // waiting for animal to collect reward

/*
    phase 1: white noise, init poke pre-rewarded. Animal pokes init, then gets cue, and
    only one door opens, which is also pre-rewarded. Advance when animal gets reward quickly.

    phase 2: same as phase 1 except neither poke is pre-rewarded

    phase 3: same as phase 2 except two reward doors open, and only the correct one is rewarded. No punishment for
    picking the wrong door. Try to keep this short.

    phase 4: same as phase 3 except now the incorrect door is punished.

    phase 5: increasing init poke duration. Also, rewards become probabilistic. Only outer doors open.

    phase 6: no cue, only center door opens. Reward is probabilistic.

    phase 7: full task. All three doors open on every trial.


  reward codes - they are independent of which poke is rewarded
    0 - no reward
    1 - reward init poke at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon nosepoke
*/

void setup() { // code runs once on initial setup

  Serial.begin(115200); // begin serial with 115200 baud rate
  Serial.setTimeout(100); // wait 100 ms for timeout (was originally 20 ms)

  randomSeed(analogRead(1)); //seed rng with reading from pin 1
  analogWriteResolution(12);      // set DACs to 12-bit resolution
  analogWrite(DAC0, 0);      // just to initialize this DAC

  // close all doors
  servoLeft.attach(servoPin1); //attach servo to pin
  servoLeft.write(ServoClosed); //set to closed
  servoCenter.attach(servoPin2); //attach servo to pin
  servoCenter.write(ServoClosed); //set to closed
  servoRight.attach(servoPin3); //attach servo to pin
  servoRight.write(ServoClosed); //set to closed
  servoCenterRight.attach(servoPin4); //attach servo to pin
  servoCenterRight.write(ServoClosed); //set to closed
  servoCenterLeft.attach(servoPin5); //attach servo to pin
  servoCenterLeft.write(ServoClosed); //set to closed

  // configure output pins
  pinMode(initPokeTTL, INPUT);
  pinMode(leftPokeTTL, INPUT);
  pinMode(centerPokeTTL, INPUT);
  pinMode(rightPokeTTL, INPUT);
  pinMode(centerRightPokeTTL, INPUT);
  pinMode(centerLeftPokeTTL, INPUT);

  pinMode(syringePumpInit, OUTPUT);      // connected to init pump - in phase 6-7, used for center port
  pinMode(syringePumpLeft, OUTPUT);      // connected to left pump
  pinMode(syringePumpRight, OUTPUT);     // connect to right pump
  pinMode(syringePumpCenter, OUTPUT);  // not connected
  pinMode(syringePumpCenterLeft, OUTPUT);    // not connected
  pinMode(syringePumpCenterRight, OUTPUT);  // not connected


  pinMode(whiteNoiseTTL, OUTPUT);
  pinMode(auditoryCueTTL, OUTPUT);
  pinMode(visualCueTTL, OUTPUT);
  pinMode(lowCueTTL, OUTPUT);
  pinMode(highCueTTL, OUTPUT);
  pinMode(pulsePal1, OUTPUT);
  pinMode(pulsePal2, OUTPUT);
  pinMode(triggerPin, OUTPUT);

  // turn all LEDs off
  cueLED1.off();
  cueLED2.off();
  cueLED3.off();
  cueLED4.off();
  cameraLED.off();


  state = standby; // default state

  // giving pulse to shut off the init syringe pump
  delay(100);
  initPulse();
}



// herein lies the finite state machine
void loop() {

  t.update(); // update timer with each cycle
  if (micros() - lastLoopTimeMicros >= slowDTmicros) {
    checkDoors();   // update door state as per matlab instruction
    checkRewards(); // update reward state as per matlab instruction
    checkPokes();   // check nosepokes
  }

  switch (state) {

    // STANDBY - the default state when not running trials
    case standby: // wait for matlab instructions, initialize trial counter as per matlab, wait for go signal

      processMessage();
      delayMicroseconds(pauseLengthMicros);

      // if triggered by matlab, transition to readyToGo
      if (resetTimeYN == 1) {
        DPRINTLN("time reset");
        resetTimeYN = 0;
        startTime = millis();
        digitalWrite(triggerPin, HIGH); // trigger the Intan
        delay(20);
        digitalWrite(triggerPin, LOW);
      }

      if (initPoke == 1 && initPokePunishYN == 1) { // if animal init pokes when not cued to do so
        serLog("InitPokeDuringStndby");
        initPokeError = 1; // this prevents "Standby" from going in the log, so that matlab doesn't get confused and think the trial is over.
        switchTo(missed);
        sndCounter = 0;
      }
      else if (startTrialYN == 1) {
        serLog("TrialAvailable");
        serLogNum("TrainingPhase", trainingPhase);
        serLogNum("NosePokeHoldLength", nosePokeHoldLength);
        digitalWrite(whiteNoiseTTL, HIGH);
        cameraLED.on();
        sndCounter = 0;
        switchTo(readyToGo);
        startTrialYN = 0;
        giveRewards(1);
        probsWritten = 0;
        trialAvailTime = millis();
      }


      break;

    // READY TO GO - waiting for mouse to nosepoke to initiate a trial
    case readyToGo:
      playWhiteNoise();

      // if timeout, switch state to missed
      if ((millis() - tempTime) > readyToGoLength) {
        digitalWrite(whiteNoiseTTL, LOW);
        cameraLED.off();
        serLogNum("TrialMissedBeforeInit", millis() - trialAvailTime);
        sndCounter = 0;
        switchTo(missed);
      }

      // if nosepoke, go to PRECUE
      if (initPoke == 1) {
        nosePokeInitTime = millis();
        digitalWrite(whiteNoiseTTL, LOW);
        cameraLED.off();
        serLogNum("TrialStarted", millis() - trialAvailTime);
        sndCounter = 0;
        switchTo(preCue);
        giveRewards(2);
      }
      break;

    // MISSED - should play a punishment buzzer, but not tested yet
    case missed:
      playBuzzer();

      // wait for timeout, go to punishDelay
      if ((millis() - tempTime) > missedLength) {
        closePoke("all");
        serLog("PunishDelay");
        switchTo(punishDelay);
      }
      break;

    // PRECUE - pause before the cue, check for nosepoke withdrawal
    case preCue:
      // if mouse withdraws nose, go to missed
      if ((initPoke == 0) && (nosePokeHoldLength > (millis() - nosePokeInitTime))) {
        serLogNum("PreCueWithdrawal", millis() - nosePokeInitTime);
        switchTo(missed);
        sndCounter = 0;
      }

      // if mouse holds long enough, start one of the cues
      else if ((millis() - tempTime) > preCueLength) {
        if (cueHiLow == -1) {
          digitalWrite(lowCueTTL, HIGH);
          serLog("LowCue");
          if (isLeftLow == 1) {
            serLog("LeftCue");
          }
          else {
            serLog("RightCue");
          }
        }
        else if (cueHiLow == 1) {
          digitalWrite(highCueTTL, HIGH);
          serLog("HighCue");
          if (isLeftLow == 1) {
            serLog("RightCue");
          }
          else {
            serLog("LeftCue");
          }
        }

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
          switchTo(noCue);
        }

        if (auditoryOrVisualCue == 1 && cueHiLow != 0) {
          digitalWrite(auditoryCueTTL, HIGH);
          switchTo(auditoryCue);
          serLog("AuditoryCue");
        }
        if (auditoryOrVisualCue == 2 && cueHiLow != 0) {
          digitalWrite(visualCueTTL, HIGH);
          switchTo(visualCue);
          serLog("VisualCue"); 
        }
      }
      delayMicroseconds(pauseLengthMicros);
      break;

    // AUDITORY CUE - auditory stimulus given, check for nosepoke withdrawal
    case auditoryCue:
      if (cueHiLow == -1)
        playLowTone();

      else if (cueHiLow == 1)
        playHighTone();

      if (initPoke == 0 && nosePokeHoldLength > (millis() - nosePokeInitTime)) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }
      else if ((millis() - tempTime) > auditoryCueLength) {
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        switchTo(postCue);
      }
      break;

    // VISUAL CUE - visual stimulus given, check for nosepoke withdrawal
    case visualCue:
      if (cueHiLow == 1) { // high LEDs
        cueLED1.on();
        cueLED3.on();
      }
      else if (cueHiLow == -1) { // low LEDs
        cueLED2.on();
        cueLED4.on();
      }

      if (initPoke == 0 && nosePokeHoldLength > (millis() - nosePokeInitTime)) {
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
      else if (millis() - tempTime > visualCueLength) {
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

    // NO CUE - check for nosepoke withdrawal
    case noCue:

      if (initPoke == 0 && nosePokeHoldLength > (millis() - nosePokeInitTime)) {
        serLogNum("CueWithdrawal", millis() - nosePokeInitTime);
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        sndCounter = 0;
        switchTo(missed);
      }

      else if (millis() - tempTime > visualCueLength) {
        digitalWrite(lowCueTTL, LOW);
        digitalWrite(highCueTTL, LOW);
        switchTo(postCue);
      }
      break;


    // POSTCUE - pause after cue, check for nosepoke withdrawal
    case postCue:
      if (initPoke == 0  && nosePokeHoldLength > (millis() - nosePokeInitTime)) {
        serLogNum("PostCueWithdrawal", millis() - nosePokeInitTime);
        sndCounter = 0;
        switchTo(missed);
      }
      else if (millis() - tempTime > postCueLength) {
        if (LopenYN == 1)
          openPoke("left");
        if (CLopenYN == 1)
          openPoke("centerLeft");
        if (RopenYN == 1)
          openPoke("right");
        if (CRopenYN == 1)
          openPoke("centerRight");
        if (CopenYN == 1)
          openPoke("center");
        switchTo(goToPokes);
        giveRewards(3); // give all rewards with this reward code
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

    // PUNISHDELAY: delay period after error trial
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
      if (trainingPhase == 1) {
        if (LrewardCode == 3 && leftPoke == 1) {
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("LeftRewardCollected", LrewardLength);
          switchTo(getReward);
        }
        if (RrewardCode == 3 && rightPoke == 1) {
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("RightRewardCollected", RrewardLength);
          switchTo(getReward);
        }

        if (LrewardCode != 3 && RrewardCode != 3) {
          serLog("Error_reward_codes_set_incorrectly");
          goToStandby = 1;
        }
      }

      // trainingPhase 2-3: ports are only rewarded after nosepoke, no punishment. In phase2, 1 door opens. In phase3, 2 doors open.
      if (trainingPhase == 2 || trainingPhase == 3) {
        if (LrewardCode == 4 && leftPoke == 1) {
          leftReward(leftPump);
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("LeftRewardCollected", LrewardLength);
          switchTo(getReward);
        }
        if (RrewardCode == 4 && rightPoke == 1) {
          rightReward(rightPump);
          serLogNum("Correct", millis() - initPokeExitTime);
          serLogNum("RightRewardCollected", RrewardLength);
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
          serLogNum(String("CrewardProb"), CrewardProb);
          serLogNum(String("RrewardProb"), RrewardProb);
          //          serLogNum(String("CLrewardProb"), CLrewardProb);
          //          serLogNum(String("CRrewardProb"), CRrewardProb);
          probsWritten = 1;
        }

        // left side cued
        if ((isLeftLow == 1 && cueHiLow == -1) || (isLeftLow == 0 && cueHiLow == 1)) {
          if (rightPoke == 1) {
            serLogNum("ErrorPoke", millis() - initPokeExitTime);
            sndCounter = 0;
            switchTo(missed);
          }
          if (leftPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if ((LrewardCode == 4) && (random(100) < LrewardProb)) {
              leftReward(leftPump);
              serLogNum("LeftRewardCollected", LrewardLength);
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
            switchTo(missed);
          }
          if (rightPoke == 1) {
            serLogNum("Correct", millis() - initPokeExitTime);
            if ((RrewardCode == 4) && (random(100) < RrewardProb)) {
              rightReward(rightPump);
              serLogNum("RightRewardCollected", RrewardLength);
              switchTo(getReward);
            }
            else {
              serLog("RightPokeNoReward");
              delay(300);
              goToStandby = 1;
            }
          }
        }

        // center poke (regardless of which cue given)
        if (centerPoke == 1) {
          serLogNum("CenterPoke", millis() - initPokeExitTime);

          if ((CrewardCode == 4) && (random(100) < CrewardProb)) { // if reward given
            serLogNum("CenterRewardCollected", CrewardLength);
            switchTo(getReward);

            else {
              centerReward(centerPump);
            }
          }

          else {  // if reward not given
            serLog("CenterPokeNoReward");
            delay(300);
            goToStandby = 1;
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





