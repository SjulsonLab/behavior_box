/*
Daniela Cassataro v2 5/23/18

TO DO:
  . ctrl+f "FIX:" 
  . remove the center-right and center-left stuff

*/

// for debugging
//#define DEBUG   //If you comment out this line, the DPRINT & DPRINTLN lines are defined as blank.
#ifdef DEBUG    //Macros are usually in all capital letters.
#define DPRINT(...)    Serial.print(__VA_ARGS__)     //DPRINT is a macro, debug print
#define DPRINTLN(...)  Serial.println(__VA_ARGS__)   //DPRINTLN is a macro, debug print with new line
#else
#define DPRINT(...)     //now defines a blank line
#define DPRINTLN(...)   //now defines a blank line
#endif

using namespace std;

#include <Arduino.h>
#include <LED.h>   // https://playground.arduino.cc/Code/LED - have to open LED.h and manually change Wprogram.h to Arduino.h
#include <Servo.h>
#include <Event.h> // https://playground.arduino.cc/Code/Timer
#include <Timer.h> // https://playground.arduino.cc/Code/Timer
//#include <string>
#include <avr/pgmspace.h> // might be required to store waveforms on flash instead of RAM
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
#define cueLED5pin          9
#define cueLED6pin          8

// syringe pumps - will add fourth syringe pump dedicated for init poke later
#define syringePumpInit        24  // connected to left pump
#define syringePumpLeft        26  // connected to init pump (used to be center pump)
#define syringePumpRight       28  // connected to right pump
#define syringePumpCenter      30  // not actually connected
#define syringePumpCenterLeft  32  // not actually connected
#define syringePumpCenterRight 34  // not actually connected

// pins sampled by Intan:

// nosepoke-related pins(6)
#define initPokeTTL         27
#define leftPokeTTL         29
#define rightPokeTTL        31
#define centerLeftPokeTTL   35  // not connected
#define centerPokeTTL       33
#define centerRightPokeTTL  37  // not connected

// pulsepal pins(2)
#define pulsePal1           51
#define pulsePal2           53

// pins related to cues and rewards(6)
#define whiteNoiseTTL       22
#define auditoryCueTTL      23
#define visualCueTTL        25
#define lowCueTTL           39
#define highCueTTL          41
#define rewardTTL           43

// last two(2)
#define cameraLEDpin        45
#define triggerPin          46

// five extra pins (5) that are not plugged into the intan
// Could be used with an intan with more than 16(17, w/GND) inputs
#define syringePumpENABLE         47 //will try to use this for ENABLE pin for syringe pumps
#define extraIntan2         48
#define extraIntan3         49
#define extraIntan4         50
#define extraIntan5         52


long doorCloseSpeed        = 5;    // original speed was 10 - can decrease if there are problems
//long centerPulseYN         = 0;  // set to 1 to send a TTL pulse to the center pump

// other global variables
long state                        = 1;     // state variable for finite state machine - set to 1 (standby)
long trainingPhase                = 0;     // phase of training - set by serial input
long sndCounter                   = 0;
unsigned long nosePokeInitTime    = 0;     // FIX: rename to something better. initHoldStartTime_ms? it's when mouse begins the init poke specifically. used to make sure mouse holds long enough. 
long nTrial                       = 0;     // trial number
long slowDTmicros                 = 100;   // DT of slow loop in microseconds
long pauseLengthMicros            = 5;     // length of pause for each iteration of the fast loop
unsigned long lastCheckTimeMicros = 0;
int probsWritten                  = 0;     // if reward probabilities are sent to serial, turns to 1
long useInitPumpForCenter         = 0;     // if set to 1, center poke activates the init pump instead (for boxes with only 3 pumps)
int initPokeError                 = 0;     // gets set to 1 if the animal init pokes during standby

// variables for timing
unsigned long trialAvailTime           = 0;
unsigned long initPokeEntryTime        = 0;
unsigned long initPokeExitTime         = 0;
unsigned long leftPokeEntryTime        = 0;
unsigned long centerLeftPokeEntryTime  = 0;
unsigned long centerPokeEntryTime      = 0;
unsigned long centerRightPokeEntryTime = 0;
unsigned long rightPokeEntryTime       = 0;

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

