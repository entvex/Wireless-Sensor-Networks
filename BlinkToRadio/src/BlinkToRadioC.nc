// $Id: BlinkC.nc,v 1.5 2008/06/26 03:38:26 regehr Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include "Timer.h"
#include "BlinkToRadio.h"


module BlinkToRadioC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	
	uses interface Receive;
}
implementation{
	
	uint16_t counter = 0;
	
	bool busy = FALSE;
	message_t pkt;
	
	event void Boot.booted(){
		
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t error){
		if(error == SUCCESS){
		call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
	}
	else {
		call AMControl.start();
		}				
	}
	
	event void AMControl.stopDone(error_t error){
		
	}
	
	event void AMSend.sendDone(message_t *msg, error_t error){
		if(&pkt == msg){
			busy = FALSE;
			}
	}
	

	event void Timer0.fired(){
		counter++;
		//call Leds.set(counter);
		
		if(!busy){
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->counter = counter;
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
				busy = TRUE;
				}					
			}
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if (len == sizeof(BlinkToRadioMsg)) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*) payload;
			call Leds.set(btrpkt->counter);
		}
		return msg;
	}
	
	
	
}