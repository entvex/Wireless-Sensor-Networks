/* 
 * WSN-GOT BaseStation
 */

configuration BaseStationC {
}
implementation {
  components MainC;
  components LedsC;
  components BaseStationP;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components ActiveMessageC;
  components new AMSenderC(AM_CHANNEL);
  components new AMReceiverC(AM_CHANNEL);
  components CC2420ActiveMessageC;
  components new QueueC(uint8_t, 5) as RssiQueue;
  
  MainC.Boot <- BaseStationP;
  
  BaseStationP.Boot -> MainC;
  BaseStationP.Leds -> LedsC;
  BaseStationP.RssiQueue -> RssiQueue;
  BaseStationP.Timer0 -> Timer0;
  BaseStationP.Timer1 -> Timer1;
  BaseStationP.Timer2 -> Timer2;
  BaseStationP.Packet -> AMSenderC;
  BaseStationP.AMControl -> ActiveMessageC;
  BaseStationP.AMSend -> AMSenderC;
  BaseStationP.Receive -> AMReceiverC;
  BaseStationP.CC2420Packet -> CC2420ActiveMessageC;
}
