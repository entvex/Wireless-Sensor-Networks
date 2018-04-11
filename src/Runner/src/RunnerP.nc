/* 
 * WSN-GOT Runner
 */

#include "Runner.h"
#include "AM.h"
#include "Serial.h"
#include <Timer.h>
#include "printf.h"
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

module RunnerP @safe() {
   	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	
	void setLeds(uint16_t val) {
    if (val & 0x01)
      call Leds.led0On();
    else 
      call Leds.led0Off();
    if (val & 0x02)
      call Leds.led1On();
    else
      call Leds.led1Off();
    if (val & 0x04)
      call Leds.led2On();
    else
      call Leds.led2Off();
  	}
	
	void sendResponse(nx_uint16_t seq) {
		if (!busy) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));

			if (btrpkt == NULL) {
				return;
			}		

			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->seq = seq;

			setLeds(btrpkt->counter);

			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	        
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
	}

	event void Timer0.fired() {
		// Main loop. Runs every time timer is fired
	}

	event void AMControl.startDone(error_t error){
		if (error == SUCCESS)
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		else
			call AMControl.start();
	}

	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		 if (&pkt == msg) {
			busy = FALSE;
		}
	}	

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
    	BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
   	
		sendResponse(btrpkt->seq);
		
		return msg;
	}
}