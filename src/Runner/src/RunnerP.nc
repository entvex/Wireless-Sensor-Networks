/* 
 * WSN-GOT BaseStation
 */

#include "Runner.h"
#include "AM.h"
#include "Serial.h"
#include <Timer.h>
#include "printf.h"
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

module BaseStationP @safe() {
   	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
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
	
	void print(unsigned char* string, ...) {
    	printf(string);
    	printfflush();
    }
	
	void sendResponse(nx_uint8_t seq) {
		if (!busy) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));

			if (btrpkt == NULL) {
				return;
			}		

			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->ack = seq;

			call CC2420Packet.setPower(&pkt, SET_POWER);

			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	        
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
		print("Runner started!\n");
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
		message_t *ret = msg;
    	int i = 0;
    	
    	BlinkToRadioMsg* btrpkt =(BlinkToRadioMsg*)msg;
   
    	if(btrpkt->seq == (sentSeq-1))
    		receivedSeq++;

		// Extract info about rssi
		btrpkt->rssi = call CC2420Packet.getRssi(msg);
		
		sendResponse(btrpkt->seq);
		
		return ret;
	}
}