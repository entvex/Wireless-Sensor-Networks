#ifndef BLINK_TO_RADIO_H
#define BLINK_TO_RADIO_H


enum {
	AM_BLINKTORADIO = 26,
	TIMER_PERIOD_MILLI = 250
};

typedef nx_struct BlinkToRadioMsg {
	nx_uint16_t nodeid;
	nx_uint16_t counter;
} BlinkToRadioMsg;

#endif /* BLINK_TO_RADIO_H */
