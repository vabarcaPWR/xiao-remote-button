#include <stdbool.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/logging/log.h>

#include "relay/relay_hal.h"

LOG_MODULE_REGISTER(relay_hal, LOG_LEVEL_INF);

static const struct gpio_dt_spec relay_gpio0 = GPIO_DT_SPEC_GET(DT_ALIAS(relay0), gpios);
static const struct gpio_dt_spec relay_gpio1 = GPIO_DT_SPEC_GET(DT_ALIAS(relay1), gpios);

static bool gpio0_ready;
static bool gpio1_ready;

int relay_hal_init(void)
{
    gpio0_ready = gpio_is_ready_dt(&relay_gpio0);
    gpio1_ready = gpio_is_ready_dt(&relay_gpio1);

    if (!gpio0_ready && !gpio1_ready)
        return -ENODEV;

    int err = 0;

    if (gpio0_ready)
    {
        err = gpio_pin_configure_dt(&relay_gpio0, GPIO_OUTPUT_INACTIVE);
        if (err)
        {
            LOG_WRN("Failed to configure relay GPIO0 (P0.02): %d", err);
            gpio0_ready = false;
        }
    }

    if (gpio1_ready)
    {
        int err1 = gpio_pin_configure_dt(&relay_gpio1, GPIO_OUTPUT_INACTIVE);
        if (err1)
        {
            LOG_WRN("Failed to configure relay GPIO1 (P1.15): %d", err1);
            gpio1_ready = false;
        }
    }

    if (!gpio0_ready && !gpio1_ready)
        return -ENODEV;

    return 0;
}

int relay_hal_set(bool on)
{
    if (!gpio0_ready && !gpio1_ready)
        return -ENODEV;

    int val = on ? 1 : 0;
    bool any_success = false;

    if (gpio0_ready)
    {
        int err = gpio_pin_set_dt(&relay_gpio0, val);
        if (!err)
            any_success = true;
        else
            LOG_WRN("Failed to set relay GPIO0 (P0.02): %d", err);
    }

    if (gpio1_ready)
    {
        int err = gpio_pin_set_dt(&relay_gpio1, val);
        if (!err)
            any_success = true;
        else
            LOG_WRN("Failed to set relay GPIO1 (P1.15): %d", err);
    }

    return any_success ? 0 : -EIO;
}
