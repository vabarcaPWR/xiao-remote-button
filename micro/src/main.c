#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/usb/usb_device.h>
#include <zephyr/logging/log.h>

#include "ble/ble_relay_service.h"

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

static const struct gpio_dt_spec led_red = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
static const struct gpio_dt_spec led_green = GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios);
static const struct gpio_dt_spec led_blue = GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios);

/* External relay on P0.02 */
#define RELAY_NODE DT_ALIAS(relay0)
static const struct gpio_dt_spec relay_gpio = GPIO_DT_SPEC_GET(RELAY_NODE, gpios);

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

    if (gpio_is_ready_dt(&relay_gpio)) {
        gpio_pin_configure_dt(&relay_gpio, GPIO_OUTPUT_INACTIVE);
        LOG_INF("Relay GPIO ready (OFF)");
    } else {
        LOG_WRN("Relay GPIO not ready");
    }

    int err = ble_relay_service_init();
    if (err) {
        LOG_ERR("BLE init failed: %d", err);
        while (1) {
            gpio_pin_toggle_dt(&led_red);
            k_msleep(100);
        }
    }

    LOG_INF("Advertising as 'xiao-relay'");

    /*
     * LED status:
     *   Red blinking (500ms)  = advertising / disconnected
     *   Green solid            = connected
     *   Blue solid             = relay ON (Sprint 4)
     *   Red fast (100ms)      = BLE error (above)
     */
    while (1) {
        leds_all_off();

        if (ble_relay_is_connected()) {
            gpio_pin_set_dt(&led_green, 1);
            k_msleep(200);
        } else {
            gpio_pin_set_dt(&led_red, 1);
            k_msleep(500);
            gpio_pin_set_dt(&led_red, 0);
            k_msleep(500);
        }
    }

    return 0;
}

