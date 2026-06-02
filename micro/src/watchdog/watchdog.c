#include <zephyr/device.h>
#include <zephyr/drivers/watchdog.h>
#include <zephyr/logging/log.h>

#include "watchdog/watchdog.h"

LOG_MODULE_REGISTER(watchdog, LOG_LEVEL_INF);

static const struct device *const wdt_dev = DEVICE_DT_GET_OR_NULL(DT_NODELABEL(wdt0));
static int wdt_channel_id = -1;

int watchdog_init(void)
{
    if (!wdt_dev)
    {
        LOG_ERR("Watchdog device not available");
        return -ENODEV;
    }

    if (!device_is_ready(wdt_dev))
    {
        LOG_ERR("Watchdog device not ready");
        return -ENODEV;
    }

    struct wdt_timeout_cfg wdt_cfg = {
        .window =
            {
                .min = 0U,
                .max = WATCHDOG_TIMEOUT_MS,
            },
        .callback = NULL,
        .flags = WDT_FLAG_RESET_SOC,
    };

    wdt_channel_id = wdt_install_timeout(wdt_dev, &wdt_cfg);
    if (wdt_channel_id < 0)
    {
        LOG_ERR("Watchdog install failed: %d", wdt_channel_id);
        return wdt_channel_id;
    }

    int err = wdt_setup(wdt_dev, 0);
    if (err)
    {
        LOG_ERR("Watchdog setup failed: %d", err);
        return err;
    }

    LOG_INF("Watchdog enabled (%u ms)", WATCHDOG_TIMEOUT_MS);
    return 0;
}

void watchdog_feed(void)
{
    if (wdt_channel_id >= 0)
        wdt_feed(wdt_dev, wdt_channel_id);
}
