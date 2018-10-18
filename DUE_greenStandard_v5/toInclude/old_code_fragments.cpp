


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
// MISSED
// pause for missed trial, does not play buzzer

case missed:

  delayMicroseconds(pauseLengthMicros); 

  // wait for timeout, switch state to PUNISH DELAY
  if ((millis() - tempTime) > missedLength) {
    closePoke("all");
    serLog("PunishDelay");
    switchTo(punishDelay);
  }

  break;




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
        if (extra5openYN == 1) {
          openPoke("extraPoke5");
        //giveRewards(3); // give reward to the init/L/R pokes after cue/noCue has occurred and mouse held long enough
        }
        if (trainingPhase < 3) {
          giveRewards(3);
          switchTo(letTheAnimalDrink);  //mouse will collect reward in the init port in phases 1 & 2
        } 
        if (trainingPhase > 2) {
          giveRewards(3);
          switchTo(goToPokes); 
          //mouse will now go collect reward from pre-rewarded L/R (1st block phase 3), 
      	  //or after poking L/R, (in later blocks phase 3, or in phase 4 and above)
        }
      }

      delayMicroseconds(pauseLengthMicros);
      break;
