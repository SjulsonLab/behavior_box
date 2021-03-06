/*
Daniela Cassataro v3 7/13/18
Luke Sjulson v4 9/6/2018
Adam Sugi v5 11/13/2019 - version adding priming switches
TO DO:
  . ctrl+f "FIX:" 


*/

// // for debugging
// //#define DEBUG   //If you comment out this line, the DPRINT & DPRINTLN lines are defined as blank.
// #ifdef DEBUG    //Macros are usually in all capital letters.
// #define DPRINT(...)    Serial.print(__VA_ARGS__)     //DPRINT is a macro, debug print
// #define DPRINTLN(...)  Serial.println(__VA_ARGS__)   //DPRINTLN is a macro, debug print with new line
// #else
// #define DPRINT(...)     //now defines a blank line
// #define DPRINTLN(...)   //now defines a blank line
// #endif 

using namespace std;

#include "arduino_waveforms.h" // stores the sound cues to send to DAC0 to play through the speaker
#include "arduino_waveform_buzzer.h" // stores the buzzer sound

// Pin definitions

// pins not sampled by Intan
#define servoPin1           36 // connected to servo
#define servoPin2           38 // connected to servo
#define servoPin3           40 // connected to servo
#define servoPin4           42 // not actually connected to a servo yet
#define servoPin5           44 // not actually connected to a servo yet

// cue lights
#define cueLED1pin          13
#define cueLED2pin          12
#define cueLED3pin          11
#define cueLED4pin          10
//#define cueLED5pin          9
//#define cueLED6pin          8

// syringe pumps - will add fourth syringe pump dedicated for init poke later
#define syringePumpInit        24  // connected to init pump
#define syringePumpLeft        26  // connected to left pump
#define syringePumpRight       28  // connected to right pump
#define extraPump4             30  // not actually connected
#define extraPump5             32  // not actually connected
#define extraPump6             34  // not actually connected

// five extra I/O pins that are not sampled by the intan
#define syringePumpENABLE   47      // we thought about using this pin to enable/disable the syringe pump driver, but for now it's not in use
#define extraTTL2           48
#define extraTTL3           49
#define extraTTL4           50
#define extraTTL5           52

//////////////////////////////////////////////////////////
// all the pins below are sampled by the Intan:
//////////////////////////////////////////////////////////

// nosepoke-related pins(6)
#define initPokeTTL         27
#define leftPokeTTL         29
#define rightPokeTTL        31
//#define extraPoke4TTL       33  // not connected
//#define extraPoke5TTL       35  // not connected
//#define extraPoke6TTL       37  // not connected

// pulsepal pins(2)
#define pulsePal1           51
#define pulsePal2           53

// pins related to cues and rewards(6)
#define whiteNoiseTTL       22
#define auditoryCueTTL      23
#define visualCueTTL        25
#define leftCueTTL          39
#define rightCueTTL         41
#define rewardTTL           43

// last two(2)
#define cameraTrigTTL       45
#define triggerPin          46

// switches inputs
#define ip1    8 
#define ip2    9
#define ip3    33
#define ip4    35
#define button 37

long doorCloseSpeed        = 1;    // original speed was 10 - can decrease if there are problems

// other global variables
long state                        = 1;     // state variable for finite state machine - set to 1 (standby)
long trainingPhase                = 0;     // phase of training - set by serial input
long sndCounter                   = 0;
unsigned long nosePokeInitTime    = 0;     
long slowDTmicros                 = 100;   // DT of slow loop in microseconds
long pauseLengthMicros            = 5;     // length of pause for each iteration of the fast loop
unsigned long lastCheckTimeMicros = 0;
int initPokeError                 = 0;     // gets set to 1 if the animal init pokes during standby
long nTrial                       = 0;     // trial number
int uncollectedInitRewardYN       = 0;     // gets set to 1 if the animal leaves an uncollected reward in the init poke
int uncollectedLeftRewardYN       = 0;     // gets set to 1 if the animal leaves an uncollected reward in the left poke
int uncollectedRightRewardYN      = 0;     // gets set to 1 if the animal leaves an uncollected reward in the right poke
long calibrationLength            = 0;     // amount of time for the system to stay in the calibration state
long frameRate                    = 30;    // frame rate to trigger camera at (in Hz)
long cueWithdrawalPunishYN        = 0;     // set to 1 to punish for withdrawal during cues


// variables for timing
unsigned long trialAvailTime           = 0;
unsigned long initPokeEntryTime        = 0;
unsigned long initPokeExitTime         = 0;
unsigned long leftPokeEntryTime        = 0;
unsigned long rightPokeEntryTime       = 0;
unsigned long extraPoke4EntryTime      = 0;
unsigned long extraPoke5EntryTime      = 0;
unsigned long extraPoke6EntryTime      = 0;
unsigned long lastFrameTime            = 0;

// ints to store nosepoke states
unsigned long pokeLastCheckTime;
long pokeDT           = 5;  // 5 ms by default
int initPoke          = 0;
int initPokeLast      = 0;
int initPokeReading   = 0;
int initPokeDetected  = 0;

int leftPoke          = 0;
int leftPokeLast      = 0;
int leftPokeReading   = 0;
int leftPokeDetected  = 0;

