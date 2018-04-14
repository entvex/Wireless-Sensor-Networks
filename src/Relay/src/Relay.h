#ifndef RELAY_H
#define RELAY_H


enum {
	PRINT = 1,
	AM_BLINKTORADIO = 6,
	TIMER0_PERIOD_MILLI = 500,
	TIMER1_PERIOD_MILLI = 500,
	TRIES_TO_RESEND = 1,
	BASESTATION_ID = 0,
	RUNNER_ID = 3,
	SIGNAL_STRENGTH_LOW = 1,	// -25 dB
	SIGNAL_STRENGTH_MID = 16,
	SIGNAL_STRENGTH_HIGH = 31	//   0 dB
};

typedef nx_struct requestMessage {
  		nx_uint16_t nodeid;
		nx_uint16_t relayNodeid;
 		nx_uint16_t counter;
		nx_uint16_t seq;
  		nx_int16_t data;
} requestMessage;

typedef nx_struct ackMessage {
  		nx_uint16_t nodeid;
		nx_uint16_t receiveid;
		nx_uint16_t seq;
		nx_uint16_t counter;
} ackMessage;

#endif /* RELAY_H */
