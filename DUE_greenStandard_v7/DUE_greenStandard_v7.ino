//===================================================================================================>>
//                                          ARDUINO DUE + CUSTOM 'GREEN' SHIELD, THREE NOSEPOKE BOX  >>
//===================================================================================================>>

/*

  v7 - by Luke Sjulson, 2018-12-31. Making changes to work with python version
  of client. Will modify to match phase 1
  of the Jaramillo and Zador protocol better (center poke will trigger reward 
  release at side ports)	
  2019-12-23: also added stuff for drug self-admin (SA) and cue-induced reinstatement

  v6 - by Luke Sjulson, 2018-11-15. Now correctly follows modified version of the 
  Jaramillo and Zador protocol. Center poke is never rewarded.

  v5 - by Luke Sjulson, 2018-10-18. Rewritten to follow a modified version of the 
  training protocol in Jaramillo and Zador, Front Syst Neuro 2014

  v4 - by Luke Sjulson, 2018-09-07. Largely rewritten so that 1) there are no doors, 
  and 2) there are two cue slots.

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

*/

// tell matlab/python version 7 (changing this so it matches the version in the filename)
#define VERSION     7

// state definitions
#define standby         		1   // standby - the inactive state
#define readyToGo       		2   // plays white noise, waits for init poke
#define punishDelay     		3   // timeout period after animal makes mistake
#define preCue          		4   // time delay between white noise and cue
#define slot1                   5   // first cue slot
#define slot2                   6   // second cue slot
#define slot3                   7   // third cue slot
#define postCue         		8   // additional time delay
#define goToPokes       		9   // nosepokes open, animal can approach and collect reward
#define letTheAnimalDrink       10  // waiting for animal to collect reward
#define calibration             11  // state for calibrating the sound and light cue levels
#define testSyringes       12  // test syringes with switches
#define calibrateButton    13  // calibration button pressed
#define CSdelivery              201 // state to deliver CS for the animal in Trace apettitive conditioning
#define TracePeriod             202 // state for the trace period in TAC
#define SApreCue                301 // preCue for self-admin
#define SAcue                   302 // cue state for self-admin
#define SApostCue               303 // postCue state for self-admin


// include dependencies
#include <Arduino.h>
//#include "libraries/LED/LED.cpp"   // https://playground.arduino.cc/Code/LED - have to open LED.h and manually change Wprogram.h to Arduino.h
#include <Servo.h>
#include "libraries/Timer-master/Event.cpp" // https://playground.arduino.cc/Code/Timer
#include "libraries/Timer-master/Timer.cpp" // https://playground.arduino.cc/Code/Timer
//#include <string>
#include <avr/pgmspace.h> // might be required to store waveforms on flash instead of RAM
#include "toInclude/greenStandardFunctions_v7.cpp"
#include "toInclude/SA_states.cpp"