int rightPoke          = 0;
int rightPokeLast      = 0;
int rightPokeReading   = 0;
int rightPokeDetected  = 0;

int extraPoke4          = 0;
int extraPokeLast4      = 0;
int extraPokeReading4   = 0;
int extraPokeDetected4  = 0;

int extraPoke5          = 0;
int extraPokeLast5      = 0;
int extraPokeReading5   = 0;
int extraPokeDetected5  = 0;

int extraPoke6          = 0;
int extraPokeLast6      = 0;
int extraPokeReading6   = 0;
int extraPokeDetected6  = 0;

int tempInit            = 0; // temporary variable to simplify code
long debugMode          = 0;

// for phase 301 (self-admin and cue-induced reinstatement)
long initPokeCounter       = 0;
long leftPokeCounter       = 0;
long rightPokeCounter      = 0;
long initPokesToInitiate   = 0; // the number of pokes required for reward
long leftPokesToInitiate   = 0; // for inactive ports, set to 0
long rightPokesToInitiate  = 0;
int whichPokeStartedTrial  = 0; // 1 for left, 2 for init, 3 for right
long SA_leftAudCue         = 0;
long SA_initAudCue         = 0;
long SA_rightAudCue        = 0;
long SA_leftVisCue         = 0;
long SA_initVisCue         = 0;
long SA_rightVisCue        = 0;
int SAcue_aud              = 0; // temp variable for which cue plays this trial
long SAcueLength           = 0;


// servos to control nosepoke doors
#define ServoOpen      10 //position at which Servo is open
#define ServoClosed   150 //position at which Servo is closed
Servo servoInit; // not currently being used
Servo servoLeft;
Servo servoRight;
Servo extraServo4;
Servo extraServo5;

long initOpenNow         = 0; // set this to 1 to give command to open door
long leftOpenNow         = 0;
long rightOpenNow        = 0;
long extraPoke4OpenNow   = 0;
long extraPoke5OpenNow   = 0;

long initIsOpen          = 0; // this is set to 1 after the door is opened
long leftIsOpen          = 0;
long rightIsOpen         = 0;
long extraPoke4IsOpen    = 0;
long extraPoke5IsOpen    = 0;

// these will allow openPoke() and closePoke() to send commands to the servo only when
// there's a mismatch between the desired state and the actual state

// state-related variables - all durations in msec
long readyToGoLength        = 60000;
long missedLength           = 50;
long buzzerLength           = 100;
long punishDelayLength      = 5000;
long punishSound			= 200;
long preCueLength           = 50;
long slot1Length             = 200;
long slot2Length             = 10;
long slot3Length             = 10;
long postCueLength          = 50;
long goToPokesLength        = 60000;
long rewardCollectionLength = 3000;


// which cues get played
long slot1_vis               = 0;
long slot2_vis               = 0;
long slot3_vis               = 0; 
long slot1_aud               = 0;
long slot2_aud               = 0;
long slot3_aud               = 0;


long startTrialYN        = 0;   // 1 to start a trial
long resetTimeYN         = 0;   // 1 to reset the timer
long goToStandby         = 0;   // set to 1 using matlab to exit goToPokes state
long giveRewardNow       = 0;   // 1=init, 2=left, 3=right.
long initPokePunishYN    = 0;   // 1 to punish for init poke during standby, 0 is default
long cameraRecordingYN   = 0;   // 1 to start recording, 0 to pause


/* reward codes - they are independent of which poke is rewarded
   -1 - punish for incorrect nosepoke during goToPokes
    0 - no reward
    1 - reward init poke at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon successful nosepoke
*/

long IrewardCode            = 0; // determines if/when reward is given
long LrewardCode            = 0; 
long RrewardCode            = 0;
long extra4rewardCode       = 0;
long extra5rewardCode       = 0;
long extra6rewardCode       = 0;

long InterTrialInterval      = 0; // ITI for the TAC task. Implemented by EFO

long laserOnCode            = 0; // FIX: laserOnCode is set twice
long IopenYN                = 1; // whether to open L nosepoke upon goToPokes fix: should this be 1?
long LopenYN                = 1;
long RopenYN                = 1;
long extra4openYN           = 0;
long extra5openYN           = 0;

long lowCueVolume    = 128;
long highCueVolume   = 128;
long buzzerVolume    = 128; 
long WNvolume        = 128; // between 0-255
long whichSound      = 1;
long activatePump    = 0;
long cueLED1Brightness   = 255;
long cueLED2Brightness   = 255;
long cueLED3Brightness   = 255;
long cueLED4Brightness   = 255;
long cueLED5Brightness   = 255;
long cueLED6Brightness   = 255;

// globals for the syringe pumps
// these are all longs because matlab requires longs
long IrewardSize_nL          = 0;
long LrewardSize_nL          = 0;
long RrewardSize_nL          = 0;
long deliveryDuration_ms     = 1000;
long syringeSize_mL          = 5;

// these variables have no function other than to allow matlab to write them into the log file
long trialLRtype       = 0;   
long trialAVtype       = 0; 

// variables for training animal for trace appetitive conditioning
float RandNum = 0;
int ITItime = 0;
int toneTime = 0;
int LastTrialTime = 0;
bool flagITI = true;

// test syringe variables
int reading_switch1;
int reading_switch2;
int reading_switch3;
int reading_switch4;

