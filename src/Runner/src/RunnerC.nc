/* 
 * WSN-GOT Runner
 */

configuration RunnerC {
}
implementation {
  components MainC;
  components LedsC;
  components RunnerP;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components ActiveMessageC;
  components new AMSenderC(6);
  components new AMReceiverC(6);
  components CC2420ActiveMessageC;
  components RandomMlcgC;
  
  MainC.Boot <- RunnerP;
  
  RunnerP.Random -> RandomMlcgC;
  RunnerP.Boot -> MainC;
  RunnerP.Leds -> LedsC;
  RunnerP.Timer0 -> Timer0;
  RunnerP.Timer1 -> Timer1;
  RunnerP.Timer2 -> Timer2;
  RunnerP.Packet -> AMSenderC;
  RunnerP.AMPacket -> AMSenderC;
  RunnerP.AMControl -> ActiveMessageC;
  RunnerP.AMSend -> AMSenderC;
  RunnerP.Receive -> AMReceiverC;
  RunnerP.CC2420Packet -> CC2420ActiveMessageC;
}
