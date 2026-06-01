#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/usb/usb_device.h>

#include "ble/ble_relay_service.h"
#include "relay/relay.h"

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

static const struct gpio_dt_spec led_red = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
static const struct gpio_dt_spec led_green = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);
static const struct gpio_dt_spec led_blue = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);

static void leds_all_off(void)
{
    gpio_pin_set_dt(&led_red, 0);
    gpio_pin_set_dt(&led_green, 0);
    gpio_pin_set_dt(&led_blue, 0);
}

int main(void)
{
    gpio_pin_configure_dt(&led_red, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&led_green, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&led_blue, GPIO_OUTPUT_INACTIVE);

    usb_enable(NULL);
    k_msleep(1000);

    LOG_INF("=== XIAO-RELAY BOOT ===");

    int err = relay_init();
    if (err)
    {
        LOG_ERR("Relay init failed: %d", err);
        while (1)
        {
            gpio_pin_toggle_dt(&led_red);
            k_msleep(100);
        }
    }
    LOG_INF("Relay initialized (OFF)");

    err = ble_relay_service_init();
    if (err)
    {
        LOG_ERR("BLE init failed: %d", err);
        while (1)
        {
            gpio_pin_toggle_dt(&led_red);
            k_msleep(100);
        }
    }

    LOG_INF("Advertising as 'xiao-relay'");

    while (1)
    {
        leds_all_off();

        if (ble_relay_is_connected())
        {
            if (relay_get_state())
                gpio_pin_set_dt(&led_blue, 1);
            else
                gpio_pin_set_dt(&led_green, 1);
            k_msleep(200);
        }
        else
        {
            gpio_pin_set_dt(&led_red, 1);
            k_msleep(500);
            gpio_pin_set_dt(&led_red, 0);
            k_msleep(500);
        }
    }

    return 0;
}