int switch1_on = 0;
int switch2_on = 0;
int switch3_on = 0;
int switch4_on = 0;
int switches_on = 0;
int fwd_on = 0;
int bwd_on = 0;
int syringeLeft = 0;
int syringeRight = 0;
int syringeInit = 0;
int buttonReading = 0;
int buttonDetected = 0;


/*
//***********************************************
//              declare LEDs
//***********************************************
LED cueLED1   = LED(cueLED1pin);
LED cueLED2   = LED(cueLED2pin);
LED cueLED3   = LED(cueLED3pin);
LED cueLED4   = LED(cueLED4pin);
LED cueLED5   = LED(cueLED5pin);
LED cueLED6   = LED(cueLED6pin);
LED cameraLED = LED(cameraTrigTTL);  // will be connected to red or IR LED sampled by camera
*/


//***********************************************
//              stuff for logging
//***********************************************
Timer t; // declare timer

// startTime: time in ms for either..
// 1. start of trial=the last time the code exited standby. or
// 2. start of session=happens once at beginning of a session
unsigned long startTime;   
unsigned long tempTime = 0; // FIX: rename to timeThisStateBegan_ms
unsigned long logTime; // time for log data sent to matlab

// functions for logging
void serLog(String str) {
  logTime = millis() - startTime;
  Serial.print(String(logTime) + ";" + String(nTrial) + ";" + str + ";0\n");
}

void serLogNum(String str, long N) {
  logTime = millis() - startTime;
  Serial.print(String(logTime) + ";" + String(nTrial) + ";" + str +  ";" + String(N) + "\n");
}

// this function just resets the default values of the main state-related variables
void resetDefaults() {
  // state-related variables
  state             = 1;     // standby
  readyToGoLength   = 10000; // in msec
  missedLength      = 50; // in msec
  buzzerLength      = 100; // in msec
  punishDelayLength = 5000;
  preCueLength      = 50; // in msec
  slot1Length        = 200;
  slot2Length        = 10;
  slot3Length        = 10;
  postCueLength     = 50;
  goToPokesLength   = 10000; // in msec

  // cue-related variables
  slot1_vis               = 0;
  slot2_vis               = 0;
  slot3_vis               = 0; 
  slot1_aud               = 0;
  slot2_aud               = 0;
  slot3_aud               = 0;

  // other 
  IrewardCode            = 0; // when (and whether) a particular port is rewarded
  LrewardCode            = 0;
  RrewardCode            = 0;
  extra4rewardCode       = 0;
  extra5rewardCode       = 0;
  extra6rewardCode       = 0; //fix: make this extra 6

  initPokeCounter        = 0;
  leftPokeCounter        = 0;
  rightPokeCounter       = 0;
  initPokesToInitiate    = 0; // the number of pokes required for reward
  leftPokesToInitiate    = 0; // for inactive ports, set to 0
  rightPokesToInitiate   = 0;
  whichPokeStartedTrial  = 0;
  SA_leftAudCue         = 0;
  SA_initAudCue         = 0;
  SA_rightAudCue        = 0;
  SA_leftVisCue         = 0;
  SA_initVisCue         = 0;
  SA_rightVisCue        = 0;
  SAcueLength           = 0;

  laserOnCode            = 0;
  goToStandby            = 0; // set to 1 using matlab to exit goToPokes state
  giveRewardNow          = 0;

  uncollectedInitRewardYN    = 0; 

  trialLRtype       = 0;   
  trialAVtype       = 0; 


}

// debugging function that prints something only when debugging mode is on
void DPRINTLN(String tempStr) {
  if (debugMode==1) Serial.println(tempStr);
}

// this function changes the variable referred to by *ptr whenever varName is present in inLine
void changeVariableLong(String varName, long *ptr, String inLine) {
  String tempStr;
  long tempLong;
  if (inLine.startsWith(varName) != 0) {
    tempStr = inLine.substring(inLine.lastIndexOf(varName) + varName.length() + 1, inLine.length());
    tempLong = (long) tempStr.toInt();
    *ptr = tempLong;
    DPRINTLN(varName + String(*ptr));
  }
}

void changeVariableUnsignedLong(String varName, unsigned long *ptr, String inLine) {
  String tempStr;
  unsigned long tempLong;
  if (inLine.startsWith(varName) != 0) {
    tempStr = inLine.substring(inLine.lastIndexOf(varName) + varName.length() + 1, inLine.length());
    tempLong = (unsigned long) tempStr.toInt();
    *ptr = tempLong;
    DPRINTLN(varName + String(*ptr));
  }
}


