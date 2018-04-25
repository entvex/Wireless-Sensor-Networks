#ifndef BASE_STATION_H
#define BASE_STATION_H

enum {
  AM_CHANNEL = 10,
  AM_DATA_MSG = 3,
  SET_POWER = 1,
  ARQ_ERRORCOUNT = 3,
  RELAY_NODE_ID = 1,
  RUNNER_NODE_ID = 3,
  THRESHOLD = -40,
  QUEUE_MAX_SIZE = 5,
  DEBUG = TRUE
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

#endif /* BASE_STATION_H */
