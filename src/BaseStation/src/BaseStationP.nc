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
	uses interface Queue<int8_t> as RssiQueue;
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	uint8_t receivedCounter = 0;
	uint8_t sentCounter = 0;
	uint8_t errorCount = 0;
	uint8_t relayPosition = 0;
	uint8_t overallPacketLoss = 0;
	
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
		
	void sendAck(uint16_t receiveId) {
		ackMessage* ackMessagePtr;
    	
    	if(!busy) {
    		ackMessagePtr = (ackMessage*)(call Packet.getPayload(&pkt, sizeof(ackMessage)));
    		
    		if(DEBUG) {
    			printf("Preparing to send packet with counter: %d\n", sentCounter);
    			printfflush();
    		}
    	
    		ackMessagePtr->nodeid = TOS_NODE_ID;
			ackMessagePtr->seq = sentCounter % 2;
			ackMessagePtr->counter = sentCounter;
			ackMessagePtr->receiveid = receiveId;
			
			call CC2420Packet.setPower(&pkt, SET_POWER);
				
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ackMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
				if(DEBUG) {
					printf("Sucessfully sent packet\n");
					printfflush();
				}
    		}
    	}
	}
	
    void sendRequest(uint16_t relayNodeid) {
    	requestMessage* requestptr;

    	if(receivedCounter >= sentCounter) {
    		sentCounter++;
    	}

    	if(!busy) {
    		requestptr = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
    		printf("Preparing to send packet with counter: %d\n",  sentCounter);
    		printfflush();
    		
    		requestptr->nodeid = TOS_NODE_ID;
			requestptr->seq = sentCounter % 2;
			requestptr->counter = sentCounter;
			requestptr->data = 0;

			if(relayNodeid != 0) {
				printf("Message will be relayed!\n");
				printfflush();
				requestptr->relayNodeid = relayNodeid;
			}
			else {
				requestptr->relayNodeid = 0;
			}
			
			call CC2420Packet.setPower(&pkt, SET_POWER);
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
				call Timer1.startOneShot(200);
				
				if(DEBUG) {
					printf("Sucessfully sent packet with length and seq: %d, %d\n", sizeof(requestptr), requestptr->seq);
					printfflush();
				}
			}
    	}
    }
    
    bool isOutOfRange() {
    	int16_t avgPreviousPositions, previousPositions, lastPosition = 0;
    	uint8_t i;
		
		if(!call RssiQueue.full())
			return FALSE;
    	
    	for(i = 0; i < QUEUE_MAX_SIZE; i++) {	
			previousPositions += call RssiQueue.element(i);
		}
		lastPosition = RssiQueue.head();
		avgPreviousPositions = previousPositions/QUEUE_MAX_SIZE;
		newPosition = (lastPosition*0.5)+(avgPreviousPositions*0.5)
		
		if(DEBUG) {
			printf("New estimated position of runner node: %d", newPosition);
			printfflush();	
		}

    	if(newPosition > THRESHOLD)
    		return TRUE;
    	return FALSE;
    }
	
	void clearRssiQueue() {
		while(!call RssiQueue.empty()) {
			call RssiQueue.dequeue();
		}
	}
		    
    event void Boot.booted() {
    	// Call stuff when booted
    	int i = 0;
		call AMControl.start();
		
		// Init rssi queue with default values
		for(i = 0; i < call RssiQueue.size(); i++) {
			call RssiQueue.enqueue(-30);
		}
		
		printf("BaseStation started!\n");
		printfflush();
	}
	
	event void Timer0.fired() {
		// Main loop
		// Runs every time timer is fired
		bool isOutOfRange = FALSE;
		isOutOfRange = isOutOfRange();
		
		if(DEBUG) {
			printf("Relayposition: %d\n", relayPosition);
			printf("Overall packet loss: %d\n", overallPacketLoss);
			printfflush();
		}
		
		// Adjust relay position if node is out of range
		// and we are sending directly
		if(isOutOfRange && relayPosition == 0 || relayPosition == 2) {
			clearRssiQueue();
			relayPosition++;
    		errorCount = 0;
    	}
		
		if(relayPosition == 0 || relayPosition == 2) {
			printf("Sending message direct!\n");
			printfflush();
			sendRequest(0);
		}
		else if(relayPosition == 1){
			printf("Relaying message to relay node 1\n");
			printfflush();
			sendRequest(2);
		}
		else if(relayPosition == 3) {
			printf("Relaying message to relay node 2\n");
			printfflush();
			sendRequest(1);
		}
	}
		
	event void Timer1.fired() {
    	if(receivedCounter != sentCounter) {
    		if(DEBUG) {
    			overallPacketLoss++;
    			printf("Did not get a response, keeping counter at: %d\n", sentCounter);
    			printfflush();
    		}
    		setLedRed();
    		
    		// Runner is out of reach, increment position
    		if(errorCount >= 3) {
				clearRssiQueue();
    			if(relayPosition >= 3) {
    				relayPosition = 0;
    				errorCount = 0;
    			}
    			else {
    				relayPosition++;
    				errorCount = 0;
    			}
    		} else {
				errorCount++;
			}
    	}
    	else {
    		if(DEBUG) {
    			printf("Did get a response, all done ...\n");
    			printfflush();
    		}
    	}
    }
    
   	event void Timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}

	event void AMControl.startDone(error_t error){
		if (error == SUCCESS) {
			call Timer0.startPeriodic(2000);
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
			
			if(DEBUG) {
				printf("Received ackMessage with counter, seq and nodeid: %d, %d, %d\n", ackMsg->counter, ackMsg->seq, ackMsg->nodeid);
				printfflush();
			}
			
			if(ackMsg->seq == ackMsg->counter % 2) {
				if(DEBUG) {
					printf("Ack received! Seq no. match! Incrementing received counter! Rssi: %d\n", call CC2420Packet.getRssi(msg));
					printfflush();
				}
				setLedGreen();
				receivedCounter++;
			}
			 
		} else if (len == sizeof(requestMessage)) {
			requestMessage* requestMsg = (requestMessage*)payload;
			errorCount = 0;
			call Timer1.stop();
			
			printf("Received requestMessage with data: %d\n", requestMsg->data);
			printfflush();
			
			if(requestMsg->seq == sentCounter % 2) {
				if(DEBUG) {
					printf("Request received. Seq no. match! Rssi: %d\n", call CC2420Packet.getRssi(msg));
					printfflush();
				}
				setLedGreen();
				
				if(requestMsg->relayNodeid == 0 ||  UINT_MAX) {
					printf("RelayNodeid is zero, so saving the RSSI\n");
					printfflush();
					call RssiQueue.dequeue();
					call RssiQueue.enqueue(call CC2420Packet.getRssi(msg));
				}
				
				if(requestMsg->data != 0) {
					sendAck(requestMsg->nodeid);
					if(requestMsg->data == -1) {
						clearRssiQueue();
						if(relayPosition >= 3)
							relayPosition = 0;
						else
							
							relayPosition++;
					}
				}
			}
		}
		return msg;
	}
}