// opening and closing nosepokes
void openPoke(String whichPoke) {
  if (whichPoke.equalsIgnoreCase("init") && initIsOpen == 0) {
    servoInit.write(ServoOpen);
    initIsOpen = initOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("left") && leftIsOpen == 0) {
    servoLeft.write(ServoOpen);
    leftIsOpen = leftOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("right") && rightIsOpen == 0) {
    servoRight.write(ServoOpen);
    rightIsOpen = rightOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("extraPoke4") && extraPoke4IsOpen == 0) {
    extraServo4.write(ServoOpen);
    extraPoke4IsOpen = extraPoke4OpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("extraPoke5") && extraPoke5IsOpen == 0) {
    extraServo5.write(ServoOpen);
    extraPoke5IsOpen = extraPoke5OpenNow = 1;
  }

  if (whichPoke.equalsIgnoreCase("all")) {
    servoInit.write(ServoOpen);
    servoLeft.write(ServoOpen);
    servoRight.write(ServoOpen);
    extraServo4.write(ServoOpen);
    extraServo5.write(ServoOpen);
    initIsOpen = leftIsOpen = rightIsOpen= extraPoke4IsOpen = extraPoke5IsOpen = 1;
    initOpenNow = leftOpenNow = rightOpenNow = extraPoke4OpenNow = extraPoke5OpenNow = 1;
  }
  //delay(15);
}

void closePoke(String whichPoke) {
  int servoTemp = ServoOpen;

  while (servoTemp <= ServoClosed) {
    if (whichPoke.equalsIgnoreCase("init") && initIsOpen == 1) {
      servoInit.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("left") && leftIsOpen == 1) {
      servoLeft.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("right") && rightIsOpen == 1) {
      servoRight.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("extraPoke4") && extraPoke4IsOpen == 1) {
      extraServo4.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("extraPoke5") && extraPoke5IsOpen == 1) {
      extraServo5.write(servoTemp);
    }

    if (whichPoke.equalsIgnoreCase("all")) {
      if (initIsOpen == 1) servoInit.write(servoTemp);
      if (leftIsOpen == 1) servoLeft.write(servoTemp);
      if (rightIsOpen == 1) servoRight.write(servoTemp);
      if (extraPoke4IsOpen == 1) extraServo4.write(servoTemp);
      if (extraPoke5IsOpen == 1) extraServo5.write(servoTemp);
    }
    //delay(15);
    servoTemp += doorCloseSpeed;
  }

  // after doors are closed, set variables to zero
  if (whichPoke.equalsIgnoreCase("init")) initIsOpen = initOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("left")) leftIsOpen = leftOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("right")) rightIsOpen = rightOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("extraPoke4")) extraPoke4IsOpen = extraPoke4OpenNow = 0;
  if (whichPoke.equalsIgnoreCase("extraPoke5")) extraPoke5IsOpen = extraPoke5OpenNow = 0;
  if (whichPoke.equalsIgnoreCase("all")) initIsOpen = leftIsOpen = rightIsOpen = extraPoke4IsOpen = extraPoke5IsOpen = initOpenNow = leftOpenNow = rightOpenNow = extraPoke4OpenNow = extraPoke5OpenNow = 0;

}

// function to allow matlab to open/close doors, e.g. if matlab sets leftOpenNow to be 1, it will open the door
void checkDoors() {
  if (initOpenNow > initIsOpen)
    openPoke("init");
  else if (initOpenNow < initIsOpen)
    closePoke("init");

  if (leftOpenNow > leftIsOpen)
    openPoke("left");
  else if (leftOpenNow < leftIsOpen)
    closePoke("left");

  if (rightOpenNow > rightIsOpen)
    openPoke("right");
  else if (rightOpenNow < rightIsOpen)
    closePoke("right");

  if (extraPoke4OpenNow > extraPoke4IsOpen)
    openPoke("extraPoke4");
  else if (extraPoke4OpenNow < extraPoke4IsOpen)
    closePoke("extraPoke4");

  if (extraPoke5OpenNow > extraPoke5IsOpen)
    openPoke("extraPoke5");
  else if (extraPoke5OpenNow < extraPoke5IsOpen)
    closePoke("extraPoke5");

}

