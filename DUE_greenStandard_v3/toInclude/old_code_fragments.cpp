


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








