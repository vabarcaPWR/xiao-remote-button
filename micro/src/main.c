#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/usb/usb_device.h>
#include <zephyr/logging/log.h>

#include "ble/ble_relay_service.h"

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

/* Built-in Red LED for status */
static const struct gpio_dt_spec status_led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);

/* External relay on P0.02 */
#define RELAY_NODE DT_ALIAS(relay0)
static const struct gpio_dt_spec relay_gpio = GPIO_DT_SPEC_GET(RELAY_NODE, gpios);

int main(void)
{
    /* Status LED init */
    gpio_pin_configure_dt(&status_led, GPIO_OUTPUT_ACTIVE);

    /* USB console */
    usb_enable(NULL);
    k_msleep(1000);

    LOG_INF("=== XIAO-RELAY BOOT ===");

    /* Relay GPIO init */
    if (gpio_is_ready_dt(&relay_gpio)) {
        gpio_pin_configure_dt(&relay_gpio, GPIO_OUTPUT_INACTIVE);
        LOG_INF("Relay GPIO ready (OFF)");
    } else {
        LOG_WRN("Relay GPIO not ready");
    }

    /* BLE init + advertising */
    int err = ble_relay_service_init();
    if (err) {
        LOG_ERR("BLE init failed: %d", err);
        while (1) {
            gpio_pin_toggle_dt(&status_led);
            k_msleep(100);
        }
    }

    LOG_INF("Advertising as 'xiao-relay'");

    /* Slow blink = running OK */
    while (1) {
        gpio_pin_toggle_dt(&status_led);
        k_msleep(1000);
    }

    return 0;
}