int centerLeftPoke          = 0;
int centerLeftPokeLast      = 0;
int centerLeftPokeReading   = 0;
int centerLeftPokeDetected  = 0;

int centerRightPoke          = 0;
int centerRightPokeLast      = 0;
int centerRightPokeReading   = 0;
int centerRightPokeDetected  = 0;

int centerPoke          = 0;
int centerPokeLast      = 0;
int centerPokeReading   = 0;
int centerPokeDetected  = 0;

// servos to control nosepoke doors
#define ServoOpen      10 //position at which Servo is open
#define ServoClosed   150 //position at which Servo is closed
Servo servoLeft;
Servo servoCenterLeft;
Servo servoRight;
Servo servoCenterRight;
Servo servoCenter; 

long leftOpenNow         = 0; // set this to 1 to give command to open door
long centerLeftOpenNow   = 0;
long rightOpenNow        = 0;
long centerRightOpenNow  = 0;
long centerOpenNow       = 0;

long leftIsOpen          = 0; // this is set to 1 after the door is opened
long centerLeftIsOpen    = 0;
long rightIsOpen         = 0;
long centerRightIsOpen   = 0;
long centerIsOpen        = 0;

// these will allow openPoke() and closePoke() to send commands to the servo only when
// there's a mismatch between the desired state and the actual state

// state-related variables - all durations in msec
long readyToGoLength        = 60000;
long missedLength           = 50;
long punishDelayLength      = 5000;
long preCueLength           = 50;
long auditoryCueLength      = 200;
long visualCueLength        = 200;
long postCueLength          = 50;
long goToPokesLength        = 60000;
long rewardCollectionLength = 3000;

long startTrialYN        = 0;   // 1 to start a trial
long resetTimeYN         = 0;   // 1 to reset the timer
long nosePokeHoldLength  = 0;   // number of ms the animal must hold its nose poke FIX: rename to requiredPokeHoldLength_ms
long goToStandby         = 0;   // set to 1 using matlab to exit goToPokes state
long giveRewardNow       = 0;   // 1=init, 2=left, 3=right, 4=center.
long initPokePunishYN    = 0;   // 1 to punish for init poke during standby, 0 is default

// other variables
/* reward codes - they are independent of which poke is rewarded
    0 - no reward
    1 - reward init poke at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon successful nosepoke
*/

long IrewardCode            = 1; // determines if/when reward is given
long LrewardCode            = 0; 
long CLrewardCode           = 0;
long RrewardCode            = 0;
long CRrewardCode           = 0;
long CrewardCode            = 0;

long IrewardProb            = 100; // for probabilistic reward (0-100%)
long LrewardProb            = 100; 
long CLrewardProb           = 100;
long RrewardProb            = 100;
long CRrewardProb           = 100;
long CrewardProb            = 100;

long IrewardLength          = 500; // length of reward delivery in ms
long LrewardLength          = 500; // length of reward delivery in ms
long CLrewardLength         = 500; // length of reward delivery in ms
long RrewardLength          = 500; // length of reward delivery in ms
long CRrewardLength         = 500; // length of reward delivery in ms
long CrewardLength          = 500; // length of reward delivery in ms



long laserOnCode            = 0; // FIX: laserOnCode is set twice
long auditoryOrVisualCue    = 0; // 0 is none, 1 is auditory, 2 is visual
long cueHiLow               = 0; // -1 is low, 1 is high, and 0 is neither
long isLeftLow              = 1; // 1 means left is low cue, 0 means left is high cue
long LopenYN                = 1; // whether to open L nosepoke upon goToPokes
long CLopenYN               = 0;
long RopenYN                = 1;
long CRopenYN               = 0;
long CopenYN                = 0;

long WNvolume        = 128; // between 0-255
long lowCueVolume    = 128;
long highCueVolume   = 128;
long buzzerVolume    = 128; 


// globals for the syringe pumps
// these are all longs because matlab requires longs
long volumeLeft_nL           = 0;
long volumeCenter_nL         = 0;
long volumeRight_nL          = 0;
long volumeInit_nL           = 0;
long deliveryDuration_ms     = 1000;
long syringeSize_mL          = 5;



