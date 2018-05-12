#ifndef RELAY_H
#define RELAY_H

enum {
	DEBUG = 0,					// Debug flag, set 0 if no prints are needed
	LED_DEBUG = 0,				// LED Debug flag, set 0 if no prints are needed
	AM_CHANNEL = 4,			// AM Channel
	TIMER0_PERIOD_MILLI = 20,	// Timer used for request towards Runner 
	TIMER1_PERIOD_MILLI = 20,	// Timer used for request towards BaseStation
	TIMER2_PERIOD_MILLI = 100,	// Timer used to turn off LEDs
	TRIES_TO_RESEND = 3,		// Amount of retries before a request is shut down
	BASESTATION_ID = 0,			// ID of BaseStation
	RUNNER_ID = 3,				// ID of Runner
	SIGNAL_STRENGTH_LOW = 1,	// -25.0 dBm
	SIGNAL_STRENGTH_MID = 16,	// -12.5 dBm
	SIGNAL_STRENGTH_HIGH = 31	//   0.0 dBm
};

typedef nx_struct requestMessage {
  		nx_uint32_t nodeid;
		nx_uint32_t relayNodeid;
 		nx_uint32_t counter;
		nx_uint32_t seq;
  		nx_int32_t data;
} requestMessage;

typedef nx_struct ackMessage {
  		nx_uint32_t nodeid;
		nx_uint32_t receiveid;
		nx_uint32_t seq;
		nx_uint32_t counter;
} ackMessage;

#endif /* RELAY_H */
