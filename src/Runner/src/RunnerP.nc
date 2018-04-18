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
	uses interface Timer<TMilli> as Timer0; //Handles leds.
	uses interface Timer<TMilli> as Timer1; //handle AMControl start.
	uses interface Timer<TMilli> as Timer2; //Send Delay between sending ack and data
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

	void sendAcknowledge(requestMessage*);
	void setLedRed();
	void setLedGreen();
	void setLedBlue();
	void printAck(ackMessage* ackmsg);
	void printReq(requestMessage* reqmsg);
	void printGotReq(requestMessage* reqmsg);

	bool busy = FALSE;
	message_t pkt;
	uint8_t sentCounter = 0;
	uint8_t receivedCounter = 0;
	uint8_t errorCount = 0;
	
	nx_uint16_t nodeidToSendTo;
		
	void setLedRed() {
		call Leds.led0On();
		call Timer0.startOneShot(100);
	}
	
	void setLedGreen() {
		call Leds.led1On();
		call Timer0.startOneShot(100);
	}
	
	void setLedBlue() {
		call Leds.led2On();
		call Timer0.startOneShot(100);
	}
	
	event void Timer0.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}
	
	void printAck(ackMessage* ackmsg){
		printf("Sending acknowledge with size: %d should be %d nodeid: %d receiveid: %d seq: %d counter: %d\n", sizeof(*ackmsg), sizeof(ackMessage), ackmsg->nodeid, ackmsg->receiveid, ackmsg->seq, ackmsg->counter);
    	printfflush();
	}

	
	void printReq(requestMessage* reqmsg){
		printf("Sending request with size: %d should be %d nodeid: %d relaynodeid: %d seq: %d counter: %d data: %d\n", sizeof(*reqmsg), sizeof(requestMessage), reqmsg->nodeid, reqmsg->relayNodeid, reqmsg->seq, reqmsg->counter, reqmsg->data);
    	printfflush();
	}
	
	void printGotReq(requestMessage* reqmsg){
		printf("Got request with size: %d should be %d nodeid: %d relaynodeid: %d seq: %d counter: %d data: %d\n", sizeof(*reqmsg), sizeof(requestMessage), reqmsg->nodeid, reqmsg->relayNodeid, reqmsg->seq, reqmsg->counter, reqmsg->data);
    	printfflush();
	}
	
	event void Timer1.fired(){
		
	}
	
	event void Timer2.fired(){
		
	}
	
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
	}
	
	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}
	
	event void AMControl.startDone(error_t error){
		if (error == SUCCESS)
			call Timer1.startPeriodic(TIMER_PERIOD_MILLI);
		else
			call AMControl.start();
	}
	
	event void AMSend.sendDone(message_t *msg, error_t error){
		 if (&pkt == msg) {
			busy = FALSE;
		}
	}	
	
	
	void sendAcknowledge(requestMessage* reqmsg){
		if(!busy) {
        	ackMessage* ackmsg = (ackMessage*)(call Packet.getPayload(&pkt, sizeof(ackMessage)));
        	ackmsg->nodeid 		= TOS_NODE_ID;
        	ackmsg->receiveid 	= reqmsg->nodeid;
        	ackmsg->seq 		= reqmsg->seq;
        	ackmsg->counter 	= reqmsg->counter;
       		
       		if(PRINT)
			{
       			printAck(ackmsg);
       		}
       		
       		call CC2420Packet.setPower(&pkt, SIGNAL_STRENGTH_LOW); // sets package size and signal strength	
       
        	if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ackMessage)) == SUCCESS) {
            	busy = TRUE;
            	setLedGreen();
            }
        }
		return;
	}
	
		
	void sendData(uint16_t nodeid) {
				
		if (!busy) {
			requestMessage* requestpkt = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
			
			requestpkt->nodeid = TOS_NODE_ID;
			requestpkt->counter = sentCounter;
			requestpkt->data = 25;

			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
				busy = TRUE;
				setLedBlue();
			}
		}
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		setLedBlue();
		
		//Got a request
		if(len == sizeof(requestMessage)) {
			requestMessage* requestpkt = (requestMessage*)payload;
			errorCount = 0;
			    		
    		//Check if the request is for me and if it is send sendAcknowledge.
    		if (requestpkt->nodeid == requestpkt->relayNodeid && requestpkt->data == 0) {			
				printGotReq(requestpkt);
    			sendAcknowledge(requestpkt);    			
    			call Timer2.startPeriodic(100);
    		}
		}
	return msg;
	}	
}