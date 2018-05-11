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
	uses interface Timer<TMilli> as Timer2; //Send Delay between sending ack and data.
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
	void sendData(uint16_t nodeid);
	void setLedRed();
	void setLedGreen();
	void setLedBlue();
	void printAck(ackMessage* ackmsg);
	void printReq(requestMessage* reqmsg);
	void printGotReq(requestMessage* reqmsg);

	bool busy = FALSE;
	message_t pkt;
	
	//Number of resends
	uint8_t resendCounter = 0;
	
	//Used for data transmit
	nx_uint16_t nodeidToSendTo;
	nx_uint16_t counterToSendTo;
	nx_uint16_t seqToSendTo;
	nx_uint16_t relaynodeIdToSendTo;	
		
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
	
	void printSendingData(requestMessage* responsemsg){
		printf("Sending data with size: %d should be %d nodeid: %d relaynodeid: %d seq: %d counter: %d data: %d\n", sizeof(*responsemsg), sizeof(requestMessage), responsemsg->nodeid, responsemsg->relayNodeid, responsemsg->seq, responsemsg->counter, responsemsg->data);
    	printfflush();
	}
	
	event void Timer2.fired(){
		//Send The data
		sendData(nodeidToSendTo);
	}
	
    event void Boot.booted() {
    	// Call stuff when booted
		call AMControl.start();
	}
	
	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}
	
	event void AMControl.startDone(error_t error){
		if (error != SUCCESS)
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
	       		if(PRINT)
				{
            		setLedGreen();
            	}
            }
        }
		return;
	}
	
	void sendData(uint16_t nodeid) {
				
		if (!busy) {
			requestMessage* responsepkt = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
			
			responsepkt->nodeid      = TOS_NODE_ID;
			responsepkt->seq         = seqToSendTo;
			responsepkt->counter     = counterToSendTo;
			responsepkt->relayNodeid = relaynodeIdToSendTo;
			responsepkt->data        = 55;
			
       		if(PRINT)
			{
				printSendingData(responsepkt);
			}
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
				busy = TRUE;
				resendCounter++;
				
	       		if(PRINT)
				{				
					setLedRed();
				}
			}
		}		
		
		if(resendCounter >= TRIES_TO_RESEND){
			call Timer2.stop();
			resendCounter = 0;		
		}
		
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		
		//Got a request
		if(len == sizeof(requestMessage)) {			
			requestMessage* requestpkt = (requestMessage*)payload;
			    		
    		//Check if the request is for me and if it is send sendAcknowledge.
    		if (requestpkt->nodeid == requestpkt->relayNodeid && requestpkt->data == 0) {
    			
	       		if(PRINT)
				{
					setLedBlue();
					printGotReq(requestpkt);
				}
				
    			sendAcknowledge(requestpkt);
    			
    			//Save data needed for data response
    			nodeidToSendTo      = requestpkt->nodeid;
    			counterToSendTo     = requestpkt->counter;
    			seqToSendTo         = requestpkt->seq;
    			relaynodeIdToSendTo = requestpkt->relayNodeid;
    			
    			call Timer2.startPeriodic(TIMER_PERIOD_MILLI);
    		}
		} else if (len == sizeof(ackMessage)){
			ackMessage* ackpkt = (ackMessage*)payload;
    		//Check if the ack is for me and if it is stop sending data.
    		if (ackpkt->receiveid == TOS_NODE_ID ) {
    			call Timer2.stop();
    			resendCounter = 0;
    		}
						
			}
				
	return msg;
	}
}