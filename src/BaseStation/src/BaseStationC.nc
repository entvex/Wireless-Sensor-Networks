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
  components new AMSenderC(6);
  components new AMReceiverC(6);
  components CC2420ActiveMessageC;
  components new QueueC(int8_t, 10) as RssiQueue;
  
  MainC.Boot <- BaseStationP;
  
  BaseStationP.Boot -> MainC;
  BaseStationP.Leds -> LedsC;
  BaseStationP.Timer0 -> Timer0;
  BaseStationP.Timer1 -> Timer1;
  BaseStationP.Timer2 -> Timer2;
  BaseStationP.Packet -> AMSenderC;
  //  BaseStationP.AMPacket -> AMSenderC;
  BaseStationP.AMControl -> ActiveMessageC;
  BaseStationP.AMSend -> AMSenderC;
  BaseStationP.Receive -> AMReceiverC;
  BaseStationP.CC2420Packet -> CC2420ActiveMessageC;
}