/*

phases 1 and 2 are different in v6, but the rest are the same as in v5
////////////////////////////////////////////////////////////////////////////
  PHASE 1. collection: no white noise, mice get reward (in side poke) for poking the "correct"
    sidepoke for that trial. Cue is given when animal does correct side poke. 
  PHASE 2. initiation: white noise, animal must center poke to get reward delivered in side poke
  PHASE 3. fast choice: white noise, center poke, cue given, then animal must collect
    the reward within four seconds.
  PHASE 4. nosepoke hold through precue, then nosepoke hold through increased IOI (stimulus inter-onset interval)
  PHASE 5. correct choice: full task with punishment for incorrect choice
////////////////////////////////////////////////////////////////////////////


phase 1xx (e.g.: 101,102) I'm saving for the head-fixed 2AFC [EFO]

phase 201 is for trace appetitive conditioning in head-fixed [EFO]

phase 301 is for drug self-admin, cue-induced reinstatement, etc.

reward codes - they are independent of which poke is rewarded
 -1 - punish for incorrect nosepoke during goToPokes
  0 - no reward
  1 - reward at ready signal
  2 - reward on init nose poke
  3 - reward at end of cue
  4 - reward only upon nosepoke

slot1_vis/slot2_vis/slot3_vis codes
  0 - no visual cue
  1 - LEDs 1 and 2 on
  2 - LEDs 3 and 4 on
  3 - all LEDs on

slot1_aud/slot2_aud/slot3_aud codes
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
  pinMode(leftCueTTL, OUTPUT);   
  pinMode(rightCueTTL, OUTPUT);  
  pinMode(pulsePal1, OUTPUT);
  pinMode(pulsePal2, OUTPUT);
  pinMode(triggerPin, OUTPUT);
  pinMode(cameraTrigTTL, OUTPUT);

  // turn all LEDs off.
  setLEDlevel(cueLED1pin, 0);
  setLEDlevel(cueLED2pin, 0);
  setLEDlevel(cueLED3pin, 0);
  setLEDlevel(cueLED4pin, 0);
  setLEDlevel(cueLED5pin, 0);
  setLEDlevel(cueLED6pin, 0);
  digitalWrite(cameraTrigTTL, LOW);
  
  // switches pins 
  pinMode(ip1, INPUT_PULLUP); 
  pinMode(ip2, INPUT_PULLUP); 
  pinMode(ip3, INPUT_PULLUP); 
  pinMode(ip4, INPUT_PULLUP); 
  pinMode(button,INPUT); 

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
    checkSwitches(); // checking switches on

    if (cameraRecordingYN==1) {
      triggerCamera();
    }
    else {
      digitalWrite(cameraTrigTTL, LOW);
    }

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
        uncollectedInitRewardYN  = 0;          // clear any uncollected rewards when timer is reset
        uncollectedLeftRewardYN  = 0;
        uncollectedRightRewardYN = 0;
         
      }
      

      // prevent the animal from starting a trial before white noise/"readyToGo" state:
      if (initPoke == 1 && initPokePunishYN == 1) { // if animal init pokes when not cued to do so (before white noise)
        serLog("InitPokeDuringStndby");
        initPokeError = 1; // this prevents "Standby" from going in the log, so that matlab doesn't get confused and think the trial is over.
        switchTo(punishDelay);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        sndCounter = 0;
      }

      // start a trial if triggered by matlab, switch state to READY TO GO
      else if (startTrialYN == 1) { // if matlab wants to start a trial
        serLog("TrialAvailable");
        serLogNum("TrainingPhase", trainingPhase);

        if (trainingPhase < 200){
          serLogNum("requiredPokeHoldLength_ms", preCueLength + slot1Length + slot2Length + slot3Length + postCueLength);
          serLogNum("goToPokesLength", goToPokesLength);
          serLogNum("trialLRtype", trialLRtype);
          serLogNum("trialAVtype", trialAVtype);
          serLogNum("Lsize_nL", LrewardSize_nL);
          serLogNum("Isize_nL", IrewardSize_nL);
          serLogNum("Rsize_nL", RrewardSize_nL);
        }
        else if (trainingPhase > 200 && trainingPhase < 300){
          serLogNum("rewardSize_nL", IrewardSize_nL);
        }

        // fix: need to put any SA-relevant code here


        sndCounter = 0; // reset sound counter
        startTrialYN = 0; // reset startTrial
        trialAvailTime = millis(); // assign time in ms when trial becomes available/when you're switching to readyToGo state.
        
        ///////////////
        // pre-rewarding the trial available
        if (IrewardCode == 1){
          deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit); //give reward at init poke at ready signal (didn't work)
          serLogNum("initReward_nL", IrewardSize_nL);
        //giveRewards(1);
        }

        if (trainingPhase>1 & trainingPhase<200) {
          digitalWrite(whiteNoiseTTL, HIGH); // tell the intan you're going to the readyToGo state/you're about to start the white noise
        }
        switchTo(readyToGo);

      }

      // for calibrating the volume levels and cue light brightness
      if (calibrationLength > 0 ){//|| activatePump > 0) {
        // setting to max brightness. Voltage drop across resistor should be 10 mV
        setLEDlevel(cueLED1pin, 1023);
        setLEDlevel(cueLED2pin, 1023);
        setLEDlevel(cueLED3pin, 1023);
        setLEDlevel(cueLED4pin, 1023);

        switchTo(calibration);
        serLog("during calibration, LEDs are active with maximum intensity");
        serLog("voltage drop across cue LED resistor should be 10 mV");
        serLog("sound volume at center of chamber (with doors open) should be calibrated in dB");
        serLog("Volume can be between 0-255");
        serLog("whichSound: 1 -> lowCue, 2 -> highCue, 3 -> buzzer, 4 -> white noise");

        serLogNum("lowCueVolume", lowCueVolume);
        serLogNum("highCueVolume", highCueVolume);
        serLogNum("buzzerVolume", buzzerVolume);
        serLogNum("WNvolume", WNvolume);
      }
      
      if (switches_on > 0){ 
        switchTo(testSyringes); 
      }

      break;


    ////////////////////
    // READY TO GO
    // white noise starts
    // wait for mouse to nosepoke to initiate a trial

    case readyToGo:

	  if (trainingPhase >= 1 & trainingPhase < 200) {   
        playWhiteNoise();
      }
      
      // if timeout, switch state to punishDelay
      if ((millis() - tempTime) > readyToGoLength) { // if timeThisStateBegan_ms happened readyToGoLength_ms ago without a nosepoke, the mouse missed the trial.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
        serLogNum("TrialMissedBeforeInit_ms", millis() - trialAvailTime); // FIX: replace tempTime w/ trialAvailTime
        sndCounter = 0;
        serLogNum("punishDelayLength_ms", punishDelayLength);
        switchTo(punishDelay);
      }


      // switch state to PRE-CUE if 1) the mouse init pokes, or 2) any poke is activated during phase 1

      if (initPoke == 1 && trainingPhase < 301) { // init poke activated
        tempInit = 1;
      }
      if ((trainingPhase == 1  || trainingPhase == 11)  && leftPoke == 1 && LrewardCode > 0) {
        tempInit = 1;
      }
      if ((trainingPhase == 1 || trainingPhase == 11) && rightPoke == 1 && RrewardCode > 0) {
        tempInit = 1;
      }

      if (tempInit == 1 && trainingPhase<200) {
        tempInit = 0;

        // if trainingPhase == 0, the arduino wasn't set up properly
        if (trainingPhase == 0) {
          serLog("Error_trainingPhaseIsZero");
          switchTo(standby);
        }

        nosePokeInitTime = millis(); // record time when mouse begins the init poke specifically. used to make sure mouse holds long enough.
        digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.

        serLogNum("TrialStarted_ms", millis() - trialAvailTime);
        sndCounter = 0;
        if (cueWithdrawalPunishYN==0){ //added by EFO to avoid rewarding before 
          giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) //EFO: I think we need to move this 
        }
        switchTo(preCue);
      }
      else if (tempInit == 1 && trainingPhase == 201){
        tempInit = 0;
        nosePokeInitTime = millis();
        sndCounter = 0;
      }

       if (cueWithdrawalPunishYN==0){ //added by EFO to avoid rewarding before 
          giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) //EFO: I think we need to move this 
        } 
        switchTo(preCue); 
      } 
      else if (tempInit == 1 && trainingPhase == 201){ 
        tempInit = 0; 
        nosePokeInitTime = millis(); 
        sndCounter = 0; 
      } 
 
      // if mouse pokes the wrong poke in phase 5, go to punishDelay 
      if (trainingPhase >= 5 && trainingPhase <= 10 && trainingPhase >= 12 && trainingPhase <= 99) { 
        if (leftPoke==1 || rightPoke==1) {
          digitalWrite(whiteNoiseTTL, LOW); // stop signaling the intan that white noise is playing.
          serLogNum("ErrorPokeBeforeInit_ms", millis() - trialAvailTime); 
          sndCounter = 0;
          serLogNum("punishDelayLength_ms", punishDelayLength);
          switchTo(punishDelay);
        }
      }
      
      if (trainingPhase == 201){
       //digitalWrite(auditoryCueTTL, HIGH);
       
       if (ITItime < (millis() - LastTrialTime) & flagITI){
        flagITI = false;
        serLogNum("CS_delivered",millis()-trialAvailTime);
        toneTime = millis();
        switchTo(CSdelivery);
        }
      }

      // stuff for trainingPhase 301 (self-admin and cue-induced reinstatement)
      if (trainingPhase == 301 && initPokesToInitiate > 0 && (initPokeCounter >= initPokesToInitiate)) {
      	if (IrewardCode == 2) {
		  deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
          serLogNum("initReward_nL", IrewardSize_nL);
      	}
      	whichPokeStartedTrial = 2; // 2 for init
      	serLogNum("TrialStartedInitPokes", initPokeCounter);
      	serLogNum("TrialStarted_ms", millis() - trialAvailTime);
      	initPokeCounter   = 0;
      	leftPokeCounter   = 0;
      	rightPokeCounter  = 0;
      	LrewardCode = 0; // this is so that the other pokes don't get rewarded
      	RrewardCode = 0;
        sndCounter = 0;
        switchTo(SApreCue);
      }

      if (trainingPhase == 301 && leftPokesToInitiate > 0 && (leftPokeCounter >= leftPokesToInitiate)) {
      	if (LrewardCode == 2) {
		  deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
          serLogNum("leftReward_nL", IrewardSize_nL);
      	}
      	whichPokeStartedTrial = 1; // 1 for left
      	serLogNum("TrialStartedLeftPokes", leftPokeCounter);
      	serLogNum("TrialStarted_ms", millis() - trialAvailTime);
      	initPokeCounter   = 0;
      	leftPokeCounter   = 0;
      	rightPokeCounter  = 0;
      	IrewardCode = 0; // this is so that the other pokes don't get rewarded
      	RrewardCode = 0;
        sndCounter = 0;
        switchTo(SApreCue);
      }

      if (trainingPhase == 301 && rightPokesToInitiate > 0 && (rightPokeCounter >= rightPokesToInitiate)) {
      	if (RrewardCode == 2) {
		  deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
          serLogNum("rightReward_nL", IrewardSize_nL);
      	}
      	whichPokeStartedTrial = 3; // 3 for right
      	serLogNum("TrialStartedRightPokes", rightPokeCounter);
      	serLogNum("TrialStarted_ms", millis() - trialAvailTime);
      	initPokeCounter   = 0;
      	leftPokeCounter   = 0;
      	rightPokeCounter  = 0;
      	IrewardCode = 0; // this is so that the other pokes don't get rewarded
      	LrewardCode = 0;
        sndCounter = 0;
        switchTo(SApreCue);
      }

      break;






    ////////////////////
    // PRE-CUE
    // pause before the cue, check for nosepoke withdrawal

    case preCue:

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0 && leftPoke==0 && rightPoke==0 && cueWithdrawalPunishYN==1) {
        serLogNum("PreCueWithdrawal_ms", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
      // start one of the cues when preCueLength time elapsed.
      else if ((millis() - tempTime) > preCueLength) {
        switchTo(slot1);

        // turn on visual cues
        if (slot1_vis==1) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot1_vis==2) {
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot1_vis==3) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot1_vis==4) { 
          setLEDlevel(cueLED4pin, cueLED3Brightness); 
          digitalWrite(visualCueTTL, HIGH); 
        } 
        else if (slot1_vis==5) { 
          setLEDlevel(cueLED3pin, cueLED4Brightness); 
          digitalWrite(visualCueTTL, HIGH); 
        } 
        // turn on auditory cue TTL
        if (slot1_aud > 0) {
          digitalWrite(auditoryCueTTL, HIGH);
        }
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


    ////////////////////
    // CUE1
    // First cue, check for nosepoke withdrawal

    case slot1:

      // play auditory cues
      if (slot1_aud==1) {
        playLowTone();
      }
      else if (slot1_aud==2) {
        playHighTone();
      }
      else if (slot1_aud==3) {
        playBuzzer();
      }
      else if (slot1_aud==4) {
        playWhiteNoise();
      }


      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0 && leftPoke==0 && rightPoke==0 && cueWithdrawalPunishYN==1) { // EFO: added leftPoke and rightPoke 
        // turn off any visual cues
        setLEDlevel(cueLED1pin, 0);
        setLEDlevel(cueLED2pin, 0);
        setLEDlevel(cueLED3pin, 0);
        setLEDlevel(cueLED4pin, 0);
        digitalWrite(visualCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);

        serLogNum("Cue1Withdrawal_ms", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        digitalWrite(visualCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        switchTo(punishDelay);
      }

      // mouse held long enough
      else if ((millis() - tempTime) > slot1Length) {

        // turn on/off any visual cues
        if (slot2_vis==0) {
          // turn off any visual cues
          setLEDlevel(cueLED1pin, 0);
          setLEDlevel(cueLED2pin, 0);
          setLEDlevel(cueLED3pin, 0);
          setLEDlevel(cueLED4pin, 0);
          digitalWrite(visualCueTTL, LOW);
        }
        else if (slot2_vis==1) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          setLEDlevel(cueLED3pin, 0);
          setLEDlevel(cueLED4pin, 0);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot2_vis==2) {
          setLEDlevel(cueLED1pin, 0);
          setLEDlevel(cueLED2pin, 0);
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot2_vis==3) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot2_vis==4) { 
          setLEDlevel(cueLED1pin, 0); 
          setLEDlevel(cueLED2pin, 0); 
          setLEDlevel(cueLED3pin, 0); 
          setLEDlevel(cueLED4pin, cueLED4Brightness); 
          digitalWrite(visualCueTTL, HIGH); 
        } 
        else if (slot2_vis==5) { 
          setLEDlevel(cueLED1pin, 0); 
          setLEDlevel(cueLED2pin, 0); 
          setLEDlevel(cueLED3pin, cueLED3Brightness); 
          setLEDlevel(cueLED4pin, 0); 
          digitalWrite(visualCueTTL, HIGH); 
        } 
        // turn on/off auditory cue TTL
        if (slot2_aud == 0) {
          digitalWrite(auditoryCueTTL, LOW);
        }
        else {
          digitalWrite(auditoryCueTTL, HIGH);
        }

  		switchTo(slot2);
      }

      delayMicroseconds(pauseLengthMicros); 
      break;


    ////////////////////
    // CUE2
    // second cue slot, check for nosepoke withdrawal

    case slot2:

      // play auditory cues
      if (slot2_aud==1) {
        playLowTone();
      }
      else if (slot2_aud==2) {
        playHighTone();
      }
      else if (slot2_aud==3) {
        playBuzzer();
      }
      else if (slot2_aud==4) {
        playWhiteNoise();
      }

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0  && leftPoke==0 && rightPoke==0 && cueWithdrawalPunishYN==1) { // EFO added leftPoke and rightPoke 
        // turn off any visual cues
        setLEDlevel(cueLED1pin, 0);
        setLEDlevel(cueLED2pin, 0);
        setLEDlevel(cueLED3pin, 0);
        setLEDlevel(cueLED4pin, 0);
        digitalWrite(visualCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);

        serLogNum("InterCueWithdrawal_ms", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        digitalWrite(visualCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);
        switchTo(punishDelay);
      }

      // otherwise mouse held long enough:
       else if ((millis() - tempTime) > slot2Length) {

        // turn on/off visual cues
        if (slot3_vis==0) {
          // turn off any visual cues
          setLEDlevel(cueLED1pin, 0);
          setLEDlevel(cueLED2pin, 0);
          setLEDlevel(cueLED3pin, 0);
          setLEDlevel(cueLED4pin, 0);
          digitalWrite(visualCueTTL, LOW);
        }
        else if (slot3_vis==1) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          setLEDlevel(cueLED3pin, 0);
          setLEDlevel(cueLED4pin, 0);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot3_vis==2) {
          setLEDlevel(cueLED1pin, 0);
          setLEDlevel(cueLED2pin, 0);
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot3_vis==3) {
          setLEDlevel(cueLED1pin, cueLED1Brightness);
          setLEDlevel(cueLED2pin, cueLED2Brightness);
          setLEDlevel(cueLED3pin, cueLED3Brightness);
          setLEDlevel(cueLED4pin, cueLED4Brightness);
          digitalWrite(visualCueTTL, HIGH);
        }
        else if (slot3_vis==4) { 
          setLEDlevel(cueLED1pin, 0); 
          setLEDlevel(cueLED2pin, 0); 
          setLEDlevel(cueLED3pin, 0); 
          setLEDlevel(cueLED4pin, cueLED4Brightness); 
          digitalWrite(visualCueTTL, HIGH); 
        } 
        else if (slot3_vis==5) { 
          setLEDlevel(cueLED1pin, 0); 
          setLEDlevel(cueLED2pin, 0); 
          setLEDlevel(cueLED3pin, cueLED3Brightness); 
          setLEDlevel(cueLED4pin, 0); 
          digitalWrite(visualCueTTL, HIGH); 
        } 

        // turn on/off auditory cue TTL
        if (slot3_aud == 0) {
          digitalWrite(auditoryCueTTL, LOW);
        }
        else {
          digitalWrite(auditoryCueTTL, HIGH);
        }
        switchTo(slot3);
      }

      delayMicroseconds(pauseLengthMicros); 
      break;

    ////////////////////
    // CUE3
    // third cue slot, check for nosepoke withdrawal

    case slot3:

      // play auditory cues
      if (slot3_aud==1) {
        playLowTone();
      }
      else if (slot3_aud==2) {
        playHighTone();
      }
      else if (slot3_aud==3) {
        playBuzzer();
      }
      else if (slot3_aud==4) {
        playWhiteNoise();
      }

      // if mouse withdraws nose too early, switch state to punishDelay
      if (initPoke == 0 &&  leftPoke==0 && rightPoke==0 && cueWithdrawalPunishYN==1) { //EFO: added leftPoke and rightPoke 
        // turn off any visual cues
        setLEDlevel(cueLED1pin, 0);
        setLEDlevel(cueLED2pin, 0);
        setLEDlevel(cueLED3pin, 0);
        setLEDlevel(cueLED4pin, 0);
        digitalWrite(visualCueTTL, LOW);
        digitalWrite(auditoryCueTTL, LOW);

        serLogNum("Cue2Withdrawal_ms", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        switchTo(punishDelay);

      }

      // otherwise mouse held long enough:
      // start one of the cues when slot3Length time elapsed.
      else if ((millis() - tempTime) > slot3Length) {
        // turn off any visual cues
        setLEDlevel(cueLED1pin, 0);
        setLEDlevel(cueLED2pin, 0);
        setLEDlevel(cueLED3pin, 0);
        setLEDlevel(cueLED4pin, 0);
        digitalWrite(visualCueTTL, LOW);

        // turn off auditory cue TTL
        digitalWrite(auditoryCueTTL, LOW);

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
      if (initPoke == 0 && leftPoke==0 && rightPoke==0 && cueWithdrawalPunishYN==1) { // EFO: added leftPoke and rightPoke 
        serLogNum("postCueWithdrawal_ms", millis() - nosePokeInitTime);
        serLogNum("punishDelayLength_ms", punishDelayLength);
        switchTo(punishDelay);
      }

       // otherwise mouse held long enough: 
      // start one of the cues when postCueLength time elapsed. 
      else if ((millis() - tempTime) > postCueLength) { 
        if (cueWithdrawalPunishYN==1){ //added by EFO, so the animals get reward if held long enough 
            if (trainingPhase == 1 || trainingPhase == 2 || trainingPhase == 11){ 
              if (leftPoke == 1){ 
                deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft); 
                serLogNum("leftReward_nL", LrewardSize_nL); 
              } 
              else if (rightPoke == 1){ 
                deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight); 
                serLogNum("rightReward_nL", RrewardSize_nL); 
              } 
              else if (initPoke == 1){ 
                giveRewards(2); // give a reward to the location(s) with reward codes "2" (init at time of mouse poke) 
              } 
             } 
           
        }
        // pre-reward L or R pokes, but not if there's already an uncollected reward there from the last trial 
        if (LrewardCode==3 && uncollectedLeftRewardYN==0) { 
          deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft); 
          serLogNum("leftReward_nL", LrewardSize_nL); 
          uncollectedLeftRewardYN = 1; 
        } 
        if (RrewardCode==3 && uncollectedRightRewardYN==0) { 
          deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight); 
          serLogNum("rightReward_nL", RrewardSize_nL); 
          uncollectedRightRewardYN = 1; 
        } 
        if ((trainingPhase == 1 || trainingPhase == 11) && leftPoke==1 || rightPoke==1){ //added by EFO to make sure phase 1 works as it should 
          switchTo(letTheAnimalDrink); 
        } 
        else{ //EFO: to make sure other phases work as it should. 
          switchTo(goToPokes);  
        }
      }

      delayMicroseconds(pauseLengthMicros); 
      break;

    // state for self-admin and cue-induced reinstatement
    case SApreCue:
    	SApreCue_fxn();
    	break;
    case SAcue:
    	SAcue_fxn();
    	break;
    case SApostCue:
    	SApostCue_fxn();
    	break;

    ////////////////////
    // PUNISHDELAY
    // delay period after error trial

    case punishDelay:
      if ((millis() - tempTime) < punishSound)
      {
        playHighTone();
      }
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
      delayMicroseconds(pauseLengthMicros);
      break;



    ////////////////////
    // GOTOPOKES
    // animal is free to nosepoke the reward pokes
    // main place where training phase affects what happens

    case goToPokes:

      processMessage(); // read in input from matlab/console - allows canceling in middle of trial

      // if timeout, switch state to punishDelay
      if ((millis() - tempTime) > goToPokesLength) {
        serLogNum("TrialMissedAfterInit_ms", millis() - initPokeExitTime);
        sndCounter = 0;
        serLogNum("punishDelayLength_ms", punishDelayLength);
        switchTo(punishDelay);
        uncollectedInitRewardYN = 1; // not relevant unless you're pre-rewarding the init port
      }

      // if left poke occurs
      if (leftPoke==1) {

        // if reward is delivered upon nosepoke
        if (LrewardCode==2 || LrewardCode==3 || LrewardCode==4) {
          if (LrewardCode==4) {
            deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
            serLogNum("leftReward_nL", LrewardSize_nL);
          }
          serLog("leftRewardCollected");
          serLogNum("letTheAnimalDrink_ms", rewardCollectionLength);
          switchTo(letTheAnimalDrink);
        }
        
        // if nosepoke is an error
        if (LrewardCode==-1) {
          serLog("LeftPokeError");
          serLogNum("punishDelayLength_ms", punishDelayLength);
          switchTo(punishDelay);
        }
      }

      // if right poke occurs
      if (rightPoke==1) {

        // if reward is delivered upon nosepoke
        if (RrewardCode==2 || RrewardCode==3 || RrewardCode==4) {
          if (RrewardCode==4) {
            deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
            serLogNum("rightReward_nL", RrewardSize_nL);
          }
          serLog("rightRewardCollected");
          serLogNum("letTheAnimalDrink_ms", rewardCollectionLength);
          switchTo(letTheAnimalDrink);
        }

        //if nosepoke is an error
        if (RrewardCode==-1) {
          serLog("RightPokeError");
          serLogNum("punishDelayLength_ms", punishDelayLength);
          switchTo(punishDelay);
        }
      }

      // if init poke occurs in trainingPhase 301, pass through this state
      if (initPoke==1 && trainingPhase==301) {

        // if reward is delivered upon nosepoke
        if (IrewardCode==2 || IrewardCode==3 || IrewardCode==4) {
          if (IrewardCode==4) {
            deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
            serLogNum("initReward_nL", IrewardSize_nL);
          }
          serLog("initRewardCollected");
          serLogNum("letTheAnimalDrink_ms", rewardCollectionLength);
          switchTo(letTheAnimalDrink);
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

    ////////////////////
    //CS DELIVERY
    //CS delivery for Trace apettitive conditioning
    case CSdelivery:
      
       if (~flagITI & ( (millis() - toneTime) < 0.5*1000) ) {
         playLowTone();
       }
       else if(~flagITI & ( (millis() - toneTime) > 0.5*1000) ){
         switchTo(TracePeriod);
       }
       delayMicroseconds(pauseLengthMicros);
       break;
      

    ////////////////////
    //Trace Period
    //
    case TracePeriod:
        /*
       Following dudman work: Tone: 0.5s Trace: 1.5s, ITI: randomly permuted exponential distributions (mean of 10, 25 or 50)
       I have to insert here a tone for CS, encode a trace of 1.5 s without using delay and reward delivery after that time
       Check references for the time of each parameter.
       */
        if ( (millis() - toneTime) > 1.5*1000 ){ // 1.5 s of trace %after trace is over
           deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
           serLogNum("initReward_nL", IrewardSize_nL);
           LastTrialTime = millis();
           RandNum = random(0,100);
           ITItime = (-log( (RandNum/100) )+InterTrialInterval)*1000; //this is already in arduino time code
           while (ITItime > 120*1000 || ITItime < 6*1000){ //here I have problems that the ITI gets huge
             ITItime = (-log( (RandNum/100) )+InterTrialInterval)*1000; //this is already in arduino time code
           }
           serLogNum("ITIperiod_ms",ITItime);
           serLogNum("ITIfixed_s",InterTrialInterval);
           flagITI = true;
           switchTo(letTheAnimalDrink);
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
      
  //   1 - low tone
  //   2 - high tone
  //   3 - buzzer
  //   4 - white noise
      if (whichSound==1) {
        playLowTone();
      }
      else if (whichSound==2) {
        playHighTone();
      }
      else if (whichSound==3) {
        playBuzzer();
      }
      else if (whichSound==4) {
        playWhiteNoise();  
      }

      if(activatePump == 1){
//        serLog("You activated the pump");
        deliverReward_dc(5000, 1000, 5, syringePumpLeft);
        activatePump = 0;
      }
      else if (activatePump == 2){
        deliverReward_dc(5000, 1000, 5, syringePumpInit);
        activatePump = 0;
      }
      else if (activatePump == 3){
        deliverReward_dc(5000, 1000, 5, syringePumpRight);
        activatePump = 0;
      }

      if ((millis() - tempTime) > calibrationLength) {
        calibrationLength = 0;
        sndCounter = 0;
        switchTo(standby);
        setLEDlevel(cueLED1pin, 0);
        setLEDlevel(cueLED2pin, 0);
        setLEDlevel(cueLED3pin, 0);
        setLEDlevel(cueLED4pin, 0);
      }
    break;
    
    
    case testSyringes:

    
      if (fwd_on==1){
        if (syringeLeft==1 && syringeRight==0){
          fwd_syringe(syringePumpLeft);          
        } else if (syringeLeft==0 &&syringeRight==1){
          fwd_syringe(syringePumpRight);          
        } else if (syringeLeft==0 &&syringeRight==0){
          fwd_syringe(syringePumpInit);          
        }
      } else if (bwd_on==1){
        if (syringeLeft==1 && syringeRight==0){
          bwd_syringe(syringePumpLeft);          
        } else if (syringeLeft==0 && syringeRight==1){
          bwd_syringe(syringePumpRight);          
        } else if (syringeLeft==0 && syringeRight==0){
          bwd_syringe(syringePumpInit);          
        }
      }
      fwd_on = 0;
      bwd_on = 0;
      switches_on = 0;
      syringeLeft =0;
      syringeRight =0;
      syringeInit =0;
    
      switchTo(standby);
  break;

  case calibrateButton:
    if (syringeLeft==1 && syringeRight==0){
      button_press(syringePumpLeft);          
    } else if (syringeLeft==0 &&syringeRight==1){
      button_press(syringePumpRight);          
    } else if (syringeLeft==0 &&syringeRight==0){
      button_press(syringePumpInit);          
    }

    switchTo(standby);
    buttonDetected = 0;
  break;
  }
}
