#include "Timer.h"
#include "Relay.h"
#include "printf.h"


module RelayC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Timer<TMilli> as Timer2;
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface CC2420Packet;
	uses interface Receive;
}
implementation{

		void sendAcknowledge(requestMessage*);
		void setLedRed();
		void setLedGreen();
		void setLedBlue();
		void printAck(ackMessage* ackmsg);
		void printReq(requestMessage* reqmsg);

		uint16_t requestRunnerCounter = 0;
		uint16_t requestBaseCounter = 0;
		message_t pkt;
		bool busy = TRUE;
		requestMessage requestFromBase, requestFromRunner;
				
		
	event void Boot.booted(){
		
		if(PRINT)
		{
			printf("Hello from Relay with ID: %d\n", TOS_NODE_ID);
    		printfflush();
		}
		call AMControl.start();
		
	}
	
	event void AMControl.stopDone(error_t error){
			
	}
	
	event void AMControl.startDone(error_t error){
		if(error == SUCCESS){
			busy = FALSE;
		}
		else {
			call AMControl.start();
		}	
	}
		
	event void AMSend.sendDone(message_t *msg, error_t error){
		if(&pkt == msg) {
			busy = FALSE;
		}
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if(PRINT)
		{
			printf("Aquired a package with length: %d\n", len);
    		printfflush();
		}
	
		if (len == sizeof(requestMessage)) {
			requestMessage* reqmsg = (requestMessage*) payload;
			
			if(PRINT)
			{
				int RSSI = call CC2420Packet.getRssi(msg);
				printf("Payload is a request message with following data:\n nodeid: %d\n relaynodeid: %d\n counter: %d\n seq: %d\n data: %d\n RSSI: %d\n", reqmsg->nodeid, reqmsg->relayNodeid, reqmsg->counter, reqmsg->seq, reqmsg->data, RSSI);
    			printfflush(); 
			}
			
			if (reqmsg->relayNodeid == TOS_NODE_ID) {
				// Send Acknowledge
				sendAcknowledge(reqmsg);
				
				if (reqmsg->data == 0) {	
					requestFromBase = *reqmsg;
					call Timer0.startPeriodic(TIMER0_PERIOD_MILLI);
					
				}
				else {
					requestFromRunner = *reqmsg;
					call Timer1.startPeriodic(TIMER1_PERIOD_MILLI);
				}
					
			}
			
		}
		else if (len == sizeof(ackMessage)) {
			ackMessage* ackmsg = (ackMessage*) payload;
			
			if(PRINT)
			{
				int RSSI = call CC2420Packet.getRssi(msg);
				printf("Payload is a acknowldge message with following data:\n nodeid: %d\n receiveid: %d\n counter: %d\n seq: %d\n RSSI: %d\n", ackmsg->nodeid, ackmsg->receiveid, ackmsg->counter, ackmsg->seq, RSSI);
    			printfflush(); 
			}
			
			if (ackmsg->receiveid == TOS_NODE_ID){
				if (ackmsg->nodeid == BASESTATION_ID){
					call Timer1.stop();
					requestBaseCounter = 0;
				}
				else if (ackmsg->nodeid == RUNNER_ID){
					call Timer0.stop();
					requestRunnerCounter = 0;
				}
			}
		}
		return msg;
	}
	
	// Got a request from BaseStation
	event void Timer0.fired(){
		if(!busy) {
        	requestMessage* reqmsg = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
        	*reqmsg 		= requestFromBase;
        	reqmsg->nodeid 	= TOS_NODE_ID;
       
       		call CC2420Packet.setPower(&pkt, SIGNAL_STRENGTH_LOW); // sets package size and signal strength	
       
       		if(PRINT)
			{
       			printReq(reqmsg);
       		}
       		
        	if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
            	busy = TRUE;
            	requestRunnerCounter++;
            	setLedBlue();
            }
            
        }
        if(requestRunnerCounter >= TRIES_TO_RESEND) {
        	call Timer0.stop();
        	requestRunnerCounter = 0;
        	requestFromRunner = requestFromBase;
        	requestFromRunner.data = -1;
        	call Timer1.startPeriodic(TIMER1_PERIOD_MILLI);
        }
		return;
	}
	
	// Got a answer from Runner
	event void Timer1.fired(){
		if(!busy) {
        	requestMessage* reqmsg = (requestMessage*)(call Packet.getPayload(&pkt, sizeof(requestMessage)));
        	*reqmsg 		= requestFromRunner;
        	reqmsg->nodeid 	= TOS_NODE_ID;
       
       		call CC2420Packet.setPower(&pkt, SIGNAL_STRENGTH_LOW); // sets package size and signal strength	
       		
       		if(PRINT)
			{
       			printReq(reqmsg);
       		}
       		
        	if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(requestMessage)) == SUCCESS) {
            	busy = TRUE;
            	requestBaseCounter++;
            	setLedRed();
            }
        }
        if(requestBaseCounter >= TRIES_TO_RESEND) {
        	call Timer1.stop();
        	requestBaseCounter = 0;
        }
		return;
	}
	
	event void Timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
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
	
	void setLedRed() {
		call Leds.led0On();
		call Timer2.startOneShot(TIMER2_PERIOD_MILLI);
	}
	void setLedGreen() {
		call Leds.led1On();
		call Timer2.startOneShot(TIMER2_PERIOD_MILLI);
	}
	void setLedBlue() {
		call Leds.led2On();
		call Timer2.startOneShot(TIMER2_PERIOD_MILLI);
	}
	
	void printAck(ackMessage* ackmsg){
		printf("Sending acknowledge with size: %d should be %d\n nodeid: %d\n receiveid: %d\n counter: %d\n seq: %d\n", sizeof(*ackmsg), sizeof(ackMessage), ackmsg->nodeid, ackmsg->receiveid, ackmsg->counter, ackmsg->seq);
    	printfflush();
	}

	
	void printReq(requestMessage* reqmsg){
		printf("Sending request with size: %d should be %d\n nodeid: %d\n relaynodeid: %d\n counter: %d\n seq: %d\n data: %d\n", sizeof(*reqmsg), sizeof(requestMessage), reqmsg->nodeid, reqmsg->relayNodeid, reqmsg->counter, reqmsg->seq, reqmsg->data);
    	printfflush();
	}
		
}