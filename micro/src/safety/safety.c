#include "safety/safety.h"
#include "relay/relay.h"
#include "safety/safety_hal.h"

int safety_init(void)
{
    int err = safety_hal_init();
    if (err)
        return err;

    safety_hal_cancel_timeout();
    return 0;
}

void safety_on_ble_connected(void)
{
    safety_hal_cancel_timeout();
}

void safety_on_ble_disconnected(void)
{
    safety_hal_schedule_timeout(SAFETY_DISCONNECT_TIMEOUT_MS);
}

void safety_timeout_expired(void)
{
    relay_off();
}
