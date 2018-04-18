#ifndef RUNNER_H
#define RUNNER_H

enum {
  PRINT = 1,
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 460,
  AM_DATA_MSG = 3,
  SET_POWER = 31,
  ARQ_RETRYCOUNT = 10,
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

#endif /* RUNNER_H */
