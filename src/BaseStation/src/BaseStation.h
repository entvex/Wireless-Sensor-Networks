#ifndef BASE_STATION_H
#define BASE_STATION_H

enum {
  AM_CHANNEL = 4,
  AM_DATA_MSG = 3,
  SET_POWER = 1,
  ARQ_ERRORCOUNT = 3,
  BASESTATION_NODE_ID = 0,
  RELAY_NODE_ID = 1,
  RUNNER_NODE_ID = 3,
  THRESHOLD = -40,
  QUEUE_MAX_SIZE = 5,
  DEBUG = FALSE,
  RELEASE = TRUE
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

#endif /* BASE_STATION_H */