void checkPokes()
{
  
  // read all the pokes
  initPokeReading = digitalRead(initPokeTTL);
  if (initPokeDetected==0 && initPokeReading==1)  { // if a poke is detected in this time window
    initPokeDetected = 1; 
    uncollectedInitRewardYN = 0; // this is in case the animal collects the reward between trials
  }

  leftPokeReading = digitalRead(leftPokeTTL);
  if (leftPokeDetected==0 && leftPokeReading==1)  { // if a poke is detected in this time window
    leftPokeDetected = 1;
    uncollectedLeftRewardYN = 0; // this is in case the animal collects the reward between trials
  }

  rightPokeReading = digitalRead(rightPokeTTL);
  if (rightPokeDetected==0 && rightPokeReading==1)  { // if a poke is detected in this time window
    rightPokeDetected = 1; 
    uncollectedRightRewardYN = 0; // this is in case the animal collects the reward between trials
  }

/*  // commenting out the extraPokes for now to prevent erroneous messages because they're not connected
  extraPokeReading4 = digitalRead(extraPoke4TTL);
  if ((extraPokeDetected4==0) && (extraPokeReading4==1))  { // if a poke is detected in this time window
    extraPokeDetected4 = 1; 
  }

  extraPokeReading5 = digitalRead(extraPoke5TTL);
  if ((extraPokeDetected5==0) && (extraPokeReading5==1))  { // if a poke is detected in this time window
    extraPokeDetected5 = 1; 
  }

  extraPokeReading6 = digitalRead(extraPoke6TTL);
  if ((extraPokeDetected6==0) && (extraPokeReading6==1))  { // if a poke is detected in this time window
    extraPokeDetected6 = 1; 
  }
*/
  
  // if enough time has passed, log and update status
  if (millis()-pokeLastCheckTime >= pokeDT) { 
  	pokeLastCheckTime = millis();
  	// DPRINTLN(String("POKECHECK: ") + String(pokeLastCheckTime));

    if ((initPokeLast==0) && (initPokeDetected==1)) { // init poke entry
    	serLog("initPokeEntry");
    	initPokeLast = initPokeDetected;
    	initPoke = 1;
      initPokeEntryTime = millis();
      initPokeCounter += 1;
    }
    else if ((initPokeLast==1) && (initPokeDetected==0)) { // init poke exit
    	serLogNum("initPokeExit_ms", millis() - initPokeEntryTime);
    	initPokeLast = initPokeDetected;
    	initPoke = 0;
      initPokeExitTime = millis();
    }

    if ((leftPokeLast==0) && (leftPokeDetected==1)) { // left poke entry
    	serLog("leftPokeEntry");
    	leftPokeLast = leftPokeDetected;
    	leftPoke = 1;
      leftPokeEntryTime = millis();
      leftPokeCounter += 1;
    }
    else if ((leftPokeLast==1) && (leftPokeDetected==0)) { // left poke exit
    	serLogNum("leftPokeExit_ms", millis() - leftPokeEntryTime);
    	leftPokeLast = leftPokeDetected;
    	leftPoke = 0;
    }

    if ((rightPokeLast==0) && (rightPokeDetected==1)) { // right poke entry
    	serLog("rightPokeEntry");
    	rightPokeLast = rightPokeDetected;
    	rightPoke = 1;
      rightPokeEntryTime = millis();
      rightPokeCounter += 1;
    }
    else if ((rightPokeLast==1) && (rightPokeDetected==0)) { // right poke exit
    	serLogNum("rightPokeExit_ms", millis() - rightPokeEntryTime);
    	rightPokeLast = rightPokeDetected;
    	rightPoke = 0;
    }

    if ((extraPokeLast4==0) && (extraPokeDetected4==1)) { // extra poke 4 entry
    	serLog("extraPokeEntry4");
    	extraPokeLast4 = extraPokeDetected4;
    	extraPoke4 = 1;
      extraPoke4EntryTime = millis();
    }
    else if ((extraPokeLast4==1) && (extraPokeDetected4==0)) { // extra poke 4 exit
    	serLogNum("extraPokeExit4_ms", millis() - extraPoke4EntryTime);
    	extraPokeLast4 = extraPokeDetected4;
    	extraPoke4 = 0;
    }

    if ((extraPokeLast5==0) && (extraPokeDetected5==1)) { // extra poke 5 entry
      serLog("extraPokeEntry5");
      extraPokeLast5 = extraPokeDetected5;
      extraPoke5 = 1;
      extraPoke5EntryTime = millis();
    }
    else if ((extraPokeLast5==1) && (extraPokeDetected5==0)) { // extra poke 5 exit
      serLogNum("extraPokeExit5_ms", millis() - extraPoke5EntryTime);
      extraPokeLast5 = extraPokeDetected5;
      extraPoke5 = 0;
    }

    if ((extraPokeLast6==0) && (extraPokeDetected6==1)) { // center poke entry
      serLog("extraPokeEntry6");
      extraPokeLast6 = extraPokeDetected6;
      extraPoke6 = 1;
      extraPoke6EntryTime = millis();
    }
    else if ((extraPokeLast6==1) && (extraPokeDetected6==0)) { // center poke exit
      serLogNum("extraPokeExit6_ms", millis() - extraPoke6EntryTime);
      extraPokeLast6 = extraPokeDetected6;
      extraPoke6 = 0;
    }

    initPokeDetected = 0;
    leftPokeDetected = 0;
    rightPokeDetected = 0;
    extraPokeDetected4 = 0;
    extraPokeDetected5 = 0;
    extraPokeDetected6 = 0;
  }
}

// triggering camera frame acquisition. This function should only be called when the camera is on
void triggerCamera() {
  unsigned long localTime;
  localTime = millis();

  if (digitalRead(cameraTrigTTL)==HIGH) {
    //digitalWrite(cameraTrigTTL, LOW);

    if ((localTime-lastFrameTime) >= 5) { // hard coding that a camera trigger pulse is 5 ms
      digitalWrite(cameraTrigTTL, LOW);
    }
  }
  else {
//    if ((localTime-lastFrameTime) >= 20) {
    if ((localTime-lastFrameTime) > round(1000 / frameRate)) {
      digitalWrite(cameraTrigTTL, HIGH);
      lastFrameTime = localTime;
//      serLogNum("frameTime_ms", localTime);
    }
  }
}

// triggering pulse pal
void triggerPulsePal(int oneOrTwo)
{
  if (oneOrTwo == 1) {
    t.pulse(pulsePal1, 10, LOW);
    serLog("triggerPulsePal1");
  }
  if (oneOrTwo == 2) {
    t.pulse(pulsePal2, 10, LOW);
    serLog("triggerPulsePal2");
  }
}

// playing sounds on DAC0
void playWhiteNoise() {
//  dacc_write_conversion_data(DACC_INTERFACE, whiteNoise[sndCounter++]); // old
  dacc_write_conversion_data(DACC_INTERFACE, whiteNoise[sndCounter++] * (float)WNvolume/255);
  if (sndCounter == seqLen)
    sndCounter = 0;
}

