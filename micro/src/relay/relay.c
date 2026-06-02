#include <stdbool.h>
#include <stddef.h>

#ifndef UNIT_TEST
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(relay, LOG_LEVEL_INF);
#endif

#include "relay/relay.h"
#include "relay/relay_hal.h"

static bool relay_state;
static relay_state_changed_cb_t state_changed_cb;

int relay_init(void)
{
    int err = relay_hal_init();
    if (err)
        return err;

    relay_state = false;
    return 0;
}

int relay_on(void)
{
    int err = relay_hal_set(true);
    if (err)
        return err;

    relay_state = true;
    if (state_changed_cb)
        state_changed_cb(true);
    return 0;
}

int relay_off(void)
{
    int err = relay_hal_set(false);
    if (err)
        return err;

    relay_state = false;
    if (state_changed_cb)
        state_changed_cb(false);
    return 0;
}

bool relay_get_state(void)
{
    return relay_state;
}

void relay_set_state_changed_cb(relay_state_changed_cb_t cb)
{
    state_changed_cb = cb;
}
