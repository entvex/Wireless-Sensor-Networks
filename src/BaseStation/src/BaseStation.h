#ifndef BASE_STATION_H
#define BASE_STATION_H

enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 3000,
  AM_DATA_MSG = 3,
  SET_POWER = 31,
  ARQ_RETRYCOUNT = 10
};

typedef nx_struct BlinkToRadioMsg {
  		nx_uint16_t nodeid;
 		nx_uint16_t counter;
  		nx_int8_t rssi;
  		nx_uint8_t lqi;
  		nx_uint8_t power;
  		nx_uint16_t seq;
} BlinkToRadioMsg;

#endif /* BASE_STATION_H */