void playLowTone() {
  dacc_write_conversion_data(DACC_INTERFACE, lowFreq[sndCounter++] * (float)lowCueVolume/255);
  if (sndCounter == seqLen)
    sndCounter = 0;
}

void playHighTone() {
  dacc_write_conversion_data(DACC_INTERFACE, highFreq[sndCounter++] * (float)highCueVolume/255);
  if (sndCounter == seqLen)
    sndCounter = 0;
}

void playBuzzer() {
  dacc_write_conversion_data(DACC_INTERFACE, buzzer[sndCounter++] * (float)buzzerVolume/255);
  if (sndCounter == seqLen)
    sndCounter = 0;
}

/*
// used for doing after() on the enable pin which requires a callback in the argument
void make_ENABLE_pin_HIGH_which_is_off() {
  digitalWrite(syringePumpENABLE, HIGH); 
}
*/

// the dc syringe pump func.
// initialize the variables in the argument of the function definition:
void deliverReward_dc(long volume_nL, long local_deliveryDuration_ms, int local_syringeSize_mL, int whichPump) {
  double diameter_mm; 
  double volPerRevolution_uL;
  double howManyRevolutions; 
  unsigned long totalSteps; //can't have negative steps
  unsigned int minimumDeliveryDuration_ms;
  double stepDuration_ms;
  // the calcs are done in uL but because matlab needs expects longs it's converted from nL so we can have accuracy and whole numbers
  double volume_uL;
  volume_uL = (double)volume_nL/1000; 

  // set syringe diameter variable based on BD syringe standard sizes 5 or 10mL  
  if (local_syringeSize_mL == 5) {
    diameter_mm = 12.06; //in mm
  }
  if (local_syringeSize_mL == 10) {
    diameter_mm = 14.5; //in mm
  }
  if ((local_syringeSize_mL != 5) && (local_syringeSize_mL != 10)) {
    //Serial.println("didn't recognize syringe size. available sizes '5' or '10.'");
    //Serial.println("diameter_mm=");
    //Serial.println(diameter_mm); 
    return;
  } 

  // determine vol per revolution, area of small cylinder with h=0.8mm
  // 0.8mm length per thread. 1thread=1cycle. 1 like=1prayer.
  volPerRevolution_uL = 0.8 * ( diameter_mm/2 )*( diameter_mm/2 ) * 3.1415926535898 ; 
  
  // determine how many revolutions needed for the desired volume
  howManyRevolutions = volume_uL / volPerRevolution_uL ;

  // determine total steps needed to reach desired revolutions, @200 steps/revolution
  // use *4 as a multiplier because it's operating at 1/4 microstep mode.
  // round to nearest int because totalSteps is unsigned long
  totalSteps = round(200 * howManyRevolutions * 4);

  // determine shortest delivery duration, total steps * 2 ms per step. 
  // minimum 1 ms in high, 1 ms in low for the shortest possible step function.
  minimumDeliveryDuration_ms = totalSteps*2; 

  // make sure delivery duration the user wants is long enough
  if (local_deliveryDuration_ms < minimumDeliveryDuration_ms) {
      //Serial.println("duration too low. duration needs to be >");
      //Serial.println(minimumDeliveryDuration_ms); 
      //Serial.println("with that diameter and reward volume.");
      return;
    }

  // determine duration of each step for the timer oscillate function
  stepDuration_ms = (double)local_deliveryDuration_ms / totalSteps;

  // enable all pumps (low=on state) so we can move them
//  digitalWrite(syringePumpENABLE, LOW);
  //t.after((int)(100+local_deliveryDuration_ms), make_ENABLE_pin_HIGH_which_is_off); // FIX: every time "after()" is used needs to be fixed because it doesn't work like how luke thought it did
  // fix: use the "give immediate pulse" or whatever in the timer library code


  // tell the intan reward is delivered - need to test this
  t.pulseImmediate(rewardTTL, local_deliveryDuration_ms, LOW);
  
  // turn the pump motor
  t.oscillate(whichPump, round(stepDuration_ms/2), LOW, totalSteps*2);
}


