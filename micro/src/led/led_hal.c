#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>

#include "led/led_hal.h"

static const struct gpio_dt_spec led_red = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
static const struct gpio_dt_spec led_green = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);
static const struct gpio_dt_spec led_blue = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);

int led_hal_init(void)
{
    int err;

    err = gpio_pin_configure_dt(&led_red, GPIO_OUTPUT_INACTIVE);
    if (err)
        return err;

    err = gpio_pin_configure_dt(&led_green, GPIO_OUTPUT_INACTIVE);
    if (err)
        return err;

    err = gpio_pin_configure_dt(&led_blue, GPIO_OUTPUT_INACTIVE);
    if (err)
        return err;

    return 0;
}

void led_hal_set(bool red, bool green, bool blue)
{
    gpio_pin_set_dt(&led_red, red ? 1 : 0);
    gpio_pin_set_dt(&led_green, green ? 1 : 0);
    gpio_pin_set_dt(&led_blue, blue ? 1 : 0);
}
