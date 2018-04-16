/* 
 * WSN-GOT BaseStation
 */

#include "AM.h"
#include "Serial.h"
#include <Timer.h>
#include "printf.h"
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include "BaseStation.h"

module BaseStationP @safe() {
   	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Timer<TMilli> as Timer2;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
	uses interface Queue<int16_t> as RssiQueue;
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	uint8_t receivedCounter = 0;
	uint8_t sentCounter = 0;
	uint8_t errorCount = 0;
	uint8_t relayPosition = 0;
	
	void setLedRed() {
		call Leds.led0On();
		call Timer2.startOneShot(100);
	}
	void setLedGreen() {
		call Leds.led1On();
		call Timer2.startOneShot(100);
	}
	void setLedBlue() {
		call Leds.led2On();
		call Timer2.startOneShot(100);
	}
	
	void print(unsigned char* text) {
		printf(text);
    	printfflush();
	}
		
	void sendAck(uint16_t receiveId) {
		ackMessage* ackMessagePtr;
    	
    	if(receivedCounter == sentCounter) {
    		sentCounter++;
    	}

    	if(!busy) {
    		ackMessagePtr = (ackMessage*)(call Packet.getPayload(&pkt, sizeof(ackMessage)));
    		
    		if(DEBUG)
    			print("Preparing to send packet with counter: " + sentCounter + "\n");
    	
    		ackMessagePtr->nodeid = TOS_NODE_ID;
			ackMessagePtr->seq = sentCounter % 2;
			ackMessagePtr->counter = sentCounter;
			ackMessagePtr->receiveid = receiveId;
			
			call CC2420Packet.setPower(&pkt, SET_POWER);
				
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ackMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
				if(DEBUG)
					print("Sucessfully sent packet\n");
    		}
    	}
	}
	
    void sendRequest(uint16_t relayNodeid) {
    	requestMessage* requestptr;
    	
    	if(receivedCounter == sentCounter) {
    		sentCounter++;
    	}

    	if(!busy) {
    		requestptr = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
    		print("Preparing to send packet with counter: " + sentCounter + " and " + relayNodeid + "\n");
    		
    		requestptr->nodeid = TOS_NODE_ID;
			requestptr->seq = sentCounter % 2;
			requestptr->counter = sentCounter;
			requestptr->data = 0;

			if(relayNodeid != 0)
				requestptr->relayNodeid = relayNodeid;
			
			call CC2420Packet.setPower(&pkt, SET_POWER);
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
				call Timer1.startOneShot(500);
				
				if(DEBUG)
					print("Sucessfully sent packet with length: " + sizeof(requestMessage) + " and seq: " + requestptr->seq + "\n");
			}
    	}
    }
    
    bool isOutOfRange() {
    	int16_t previousPositions = 0;
    	int16_t lastPosition = call RssiQueue.head();
    	uint8_t i;
    	
    	for(i = 1; i <= call RssiQueue.size() - 1; i++) {	
			previousPositions += call RssiQueue.element(i);
		}
		
		int16_t avgPreviousPositions = previousPositions/(call RssiQueue.size()-1);	
    	
    	if (lastPosition <= avgPreviousPositions && lastPosition < THRESHOLD)
			return TRUE;
		return FALSE;
    }
		    
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
	}
	
	event void Timer0.fired() {
		// Main loop
		// Runs every time timer is fired
		
		if(DEBUG)
			print("Relayposition: " + relayPosition + "\n");
		
		if(relayPosition == 0) {
			sendRequest(0);
		}
		else {
			sendRequest(1);
		}
		/*
		if(relayPosition == 0) {
			sendRequest(0);
		} 
		else if (relayPosition == 1) 
		{
			sendRequest(2); 
		}
		else if (relayPosition == 2) {
			sendRequest(0);
		}
		else if (relayPosition == 3) {
			sendRequest(1);
		}
		*/
	}
	
	event void Timer1.fired() {
    	if(receivedCounter != sentCounter) {
    		if(DEBUG)
    			print("Did not get a response, resending ...\n");
    		setLedRed();
    		
    		// Runner is out of reach, increment position
    		if(errorCount >= 3) {
    			relayPosition++;
				errorCount = 0;
    		} else {
				errorCount++;
			}
    	}
    	else {
    		if(DEBUG)
    			print("Did get a response, all done ...\n");
    	}
    }
    
   	event void Timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}

	event void AMControl.startDone(error_t error){
		if (error == SUCCESS) {
			call Timer0.startPeriodic(5000);
		}
		else
			call AMControl.start();
	}

	event void AMControl.stopDone(error_t error){}

	event void AMSend.sendDone(message_t *msg, error_t error){
		 if (&pkt == msg) {
		 	busy = FALSE;
		}
	}	

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if(len == sizeof(ackMessage)) {
			ackMessage* ackMsg = (ackMessage*)payload;
			errorCount = 0;
			call Timer1.stop();
			
			if(DEBUG)
				print("Received ackMessage!\n");
			
			if(ackMsg->seq == ackMsg->counter % 2) {
				print("Ack received! Seq no. match!");
				setLedGreen();
				receivedCounter++;
			}
			 
		} else if (len == sizeof(requestMessage)) {
			requestMessage* requestMsg = (requestMessage*)payload;
			errorCount = 0;
			call Timer1.stop();
			
			print("Received requestMessage with data: " + requestMsg->data + "\n");
			
			if(requestMsg->seq == sentCounter % 2) {
				if(DEBUG)
					print("Request received. Seq no. match!\n");
				setLedGreen();
					
				if(requestMsg->relayNodeid == 0 || UINT_MAX || UINT_MIN) {
					call RssiQueue.enqueue(call CC2420Packet.getRssi(msg));
				}
				
				if(requestMsg->data == -1) {
					relayPosition++;
				}
				sendAck(requestMsg->nodeid);
			}
		}
		return msg;
	}
}