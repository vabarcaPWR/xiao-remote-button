#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

#include "safety/safety.h"
#include "safety/safety_hal.h"

LOG_MODULE_REGISTER(safety_hal, LOG_LEVEL_INF);

static void safety_work_handler(struct k_work *work)
{
    ARG_UNUSED(work);
    LOG_WRN("Disconnect timeout expired -> forcing relay OFF");
    safety_timeout_expired();
}

static K_WORK_DELAYABLE_DEFINE(safety_work, safety_work_handler);

int safety_hal_init(void)
{
    return 0;
}

void safety_hal_schedule_timeout(uint32_t ms)
{
    k_work_reschedule(&safety_work, K_MSEC(ms));
}

void safety_hal_cancel_timeout(void)
{
    k_work_cancel_delayable(&safety_work);
}
