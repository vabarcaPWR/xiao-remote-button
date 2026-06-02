#include "timer/relay_timer.h"

static relay_timer_expired_cb_t expired_cb;
static uint16_t remaining_s;
static bool running;

int relay_timer_init(relay_timer_expired_cb_t on_expired)
{
    if (!on_expired)
        return -22; /* -EINVAL */

    expired_cb = on_expired;
    remaining_s = 0;
    running = false;
    return 0;
}

void relay_timer_start(uint16_t duration_s)
{
    if (duration_s == 0)
        remaining_s = RELAY_TIMER_INDEFINITE_MAX_SECONDS;
    else if (duration_s > RELAY_TIMER_MAX_SECONDS)
        remaining_s = RELAY_TIMER_MAX_SECONDS;
    else
        remaining_s = duration_s;

    running = true;
}

void relay_timer_cancel(void)
{
    running = false;
    remaining_s = 0;
}

uint16_t relay_timer_remaining(void)
{
    return running ? remaining_s : 0;
}

bool relay_timer_is_running(void)
{
    return running;
}

void relay_timer_tick(void)
{
    if (!running)
        return;

    if (remaining_s > 0)
        remaining_s--;

    if (remaining_s == 0)
    {
        running = false;
        if (expired_cb)
            expired_cb();
    }
}
