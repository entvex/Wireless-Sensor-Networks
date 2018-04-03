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

module BaseStationP @safe() {
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
	typedef nx_struct BlinkToRadioMsg {
		nx_uint16_t nodeid;
		nx_uint16_t counter;
		nx_int8_t rssi;
		nx_uint8_t lqi;
		nx_uint8_t power;
	} BlinkToRadioMsg;
	
	// Some fixed types
	enum {
      THRESHOLD = 100,
      DISTANCE = 500,
      TIMER_PERIOD_MILLI = 5000,
	  SEND_POWER = 31
    };
	
	struct response {
		uint8_t position;
		uint8_t heartRate;
	};
	
	struct request {
		message_t buffer[12];
	};
	
	struct Queue* rssiQueue;
	bool busy = FALSE;
	message_t pkt;
	
	task void sendDirectTask();
	task void sendUsingNorthNodeTask();
	task void sendUsingSouthNodeTask();
	
	// All queue implementation code is courtesy of
	// https://gist.github.com/orcnyilmaz/06a7b9b4a03580826e7619fd8381aa00
	struct Queue {
		uint16_t front, rear, size;
		uint16_t capacity;
		uint16_t* array;
	};
	
	// Create a queue of given capacity. queue size is 0
	struct Queue* createQueue(uint16_t capacity)
	{
		struct Queue* queue = (struct Queue*) malloc(sizeof(struct Queue));
		queue->capacity = capacity;
		queue->front = queue->size = 0; 
		queue->rear = capacity - 1;  // This is important, see the enqueue
		queue->array = (uint16_t*) malloc(queue->capacity * sizeof(uint16_t));
		return queue;
	}
	
	uint16_t isFull(struct Queue* queue) {
		return (queue->size == queue->capacity);
	}
	
	uint16_t isEmpty(struct Queue* queue) {
		return (queue->size == 0);
	}
	
	// Remove an item from queue. It changes front and size
	uint16_t dequeue(struct Queue* queue) {
		uint16_t item;
		if (isEmpty(queue))
			return 0;
		item = queue->array[queue->front];
		queue->front = (queue->front + 1)%queue->capacity;
		queue->size = queue->size - 1;
		return item;
	}
	
	// Add an item to the queue
	void enqueue(struct Queue* queue, uint16_t item) {
		if (isFull(queue))
			dequeue(queue);
		queue->rear = (queue->rear + 1) % queue->capacity;
		queue->array[queue->rear] = item;
		queue->size = queue->size + 1;
		printf("%d enqueued to queue\n", item);
	}
	
	// Return front of queue
	uint16_t front(struct Queue* queue) {
		if (isEmpty(queue))
			return 0;
		return queue->array[queue->front];
	}
 
	// Return rear of queue
	uint16_t rear(struct Queue* queue) {
		if (isEmpty(queue))
			return 0;
		return queue->array[queue->rear];
	}
 
    task void sendDirectTask() {
		// Here we send directly to moving node
		if(!busy) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
			if (btrpkt == NULL) {
				return;
			}
			
			// Node Id so moving node can tell msg is from basestation
			btrpkt->nodeid = TOS_NODE_ID;
			
			// Set power to chosen value
			call CC2420Packet.setPower(&pkt, SEND_POWER);
		
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
    }
    
    task void sendUsingSouthNodeTask() {
		// Here we send using south node
    }
    
    task void sendUsingNorthNodeTask() {
		// Here we send using north node
    }
    
    event void Boot.booted() {
    	// Call stuff when booted
		rssiQueue = createQueue(10);
		call AMControl.start();
		printf("BaseStation started!\n");
		printfflush();
	}

	event void Timer0.fired() {
		// Main loop
		// Runs every time timer is fired
		if (isEmpty(rssiQueue) || rear(rssiQueue) > THRESHOLD)
		{
			post sendDirectTask();
		}
		else if (rear(rssiQueue) < THRESHOLD)
		{
			post sendUsingNorthNodeTask();
			post sendUsingSouthNodeTask();
		}	
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
    
		// Extract info about rssi
		BlinkToRadioMsg* btrpkt = NULL;
		btrpkt->rssi = call CC2420Packet.getRssi(msg);
		
		// Save rssi in rssiQueue
		enqueue(rssiQueue, btrpkt->rssi);
		printf("Newest rssi is: %d\n", rear(rssiQueue));
		printfflush();
	
		return ret;
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