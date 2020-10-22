void SApreCue_fxn() {

  // figure out which cues to turn on, etc.
  // just doing auditory for now



  // turn on visual cues, go to SAcue state
  if ((millis() - tempTime) > preCueLength) {

    // in case we want to use visual cues later
    /* // turn on visual cues
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
    } */

    if (whichPokeStartedTrial == 1) { // left poke
//      SAcue_aud = SA_leftAudCue; // old
      SAcue_aud = 3; // using buzzer for all
      setLEDlevel(cueLED5pin, cueLED5Brightness);
      digitalWrite(visualCueTTL, HIGH);
    }
    if (whichPokeStartedTrial == 2) { // init poke
      SAcue_aud = SA_initAudCue;
    }
    if (whichPokeStartedTrial == 3) { // right poke
//      SAcue_aud = SA_rightAudCue; // old
      SAcue_aud = 3; // using buzzer for all
      setLEDlevel(cueLED6pin, cueLED6Brightness);
      digitalWrite(visualCueTTL, HIGH);
    }

    // turn on auditory cue TTL
    if (1) { // use the if statement in the future, if we don't want to play the aud cue
      digitalWrite(auditoryCueTTL, HIGH);
    }
    switchTo(SAcue);
  }
  delayMicroseconds(pauseLengthMicros); 
}


void SAcue_fxn() {

  // play auditory cues
  if (SAcue_aud==1) {
    playLowTone();
  }
  else if (SAcue_aud==2) {
    playHighTone();
  }
  else if (SAcue_aud==3) {
    playBuzzer();
  }
  else if (SAcue_aud==4) {
    playWhiteNoise();
  }

  // otherwise mouse held long enough:
  // start one of the cues when slot3Length time elapsed.
  if ((millis() - tempTime) > SAcueLength) {

    // turn off any visual cues
    setLEDlevel(cueLED1pin, 0);
    setLEDlevel(cueLED2pin, 0);
    setLEDlevel(cueLED3pin, 0);
    setLEDlevel(cueLED4pin, 0);
    setLEDlevel(cueLED5pin, 0);
    setLEDlevel(cueLED6pin, 0);

    digitalWrite(visualCueTTL, LOW); 

    // turn off auditory cue TTL
    digitalWrite(auditoryCueTTL, LOW);

    sndCounter = 0;
    switchTo(SApostCue);
  }

  delayMicroseconds(pauseLengthMicros); 
}

void SApostCue_fxn() {

  // state duration has elapsed
  if ((millis() - tempTime) > postCueLength) {

    // reward pokes
    if (LrewardCode==3 && whichPokeStartedTrial==1) {
      deliverReward_dc(LrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpLeft);
      serLogNum("leftReward_nL", LrewardSize_nL);
    }
    if (IrewardCode==3 && whichPokeStartedTrial==2) {
      deliverReward_dc(IrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpInit);
      serLogNum("initReward_nL", IrewardSize_nL);
    }
    if (RrewardCode==3 && whichPokeStartedTrial==3) {
      deliverReward_dc(RrewardSize_nL, deliveryDuration_ms, syringeSize_mL, syringePumpRight);
      serLogNum("rightReward_nL", RrewardSize_nL);
    }
    whichPokeStartedTrial = 0; // resetting
    switchTo(letTheAnimalDrink);  
  }

  delayMicroseconds(pauseLengthMicros); 

}