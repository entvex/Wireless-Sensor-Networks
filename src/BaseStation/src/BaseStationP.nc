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
}

implementation
{	
	bool busy = FALSE;
	message_t pkt;
	//uint16_t rssiArray[RSSI_ARRAY_SIZE];
	
	uint8_t receivedCounter = 0;
	uint8_t sentCounter = 0;
	
	void sendRequestArq();
	task void sendDirectTask();
	task void sendUsingNorthNodeTask();
	task void sendUsingSouthNodeTask();
	
    void sendRequestArq() {
    	BlinkToRadioMsg* btrpkt;
    	
    	if(receivedCounter == sentCounter)
    		sentCounter++;
    		
    	if(!busy) {
    		btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
    		printf("Preparing to send packet with counter: %d\n", sentCounter);
    		printfflush();
    	
    		if(btrpkt != NULL) {
    			btrpkt->nodeid = TOS_NODE_ID;
				btrpkt->seq = sentCounter % 2;
				btrpkt->counter = sentCounter;
				
				call CC2420Packet.setPower(&pkt, SET_POWER);
				
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
					busy = TRUE;
					call Timer1.startOneShot(500);
					printf("Sucessfully sent packet\n");
					printfflush();
				}
    		}
    	}
    }
	
    // Return true if array is empty, else false
    bool isEmpty(uint8_t* arr, int size)
	{
		int i = 0;
		for(i = 0; i < size; i++) {
			if(arr[i] != INT_MIN || arr[i] != 0) {
				return FALSE;
			}
		}
		return TRUE;
	}
	
	// Return true if array is full, else false
	bool isFull(uint8_t* arr, int size) {
		int i = 0;
		int count = 0;
		for(i = 0; i > size; i++) {
			if(arr[i] != INT_MIN || arr[i] != 0) {
				count++;
			}
		}
		if(count == size)
			return TRUE;
		return FALSE;
	}
	
	task void sendDirectTask() {
		// Send directly
		printf("in sendDirectTask\n");
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
    	//int i = 0;
    	// Call stuff when booted
		call AMControl.start();
		//for (i = 0; i < sizeof(rssiArray); i++) {
  			//rssiArray[i] = 0;
		//}
		printf("BaseStation started!\n");
	}
	
	event void Timer0.fired() {
		// Main loop
		// Runs every time timer is fired
		
		printf("Timer0 fired\n");
		printfflush();
		sendRequestArq();
		
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
    		sendRequestArq();
    	}
    	else {
    		printf("Did not get a response, resending ...\n");
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
		BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
		btrpkt->seq = sentCounter % 2;
		
		if(btrpkt != NULL) {
			printf("Received message with rssi: %d and seq: %d\n", btrpkt->rssi, btrpkt->seq);
			printfflush();
			if(btrpkt->seq == sentCounter % 2) {
			    call Timer1.stop();
				receivedCounter = sentCounter;
			}
		}
		
		return msg;
		// Extract info about rssi
		// btrpkt->rssi = call CC2420Packet.getRssi(msg);
		
		// Forward rssiQueue and save received rssi
//		for (i = 0; i < sizeof(RSSI_ARRAY_SIZE) - 1; i++) {
//  			rssiArray[i] = rssiArray[i+1];
//		}
//		rssiArray[RSSI_ARRAY_SIZE] = btrpkt->rssi;
	}
}
//  enum {
//    UART_QUEUE_LEN = 12,
//    RADIO_QUEUE_LEN = 12,
//  };
//
//  message_t  uartQueueBufs[UART_QUEUE_LEN];
//  message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
//  uint8_t    uartIn, uartOut;
//  bool       uartBusy, uartFull;
//
//  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
//  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
//  uint8_t    radioIn, radioOut;
//  bool       radioBusy, radioFull;
//
//  task void uartSendTask();
//  task void radioSendTask();
//
//  void dropBlink() {
//    call Leds.led2Toggle();
//  }
//
//  void failBlink() {
//    call Leds.led2Toggle();
//  }
//
//  event void Boot.booted() {
//    uint8_t i;
//
//    for (i = 0; i < UART_QUEUE_LEN; i++)
//      uartQueue[i] = &uartQueueBufs[i];
//    uartIn = uartOut = 0;
//    uartBusy = FALSE;
//    uartFull = TRUE;
//
//    for (i = 0; i < RADIO_QUEUE_LEN; i++)
//      radioQueue[i] = &radioQueueBufs[i];
//    radioIn = radioOut = 0;
//    radioBusy = FALSE;
//    radioFull = TRUE;
//
//    call RadioControl.start();
//    call SerialControl.start();
//  }
//
//  event void RadioControl.startDone(error_t error) {
//    if (error == SUCCESS) {
//      radioFull = FALSE;
//    }
//  }
//
//  event void SerialControl.startDone(error_t error) {
//    if (error == SUCCESS) {
//      uartFull = FALSE;
//    }
//  }
//
//  event void SerialControl.stopDone(error_t error) {}
//  event void RadioControl.stopDone(error_t error) {}
//
//  uint8_t count = 0;
//
//  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);
//  
//  event message_t *RadioSnoop.receive[am_id_t id](message_t *msg,
//						    void *payload,
//						    uint8_t len) {
//    return receive(msg, payload, len);
//  }
//  
//  event message_t *RadioReceive.receive[am_id_t id](message_t *msg,
//						    void *payload,
//						    uint8_t len) {
//    return receive(msg, payload, len);
//  }
//
//  message_t* receive(message_t *msg, void *payload, uint8_t len) {
//    message_t *ret = msg;
//
//    atomic {
//      if (!uartFull)
//	{
//	  ret = uartQueue[uartIn];
//	  uartQueue[uartIn] = msg;
//
//	  uartIn = (uartIn + 1) % UART_QUEUE_LEN;
//	
//	  if (uartIn == uartOut)
//	    uartFull = TRUE;
//
//	  if (!uartBusy)
//	    {
//	      post uartSendTask();
//	      uartBusy = TRUE;
//	    }
//	}
//      else
//	dropBlink();
//    }
//    
//    return ret;
//  }
//
//  uint8_t tmpLen;
//  
//  task void uartSendTask() {
//    uint8_t len;
//    am_id_t id;
//    am_addr_t addr, src;
//    message_t* msg;
//    atomic
//      if (uartIn == uartOut && !uartFull)
//	{
//	  uartBusy = FALSE;
//	  return;
//	}
//
//    msg = uartQueue[uartOut];
//    tmpLen = len = call RadioPacket.payloadLength(msg);
//    id = call RadioAMPacket.type(msg);
//    addr = call RadioAMPacket.destination(msg);
//    src = call RadioAMPacket.source(msg);
//    call UartPacket.clear(msg);
//    call UartAMPacket.setSource(msg, src);
//
//    if (call UartSend.send[id](addr, uartQueue[uartOut], len) == SUCCESS)
//      call Leds.led1Toggle();
//    else
//      {
//	failBlink();
//	post uartSendTask();
//      }
//  }
//
//  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
//    if (error != SUCCESS)
//      failBlink();
//    else
//      atomic
//	if (msg == uartQueue[uartOut])
//	  {
//	    if (++uartOut >= UART_QUEUE_LEN)
//	      uartOut = 0;
//	    if (uartFull)
//	      uartFull = FALSE;
//	  }
//    post uartSendTask();
//  }
//
//  event message_t *UartReceive.receive[am_id_t id](message_t *msg,
//						   void *payload,
//						   uint8_t len) {
//    message_t *ret = msg;
//    bool reflectToken = FALSE;
//
//    atomic
//      if (!radioFull)
//	{
//	  reflectToken = TRUE;
//	  ret = radioQueue[radioIn];
//	  radioQueue[radioIn] = msg;
//	  if (++radioIn >= RADIO_QUEUE_LEN)
//	    radioIn = 0;
//	  if (radioIn == radioOut)
//	    radioFull = TRUE;
//
//	  if (!radioBusy)
//	    {
//	      post radioSendTask();
//	      radioBusy = TRUE;
//	    }
//	}
//      else
//	dropBlink();
//
//    if (reflectToken) {
//      //call UartTokenReceive.ReflectToken(Token);
//    }
//    
//    return ret;
//  }
//
//  task void radioSendTask() {
//    uint8_t len;
//    am_id_t id;
//    am_addr_t addr,source;
//    message_t* msg;
//    
//    atomic
//      if (radioIn == radioOut && !radioFull)
//	{
//	  radioBusy = FALSE;
//	  return;
//	}
//
//    msg = radioQueue[radioOut];
//    len = call UartPacket.payloadLength(msg);
//    addr = call UartAMPacket.destination(msg);
//    source = call UartAMPacket.source(msg);
//    id = call UartAMPacket.type(msg);
//
//    call RadioPacket.clear(msg);
//    call RadioAMPacket.setSource(msg, source);
//    
//    if (call RadioSend.send[id](addr, msg, len) == SUCCESS)
//      call Leds.led0Toggle();
//    else
//      {
//	failBlink();
//	post radioSendTask();
//      }
//  }
//
//  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
//    if (error != SUCCESS)
//      failBlink();
//    else
//      atomic
//	if (msg == radioQueue[radioOut])
//	  {
//	    if (++radioOut >= RADIO_QUEUE_LEN)
//	      radioOut = 0;
//	    if (radioFull)
//	      radioFull = FALSE;
//	  }
//    
//    post radioSendTask();
//  }
//}