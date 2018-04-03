/* 
 * WSN-GOT BaseStation
 */

configuration BaseStationC {
}
implementation {
  components MainC, BaseStationP, LedsC;
  components ActiveMessageC as Radio, SerialActiveMessageC as Serial;
  components CC2420ActiveMessageC;
  
  MainC.Boot <- BaseStationP;
  
  BaseStationP.CC2420Packet -> CC2420ActiveMessageC;

  BaseStationP.RadioControl -> Radio;
  BaseStationP.SerialControl -> Serial;
  
  BaseStationP.UartSend -> Serial;
  BaseStationP.UartReceive -> Serial.Receive;
  BaseStationP.UartPacket -> Serial;
  BaseStationP.UartAMPacket -> Serial;
  
  BaseStationP.RadioSend -> Radio;
  BaseStationP.RadioReceive -> Radio.Receive;
  BaseStationP.RadioSnoop -> Radio.Snoop;
  BaseStationP.RadioPacket -> Radio;
  BaseStationP.RadioAMPacket -> Radio;
  
  BaseStationP.Leds -> LedsC;
}
