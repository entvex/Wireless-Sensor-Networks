#ifndef BASE_STATION_H
#define BASE_STATION_H

enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 3000,
  AM_DATA_MSG = 3,
  SET_POWER = 31,
  ARQ_RETRYCOUNT = 10,
  RELAY_NODE_ID = 2
};

typedef nx_struct RequestMsg {
  		nx_uint16_t nodeid;
		nx_uint16_t relayNodeid;
 		nx_uint16_t counter;
		nx_uint16_t seq;
  		nx_int8_t rssi;
  		nx_uint8_t lqi;
  		nx_uint8_t power;
} RequestMsg;

typedef nx_struct ReplyMsg {
		nx_uint16_t nodeid;
 		nx_uint16_t counter;
		nx_uint16_t seq;
		nx_uint16_t data;
		nx_int8_t rssi;
  		nx_uint8_t lqi;
  		nx_uint8_t power;
} ReplyMsg;

#endif /* BASE_STATION_H */