//***********************************************
//              declare LEDs
//***********************************************
LED cueLED1   = LED(cueLED1pin);
LED cueLED2   = LED(cueLED2pin);
LED cueLED3   = LED(cueLED3pin);
LED cueLED4   = LED(cueLED4pin);
LED cameraLED = LED(cameraLEDpin);  // will be connected to red or IR LED sampled by camera



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
  punishDelayLength = 5000;
  preCueLength      = 50; // in msec
  auditoryCueLength = 200;
  visualCueLength   = 200;
  postCueLength     = 50;
  goToPokesLength   = 10000; // in msec

  // other 
  IrewardCode            = 0; // when (and whether) a particular port is rewarded
  LrewardCode            = 0;
  CLrewardCode           = 0;
  RrewardCode            = 0;
  CRrewardCode           = 0;
  CrewardCode            = 0;

  IrewardLength          = 500;
  LrewardLength          = 500; // length of reward delivery in ms
  CLrewardLength         = 500; // length of reward delivery in ms
  RrewardLength          = 500; // length of reward delivery in ms
  CRrewardLength         = 500; // length of reward delivery in ms
  CrewardLength          = 500; // length of reward delivery in ms

  laserOnCode            = 0;
  auditoryOrVisualCue    = 0; // 1 is auditory, 2 is visual, and 0 is neither
  cueHiLow               = 0; // -1 is low, 1 is high, and 0 is neither
  goToStandby            = 0; // set to 1 using matlab to exit goToPokes state
  giveRewardNow          = 0;
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
  if (whichPoke.equalsIgnoreCase("left") && leftIsOpen == 0) {
    servoLeft.write(ServoOpen);
    leftIsOpen = leftOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("centerLeft") && centerLeftIsOpen == 0) {
    servoCenterLeft.write(ServoOpen);
    centerLeftIsOpen = centerLeftOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("right") && rightIsOpen == 0) {
    servoRight.write(ServoOpen);
    rightIsOpen = rightOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("centerRight") && centerRightIsOpen == 0) {
    servoCenterRight.write(ServoOpen);
    centerRightIsOpen = centerRightOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("center") && centerIsOpen == 0) {
    servoCenter.write(ServoOpen);
    centerIsOpen = centerOpenNow = 1;
  }
  if (whichPoke.equalsIgnoreCase("all")) {
    servoLeft.write(ServoOpen);
    servoCenterLeft.write(ServoOpen);
    servoRight.write(ServoOpen);
    servoCenterRight.write(ServoOpen);
    servoCenter.write(ServoOpen);
    leftIsOpen = centerLeftIsOpen = rightIsOpen = centerRightIsOpen = centerIsOpen = 1;
    leftOpenNow = centerLeftOpenNow = rightOpenNow = centerRightOpenNow = centerOpenNow = 1;
  }
  delay(15);
}

void closePoke(String whichPoke) {
  int servoTemp = ServoOpen;

  while (servoTemp <= ServoClosed) {
    if (whichPoke.equalsIgnoreCase("left") && leftIsOpen == 1) {
      servoLeft.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("centerLeft") && centerLeftIsOpen == 1) {
      servoCenterLeft.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("right") && rightIsOpen == 1) {
      servoRight.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("centerRight") && centerRightIsOpen == 1) {
      servoCenterRight.write(servoTemp);
    }
    if (whichPoke.equalsIgnoreCase("center") && centerIsOpen == 1) {
      servoCenter.write(servoTemp);
    }

    if (whichPoke.equalsIgnoreCase("all")) {
      if (leftIsOpen == 1) servoLeft.write(servoTemp);
      if (centerLeftIsOpen == 1) servoCenterLeft.write(servoTemp);
      if (rightIsOpen == 1) servoRight.write(servoTemp);
      if (centerRightIsOpen == 1) servoCenterRight.write(servoTemp);
      if (centerIsOpen == 1) servoCenter.write(servoTemp);
    }
    delay(15);
    servoTemp += doorCloseSpeed;
  }

  // after doors are closed, set variables to zero
  if (whichPoke.equalsIgnoreCase("left")) leftIsOpen = leftOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("centerLeft")) centerLeftIsOpen = centerLeftOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("right")) rightIsOpen = rightOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("centerRight")) centerRightIsOpen = centerRightOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("center")) centerIsOpen = centerOpenNow = 0;
  if (whichPoke.equalsIgnoreCase("all")) leftIsOpen = centerLeftIsOpen = rightIsOpen = centerRightIsOpen = centerIsOpen = leftOpenNow = centerLeftOpenNow = rightOpenNow = centerRightOpenNow = centerOpenNow = 0;

}

