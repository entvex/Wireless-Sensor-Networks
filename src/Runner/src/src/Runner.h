#ifndef RUNNER_H
#define RUNNER_H

enum {
  PRINT = 0,
  AM_CHANNEL = 4,
  TIMER_PERIOD_MILLI = 20,
  TRIES_TO_RESEND = 3,
  AM_DATA_MSG = 3,
  SET_POWER = 31,
  ARQ_RETRYCOUNT = 10,
  SIGNAL_STRENGTH_LOW = 1,	// -25 dB
  SIGNAL_STRENGTH_MID = 16,
  SIGNAL_STRENGTH_HIGH = 31	//   0 dBl
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

#endif /* RUNNER_H */