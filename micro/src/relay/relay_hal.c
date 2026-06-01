#include <stdbool.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/logging/log.h>

#include "relay/relay_hal.h"

LOG_MODULE_REGISTER(relay_hal, LOG_LEVEL_INF);

static const struct gpio_dt_spec relay_gpio = GPIO_DT_SPEC_GET(DT_ALIAS(relay0), gpios);

int relay_hal_init(void)
{
    if (!gpio_is_ready_dt(&relay_gpio))
        return -ENODEV;

    return gpio_pin_configure_dt(&relay_gpio, GPIO_OUTPUT_INACTIVE);
}

int relay_hal_set(bool on)
{
    if (!gpio_is_ready_dt(&relay_gpio))
        return -ENODEV;

    return gpio_pin_set_dt(&relay_gpio, on ? 1 : 0);
}