// function to allow matlab to open/close doors, e.g. if matlab sets leftOpenNow to be 1, it will open the door
void checkDoors() {
  if (leftOpenNow > leftIsOpen)
    openPoke("left");
  else if (leftOpenNow < leftIsOpen)
    closePoke("left");

  if (centerLeftOpenNow > centerLeftIsOpen)
    openPoke("centerLeft");
  else if (centerLeftOpenNow < centerLeftIsOpen)
    closePoke("centerLeft");

  if (rightOpenNow > rightIsOpen)
    openPoke("right");
  else if (rightOpenNow < rightIsOpen)
    closePoke("right");

  if (centerRightOpenNow > centerRightIsOpen)
    openPoke("centerRight");
  else if (centerRightOpenNow < centerRightIsOpen)
    closePoke("centerRight");

  if (centerOpenNow > centerIsOpen)
    openPoke("center");
  else if (centerOpenNow < centerIsOpen)
    closePoke("center");
}

void checkPokes()
{
  
  // read all the pokes
  initPokeReading = digitalRead(initPokeTTL);
  if ((initPokeDetected==0) && (initPokeReading==1))  { // if a poke is detected in this time window
    initPokeDetected = 1; 
  }

  leftPokeReading = digitalRead(leftPokeTTL);
  if ((leftPokeDetected==0) && (leftPokeReading==1))  { // if a poke is detected in this time window
    leftPokeDetected = 1; 
  }

  rightPokeReading = digitalRead(rightPokeTTL);
  if ((rightPokeDetected==0) && (rightPokeReading==1))  { // if a poke is detected in this time window
    rightPokeDetected = 1; 
  }

  centerLeftPokeReading = digitalRead(centerLeftPokeTTL);
  if ((centerLeftPokeDetected==0) && (centerLeftPokeReading==1))  { // if a poke is detected in this time window
    centerLeftPokeDetected = 1; 
  }

  centerRightPokeReading = digitalRead(centerRightPokeTTL);
  if ((centerRightPokeDetected==0) && (centerRightPokeReading==1))  { // if a poke is detected in this time window
    centerRightPokeDetected = 1; 
  }

  centerPokeReading = digitalRead(centerPokeTTL);
  if ((centerPokeDetected==0) && (centerPokeReading==1))  { // if a poke is detected in this time window
    centerPokeDetected = 1; 
  }

  
  // if enough time has passed, log and update status
  if (millis()-pokeLastCheckTime >= pokeDT) { 
  	pokeLastCheckTime = millis();
  	// DPRINTLN(String("POKECHECK: ") + String(pokeLastCheckTime));

    if ((initPokeLast==0) && (initPokeDetected==1)) { // init poke entry
    	serLog("initPokeEntry");
    	initPokeLast = initPokeDetected;
    	initPoke = 1;
      initPokeEntryTime = millis();
    }
    else if ((initPokeLast==1) && (initPokeDetected==0)) { // init poke exit
    	serLogNum("initPokeExit", millis() - initPokeEntryTime);
    	initPokeLast = initPokeDetected;
    	initPoke = 0;
      initPokeExitTime = millis();
    }

    if ((leftPokeLast==0) && (leftPokeDetected==1)) { // left poke entry
    	serLog("leftPokeEntry");
    	leftPokeLast = leftPokeDetected;
    	leftPoke = 1;
      leftPokeEntryTime = millis();
    }
    else if ((leftPokeLast==1) && (leftPokeDetected==0)) { // left poke exit
    	serLogNum("leftPokeExit", millis() - leftPokeEntryTime);
    	leftPokeLast = leftPokeDetected;
    	leftPoke = 0;
    }

    if ((rightPokeLast==0) && (rightPokeDetected==1)) { // right poke entry
    	serLog("rightPokeEntry");
    	rightPokeLast = rightPokeDetected;
    	rightPoke = 1;
      rightPokeEntryTime = millis();
    }
    else if ((rightPokeLast==1) && (rightPokeDetected==0)) { // right poke exit
    	serLogNum("rightPokeExit", millis() - rightPokeEntryTime);
    	rightPokeLast = rightPokeDetected;
    	rightPoke = 0;
    }

    if ((centerLeftPokeLast==0) && (centerLeftPokeDetected==1)) { // centerLeft poke entry
    	serLog("centerLeftPokeEntry");
    	centerLeftPokeLast = centerLeftPokeDetected;
    	centerLeftPoke = 1;
      centerLeftPokeEntryTime = millis();
    }
    else if ((centerLeftPokeLast==1) && (centerLeftPokeDetected==0)) { // centerLeft poke exit
    	serLogNum("centerLeftPokeExit", millis() - centerLeftPokeEntryTime);
    	centerLeftPokeLast = centerLeftPokeDetected;
    	centerLeftPoke = 0;
    }

    if ((centerRightPokeLast==0) && (centerRightPokeDetected==1)) { // centerRight poke entry
      serLog("centerRightPokeEntry");
      centerRightPokeLast = centerRightPokeDetected;
      centerRightPoke = 1;
      centerRightPokeEntryTime = millis();
    }
    else if ((centerRightPokeLast==1) && (centerRightPokeDetected==0)) { // centerRight poke exit
      serLogNum("centerRightPokeExit", millis() - centerRightPokeEntryTime);
      centerRightPokeLast = centerRightPokeDetected;
      centerRightPoke = 0;
    }

    if ((centerPokeLast==0) && (centerPokeDetected==1)) { // center poke entry
      serLog("centerPokeEntry");
      centerPokeLast = centerPokeDetected;
      centerPoke = 1;
      centerPokeEntryTime = millis();
    }
    else if ((centerPokeLast==1) && (centerPokeDetected==0)) { // center poke exit
      serLogNum("centerPokeExit", millis() - centerPokeEntryTime);
      centerPokeLast = centerPokeDetected;
      centerPoke = 0;
    }

    initPokeDetected = 0;
    leftPokeDetected = 0;
    rightPokeDetected = 0;
    centerLeftPokeDetected = 0;
    centerRightPokeDetected = 0;
    centerPokeDetected = 0;
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

// used for doing after() on the enable pin which requires a callback in the argument
void make_ENABLE_pin_HIGH_which_is_off() {
  digitalWrite(syringePumpENABLE, HIGH); 
}

// the dc syringe pump func.
// initialize the variables in the argument of the function definition:
void deliverReward_dc(long volume_nL, long local_deliveryDuration_ms, int local_syringeSize_mL, int whichPump) {
Serial.println("DC TEST PULSE.");  
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
    Serial.println("didn't recognize syringe size. available sizes '5' or '10.'");
    Serial.println("diameter_mm=");
    Serial.println(diameter_mm); 
    return;
  } 

  // determine vol per revolution, area of small cylinder with h=0.8mm
  // 0.8mm length per thread. 1thread=1cycle. 1 like=1prayer.
  volPerRevolution_uL = 0.8 * ( diameter_mm/2 )*( diameter_mm/2 ) * 3.1415926535898 ; 
  Serial.println("volPerRevolution = "); 
  Serial.println(volPerRevolution_uL);
  
  // determine how many revolutions needed for the desired volume
  howManyRevolutions = volume_uL / volPerRevolution_uL ;
  Serial.println("howManyRevolution = "); 
  Serial.println(howManyRevolutions);

  // determine total steps needed to reach desired revolutions, @200 steps/revolution
  // use *4 as a multiplier because it's operating at 1/4 microstep mode.
  // round to nearest int because totalSteps is unsigned long
  totalSteps = round(200 * howManyRevolutions * 4); 
  Serial.println("totalSteps = "); 
  Serial.println(totalSteps);

  // determine shortest delivery duration, total steps * 2 ms per step. 
  // minimum 1 ms in high, 1 ms in low for the shortest possible step function.
  minimumDeliveryDuration_ms = totalSteps*2; 
  Serial.println("minimumDeliveryDuration_ms = "); 
  Serial.println(minimumDeliveryDuration_ms);  

  // make sure delivery duration the user wants is long enough
  if (local_deliveryDuration_ms < minimumDeliveryDuration_ms) {
      Serial.println("duration too low. duration needs to be >");
      Serial.println(minimumDeliveryDuration_ms); 
      Serial.println("with that diameter and reward volume.");
      return;
    }

  // determine duration of each step for the timer oscillate function
  stepDuration_ms = (double)local_deliveryDuration_ms / totalSteps;

  // enable all pumps (low=on state) so we can move them
  digitalWrite(syringePumpENABLE, LOW);
  t.after((int)(100+local_deliveryDuration_ms), make_ENABLE_pin_HIGH_which_is_off); // FIX: every time "after()" is used needs to be fixed because it doesn't work like how luke thought it did

  // tell the intan reward is delivered
  //t.pulse(whateverTheIntanPinIs, 5, LOW);
  
  // turn the pump motor
  t.oscillate(whichPump, round(stepDuration_ms/2), LOW, totalSteps*2);

  // back to main loop. 
  Serial.println("Enter new option");
  Serial.println();
}


void processMessage() {
  String inLine;
  inLine = "";
  inLine = Serial.readStringUntil('\n');

  //DPRINTLN("Message received.");

  if (inLine.equalsIgnoreCase("checkVersion")) {
    char str[100];
    sprintf(str, "%d", VERSION);
    Serial.println(str);
  }
  if (inLine.equalsIgnoreCase("reset"))
    resetDefaults();

  // all the variables (ints) go here
  changeVariableLong("IrewardCode", &IrewardCode, inLine);
  changeVariableLong("LrewardCode", &LrewardCode, inLine);
  changeVariableLong("RrewardCode", &RrewardCode, inLine);
  changeVariableLong("CrewardCode", &CrewardCode, inLine);
  //changeVariableLong("CLrewardCode", &CLrewardCode, inLine);
  //changeVariableLong("CRrewardCode", &CRrewardCode, inLine);

  changeVariableLong("IrewardProb", &IrewardProb, inLine);
  changeVariableLong("LrewardProb", &LrewardProb, inLine);
  changeVariableLong("RrewardProb", &RrewardProb, inLine);
  changeVariableLong("CrewardProb", &CrewardProb, inLine);
  //changeVariableLong("CLrewardProb", &CLrewardProb, inLine);
  //changeVariableLong("CRrewardProb", &CRrewardProb, inLine);

  changeVariableLong("IrewardLength", &IrewardLength, inLine);
  changeVariableLong("LrewardLength", &LrewardLength, inLine);
  changeVariableLong("RrewardLength", &RrewardLength, inLine);
  changeVariableLong("CrewardLength", &CrewardLength, inLine);
  //changeVariableLong("CLrewardLength", &CLrewardLength, inLine);
  //changeVariableLong("CRrewardLength", &CRrewardLength, inLine);  

  changeVariableLong("laserOnCode", &laserOnCode, inLine);
  changeVariableLong("auditoryOrVisualCue", &auditoryOrVisualCue, inLine);
  changeVariableLong("cueHiLow", &cueHiLow, inLine);
  changeVariableLong("isLeftLow", &isLeftLow, inLine);
  changeVariableLong("resetTimeYN", &resetTimeYN, inLine);
  changeVariableLong("leftOpenNow", &leftOpenNow, inLine);
  changeVariableLong("centerLeftOpenNow", &centerLeftOpenNow, inLine);
  changeVariableLong("rightOpenNow", &rightOpenNow, inLine);
  changeVariableLong("centerRightOpenNow", &centerRightOpenNow, inLine);
  changeVariableLong("centerOpenNow", &centerOpenNow, inLine);
  changeVariableLong("initPokePunishYN", &initPokePunishYN, inLine);

  changeVariableLong("trainingPhase", &trainingPhase, inLine);
  changeVariableLong("LopenYN", &LopenYN, inLine);
  changeVariableLong("RopenYN", &RopenYN, inLine);
  changeVariableLong("CopenYN", &CopenYN, inLine);
  //changeVariableLong("CLopenYN", &CLopenYN, inLine);
  //changeVariableLong("CRopenYN", &CRopenYN, inLine);

  changeVariableLong("doorCloseSpeed", &doorCloseSpeed, inLine);
  changeVariableLong("slowDTmicros", &slowDTmicros, inLine);
  changeVariableLong("pauseLengthMicros", &pauseLengthMicros, inLine);

  changeVariableLong("WNvolume", &WNvolume, inLine);
  changeVariableLong("lowCueVolume", &lowCueVolume, inLine);
  changeVariableLong("highCueVolume", &highCueVolume, inLine);
  changeVariableLong("buzzerVolume", &buzzerVolume, inLine);

  // variables related to states
  changeVariableLong("readyToGoLength", &readyToGoLength, inLine);
  changeVariableLong("missedLength", &missedLength, inLine);
  changeVariableLong("punishDelayLength", &punishDelayLength, inLine);
  changeVariableLong("preCueLength", &preCueLength, inLine);
  changeVariableLong("auditoryCueLength", &auditoryCueLength, inLine);
  changeVariableLong("visualCueLength", &visualCueLength, inLine);
  changeVariableLong("postCueLength", &postCueLength, inLine);
  changeVariableLong("goToPokesLength", &goToPokesLength, inLine);
  changeVariableLong("startTrialYN", &startTrialYN, inLine);
  changeVariableLong("goToStandby", &goToStandby, inLine);
  changeVariableLong("nosePokeHoldLength", &nosePokeHoldLength, inLine);
  changeVariableLong("nTrial", &nTrial, inLine);
  changeVariableLong("rewardCollectionLength", &rewardCollectionLength, inLine);
  changeVariableLong("useInitPumpForCenter", &useInitPumpForCenter, inLine);

  // variables for syringe pumps, dc
  changeVariableLong("volumeLeft_nL", &volumeLeft_nL, inLine);
  changeVariableLong("volumeCenter_nL", &volumeCenter_nL, inLine);
  changeVariableLong("volumeRight_nL", &volumeRight_nL, inLine);
  changeVariableLong("volumeInit_nL", &volumeInit_nL, inLine);
  changeVariableLong("deliveryDuration_ms", &deliveryDuration_ms, inLine);
  changeVariableLong("syringeSize_mL", &syringeSize_mL, inLine);
}

// this function gives rewards if the timeCode matches the rewardCode (e.g. at the correct state transition)
void giveRewards(int timeCode) {
  if (IrewardCode == timeCode) deliverReward_dc(volumeInit_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
  if (LrewardCode == timeCode) deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
  if (RrewardCode == timeCode) deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
  if (CrewardCode == timeCode) deliverReward_dc(volumeCenter_nL, deliveryDuration_ms, syringeSize_mL, syringePumpCenter);
}

/* reward codes - they are independent of which poke is rewarded
    0 - no reward
    1 - reward init poke at ready signal
    2 - reward on init nose poke
    3 - reward at end of cue
    4 - reward only upon nosepoke
*/

// 
void checkRewards() {
  if (giveRewardNow == 1) {
    giveRewardNow = 0;
    deliverReward_dc(volumeInit_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
  }
  if (giveRewardNow == 2) {
    giveRewardNow = 0;
    deliverReward_dc(volumeLeft_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
  }
  if (giveRewardNow == 3) {
    giveRewardNow = 0;
    deliverReward_dc(volumeRight_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
  }
    if (giveRewardNow == 4) {
    giveRewardNow = 0;
    deliverReward_dc(volumeCenter_nL, deliveryDuration_ms, syringeSize_mL, syringePumpCenter);
  }
}

// function to switch states
void switchTo(int whichState) {
    tempTime = millis(); // stores time of last state transition in global variable
    state = whichState;
}