void processMessage() {

  if (Serial.available() > 0) {
    String inLine;
    inLine = "";
    inLine = Serial.readStringUntil('\n');

    //DPRINTLN("Message received.");

    if (inLine.equalsIgnoreCase("checkVersion")) {
      char str[100];
      sprintf(str, "%d", VERSION);
      Serial.println(str);
    }
    if (inLine.equalsIgnoreCase("reset")) {
      resetDefaults();
    }

    // all the variables (ints) go here
    // order has been fixed w.matlab's order
    changeVariableLong("debugMode", &debugMode, inLine);    
    changeVariableLong("nTrial", &nTrial, inLine);
    changeVariableLong("InterTrialInterval", &InterTrialInterval, inLine);
    changeVariableLong("resetTimeYN", &resetTimeYN, inLine);
    changeVariableLong("initPokePunishYN", &initPokePunishYN, inLine);
    changeVariableLong("cameraRecordingYN", &cameraRecordingYN, inLine);
    changeVariableLong("frameRate", &frameRate, inLine);
    changeVariableLong("cueWithdrawalPunishYN", &cueWithdrawalPunishYN, inLine);

    changeVariableLong("WNvolume", &WNvolume, inLine);
    changeVariableLong("lowCueVolume", &lowCueVolume, inLine);
    changeVariableLong("highCueVolume", &highCueVolume, inLine);
    changeVariableLong("buzzerVolume", &buzzerVolume, inLine);
    changeVariableLong("calibrationLength", &calibrationLength, inLine);
    changeVariableLong("activatePump", &activatePump, inLine); //added by EFO
    changeVariableLong("whichSound", &whichSound, inLine);

    changeVariableLong("cueLED1Brightness", &cueLED1Brightness, inLine);
    changeVariableLong("cueLED2Brightness", &cueLED2Brightness, inLine);
    changeVariableLong("cueLED3Brightness", &cueLED3Brightness, inLine);
    changeVariableLong("cueLED4Brightness", &cueLED4Brightness, inLine);
    changeVariableLong("cueLED5Brightness", &cueLED5Brightness, inLine);
    changeVariableLong("cueLED6Brightness", &cueLED6Brightness, inLine);

    changeVariableLong("trainingPhase", &trainingPhase, inLine);
    changeVariableLong("doorCloseSpeed", &doorCloseSpeed, inLine);
    changeVariableLong("laserOnCode", &laserOnCode, inLine);

    changeVariableLong("IopenYN", &IopenYN, inLine);
    changeVariableLong("LopenYN", &LopenYN, inLine);
    changeVariableLong("RopenYN", &RopenYN, inLine);
    changeVariableLong("extra4openYN", &extra4openYN, inLine);
    changeVariableLong("extra5openYN", &extra5openYN, inLine);

    changeVariableLong("readyToGoLength", &readyToGoLength, inLine);
    changeVariableLong("punishDelayLength", &punishDelayLength, inLine);
    changeVariableLong("missedLength", &missedLength, inLine);
    changeVariableLong("buzzerLength", &buzzerLength, inLine);
    
    changeVariableLong("preCueLength", &preCueLength, inLine);
    changeVariableLong("slot1Length", &slot1Length, inLine);
    changeVariableLong("slot2Length", &slot2Length, inLine);
    changeVariableLong("slot3Length", &slot3Length, inLine);
    changeVariableLong("postCueLength", &postCueLength, inLine);
    changeVariableLong("goToPokesLength", &goToPokesLength, inLine);
    changeVariableLong("rewardCollectionLength", &rewardCollectionLength, inLine);

    changeVariableLong("slot1_vis", &slot1_vis, inLine);
    changeVariableLong("slot2_vis", &slot2_vis, inLine);
    changeVariableLong("slot3_vis", &slot3_vis, inLine);
    
    changeVariableLong("slot1_aud", &slot1_aud, inLine);
    changeVariableLong("slot2_aud", &slot2_aud, inLine);
    changeVariableLong("slot3_aud", &slot3_aud, inLine);


    // reward codes
    changeVariableLong("IrewardCode", &IrewardCode, inLine);
    changeVariableLong("LrewardCode", &LrewardCode, inLine);
    changeVariableLong("RrewardCode", &RrewardCode, inLine);
    changeVariableLong("extra4rewardCode", &extra4rewardCode, inLine);
    changeVariableLong("extra5rewardCode", &extra5rewardCode, inLine);
    changeVariableLong("extra6rewardCode", &extra6rewardCode, inLine);

    // variables for syringe pumps, dc
    changeVariableLong("IrewardSize_nL", &IrewardSize_nL, inLine);
    changeVariableLong("LrewardSize_nL", &LrewardSize_nL, inLine);
    changeVariableLong("RrewardSize_nL", &RrewardSize_nL, inLine);
    changeVariableLong("deliveryDuration_ms", &deliveryDuration_ms, inLine);
    changeVariableLong("syringeSize_mL", &syringeSize_mL, inLine);

    // solely for reporting these variables to the text output
    changeVariableLong("trialLRtype", &trialLRtype, inLine);
    changeVariableLong("trialAVtype", &trialAVtype, inLine);

    // for phase 301 (self-admin and cue-induced reinstatement)
    changeVariableLong("initPokesToInitiate", &initPokesToInitiate, inLine);
    changeVariableLong("leftPokesToInitiate", &leftPokesToInitiate, inLine);
    changeVariableLong("rightPokesToInitiate", &rightPokesToInitiate, inLine);
    changeVariableLong("SA_leftAudCue", &SA_leftAudCue, inLine);
    changeVariableLong("SA_initAudCue", &SA_initAudCue, inLine);
    changeVariableLong("SA_rightAudCue", &SA_rightAudCue, inLine);
    changeVariableLong("SA_leftVisCue", &SA_leftVisCue, inLine);
    changeVariableLong("SA_initVisCue", &SA_initVisCue, inLine);
    changeVariableLong("SA_rightVisCue", &SA_rightVisCue, inLine);
    changeVariableLong("SAcueLength", &SAcueLength, inLine);


    // not in matlab:

    changeVariableLong("initOpenNow", &initOpenNow, inLine);
    changeVariableLong("leftOpenNow", &leftOpenNow, inLine);
    changeVariableLong("rightOpenNow", &rightOpenNow, inLine);
    changeVariableLong("extraPoke4OpenNow", &extraPoke4OpenNow, inLine);
    changeVariableLong("extraPoke5OpenNow", &extraPoke5OpenNow, inLine);

    changeVariableLong("slowDTmicros", &slowDTmicros, inLine);
    changeVariableLong("pauseLengthMicros", &pauseLengthMicros, inLine);

    changeVariableLong("startTrialYN", &startTrialYN, inLine);
    changeVariableLong("goToStandby", &goToStandby, inLine);

  }
}

