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
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
	uses interface Queue<uint16_t> as DataQueue;
	uses interface Queue<uint16_t> as RssiQueue;
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	uint8_t receivedCounter = 0;
	uint8_t sentCounter = 0;

	void sendRequest(uint16_t);
	task void sendDirectTask();
	task void sendUsingNorthNodeTask();
	task void sendUsingSouthNodeTask();
	
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
	
    void sendRequest(uint16_t relayNodeid) {
    	RequestMsg* requestptr;
    	
    	if(receivedCounter == sentCounter)
    		sentCounter++;
    		
    	if(!busy) {
    		requestptr = (RequestMsg*)(call Packet.getPayload(&pkt, sizeof(RequestMsg)));
    		printf("Preparing to send packet with counter: %d\n", sentCounter);
    		printfflush();
    	
    		if(requestptr != NULL) {
    			requestptr->nodeid = TOS_NODE_ID;
				requestptr->seq = sentCounter % 2;
				requestptr->counter = sentCounter;
				
				if(relayNodeid != 0)
					requestptr->relayNodeid = relayNodeid;
				
				call CC2420Packet.setPower(&pkt, SET_POWER);
				
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RequestMsg)) == SUCCESS) {
					busy = TRUE;
					setLeds(requestptr->counter);
					call Timer1.startOneShot(500);
					printf("Sucessfully sent packet\n");
					printfflush();
				}
    		}
    	}
    }
		
	task void sendDirectTask() {
		// Send directly
		printf("Sending request direct ...\n");
		printfflush();
	//	sendArq();
		//sendArq(&pkt, 1);
    }
    
    task void sendUsingSouthNodeTask() {
		// Send using south node
		//sendArq(&pkt, 2);
    }
    
    task void sendUsingNorthNodeTask() {
		// Send using north node
		//sendArq(&pkt, 3);
    }
    
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
		printf("BaseStation started!\n");
		printfflush();
	}
	
	event void Timer0.fired() {
		// Main loop
		// Runs every time timer is fired
		
		printf("Timer0 fired\n");
		printfflush();
		sendRequest(0);
		
		//sendDirectTask();
//		if (isEmpty(rssiArray, RSSI_ARRAY_SIZE)) {
//			print("Queue is empty. Calling direct!\n");
//			post sendDirectTask();
//		}
//		
//		if (rssiArray[0] > THRESHOLD) {
//			print("Rssi is within range. Calling direct!\n");
//			post sendDirectTask();
//		}
//		
//		if (rssiArray[0] < THRESHOLD)
//		{
//			print("Rssi is outside range. Calling north/south!\n");
//			post sendUsingNorthNodeTask();
//			post sendUsingSouthNodeTask();
//		}	
	}
	
	event void Timer1.fired() {
    	if(receivedCounter != sentCounter) {
    		printf("Did not get a response, resending ...\n");
    		printfflush();
    		sendRequest(RELAY_NODE_ID);
    	}
    	else {
    		printf("Did get a response, all done ...\n");
    		printfflush();
    	}
    }

	event void AMControl.startDone(error_t error){
		if (error == SUCCESS) {
			printf("Starting timer0\n");
			printfflush();
			call Timer0.startPeriodic(1000);
		}
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
		ReplyMsg* replymsg = (ReplyMsg*)payload;
		
		if(replymsg != NULL) {
			printf("Received message with rssi: %d and seq: %d\n", replymsg->rssi, replymsg->seq);
			printfflush();
			if(replymsg->seq == sentCounter % 2) {
				printf("Correct msg received. Seq no. match!");
				printfflush();
				receivedCounter++;
				call Timer1.stop();
				//call RssiQueue.enqueue(replymsg->counter);
			}
		}
		
		return msg;
	}
}