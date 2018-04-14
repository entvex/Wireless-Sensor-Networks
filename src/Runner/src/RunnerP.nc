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
	uses interface Timer<TMilli> as Timer0; //Handles timeouts.
	uses interface Timer<TMilli> as Timer1; //Handles leds.
	uses interface Timer<TMilli> as Timer2; //Send data
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
	uses interface Random;
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	uint8_t sentCounter = 0;
	uint8_t receivedCounter = 0;
	uint8_t errorCount = 0;
	
	nx_uint16_t nodeidToSendTo;
		
	void setLedRed() {
		call Leds.led0On();
		call Timer1.startOneShot(100);
	}
	void setLedGreen() {
		call Leds.led1On();
		call Timer1.startOneShot(100);
	}
	void setLedBlue() {
		call Leds.led2On();
		call Timer1.startOneShot(100);
	}
		
	void sendAck(uint16_t nodeid) {
		ackMessage* ackptr;
    	
    	if(!busy) {
    		ackptr = (ackMessage*)(call Packet.getPayload(&pkt, sizeof(ackMessage)));
    	
    		if(ackptr != NULL) {
    			ackptr->nodeid = TOS_NODE_ID;
				ackptr->seq = sentCounter % 2;
				ackptr->counter = sentCounter;
				ackptr->receiveid = nodeid;
				
				call CC2420Packet.setPower(&pkt, SET_POWER);
				
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ackMessage)) == SUCCESS) {
					busy = TRUE;
					setLedBlue();
					printf("Sending ACK to moteId %d\n", ackptr->receiveid);
					printfflush();
				}
    		}
    	}

		}
	
	void sendResponse(uint16_t nodeid) {
		
		printf("data to: %d \n", nodeid);
		
		if(receivedCounter == sentCounter) {
    		sentCounter++;
    	}
				
		if (!busy) {
			requestMessage* requestpkt = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));

			if (requestpkt == NULL) {
				return;
			}		
			
			requestpkt->nodeid = TOS_NODE_ID;
			requestpkt->counter = sentCounter;
			requestpkt->seq = sentCounter % 2;
			requestpkt->data = 25;

			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
				call Timer0.startOneShot(1000);
			}
		}
	}
	        
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
	}

	event void Timer1.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}

	event void Timer0.fired() {
		
	}
	
	event void Timer2.fired(){
		sendResponse(nodeidToSendTo);
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
		
		if(len == sizeof(requestMessage)) {
			requestMessage* requestpkt = (requestMessage*)payload;
			errorCount = 0;
			
    		printf("Got request from moteID %d \n", requestpkt->nodeid);
    		printfflush();
									
			if(requestpkt != NULL) {
				if(requestpkt->counter % 2 == requestpkt->seq) {
   					sendAck(requestpkt->nodeid);
   					nodeidToSendTo = requestpkt->nodeid;
   					call Timer2.startPeriodicAt(100, TIMER_PERIOD_MILLI);
   				}
			}
			
		} else if (len == sizeof(ackMessage)) {
			ackMessage* ackpkt = (ackMessage*)payload;
			errorCount = 0;
			
			if(ackpkt->receiveid == TOS_NODE_ID)
			{
				
	    		printf("Got ack from moteID %d \n", ackpkt->nodeid);
	    		printfflush();
				
				if(ackpkt->counter % 2 == ackpkt->seq) {
   					setLedGreen();
					call Timer2.stop();
   				}
			}
		}
		return msg;
	}
}