// this function gives rewards if the timeCode matches the rewardCode (e.g. at the correct state transition)
// rewards can only be given to I,L,R. can fill in the extra pokes later (fix:)
void giveRewards(int timeCode) {
  if (IrewardCode == timeCode) {
    deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
    serLogNum("initReward_nL", IrewardSize_nL);
  }
  if (LrewardCode == timeCode) {
    deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
    serLogNum("leftReward_nL", LrewardSize_nL);
  }
  if (RrewardCode == timeCode) {
    deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
    serLogNum("rightReward_nL", RrewardSize_nL);
  }
  DPRINTLN(String("IrewardCode: ") + String(IrewardCode)); // for debugging - LS0807
  DPRINTLN(String("LrewardCode: ") + String(LrewardCode));
  DPRINTLN(String("RrewardCode: ") + String(RrewardCode));
}

/* reward codes - they are independent of which poke is rewarded
    0 - no reward
    1 - reward init poke at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon nosepoke
*/

// rewards can only be given to I,L,R. can fill in the extra pokes later (fix:)
void checkRewards() {
  if (giveRewardNow == 1) {
    giveRewardNow = 0;
    deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
    serLogNum("initReward_nL", IrewardSize_nL);
  }
  if (giveRewardNow == 2) {
    giveRewardNow = 0;
    deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
    serLogNum("leftReward_nL", LrewardSize_nL);
  }
  if (giveRewardNow == 3) {
    giveRewardNow = 0;
    deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
    serLogNum("rightReward_nL", RrewardSize_nL);
  }
}

// function to switch states
void switchTo(int whichState) {
  tempTime = millis(); // stores time of last state transition in global variable
  state = whichState;
}

// setting level for LEDs
void setLEDlevel(int whichPin, int whichLevel) {
  // the reason for this function is because analogWrite() implements hardware-based PWM
  // for the digital pins (e.g. for the LEDs), but that only works up to 10-bit resolution,
  // but we want 12-bit resolution for the DAC, so we have to change the resolution and 
  // change it back every time we change the PWM level for an LED pin.
  analogWriteResolution(10);
  analogWrite(whichPin, whichLevel);
  analogWriteResolution(12);  
}

// function to allow matlab to open/close doors, e.g. if matlab sets leftOpenNow to be 1, it will open the door
void checkSwitches() {  
  reading_switch1 = digitalRead(ip1);
  reading_switch2 = digitalRead(ip2);
  reading_switch3 = digitalRead(ip3);
  reading_switch4 = digitalRead(ip4);

  if (reading_switch1==0){
    switch1_on = 1;
    switch2_on = 0;
  } else {switch1_on = 0;}
  if (reading_switch2==0){
    switch2_on = 1;
    switch1_on = 0;
  } else {switch2_on = 0;}
  if (reading_switch3==0){
    switch3_on = 1;
  } else {switch3_on = 0;}
  if (reading_switch4==0){
    switch4_on = 1;
  } else {switch4_on = 0;}
   
  switches_on = switch1_on + switch2_on;
  fwd_on = switch1_on;
  bwd_on = switch2_on;
  syringeLeft = switch3_on;
  syringeRight = switch4_on;
  syringeInit = switch3_on*switch4_on;
  // digitalWrite(syringePumpLeft,LOW);
  // digitalWrite(syringePumpRight,LOW);
  // digitalWrite(syringePumpInit,LOW);

  // // t.oscillate(syringePumpLeft, 10, LOW, 10);
  // // t.oscillate(syringePumpRight, 10, LOW, 10);
  // t.oscillate(syringePumpInit, 10, LOW, 10);

  // Serial.println(reading_switch1);
  // Serial.println(reading_switch2);
  // Serial.println(reading_switch3);
  // Serial.println(reading_switch4);
  }

  void fwd_syringe(int whichPump) {
    if (fwd_on==1){
     t.oscillate(whichPump, 10, HIGH, 10); 
     // delay(16)
     // delay(1);
      // digitalWrite(whichPump,HIGH);
   } else {
    // t.oscillate(whichPump, 10, LOW, 750);
    // digitalWrite(whichPump,LOW);
  }
    
    // delay(1000);
  }

  void bwd_syringe(int whichPump) {
    if (bwd_on==1){
     // t.oscillate(whichPump, 1000, HIGH, 100); 
      // digitalWrite(whichPump,HIGH);
   } else {
    // digitalWrite(whichPump,LOW);
  }
}

void checkButton() //checking if the button was pressed
{
  
  // read all the pokes
  buttonReading = digitalRead(button);
  if ((buttonReading==1))  { // if a poke is detected in this time window
    buttonDetected = 1; 
  }
}

void button_press(int whichPump)
{
 t.oscillate(whichPump, 2, LOW, 400);
}
    

