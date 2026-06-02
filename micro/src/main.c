#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/usb/usb_device.h>

#include "ble/ble_relay_service.h"
#include "led/led.h"
#include "relay/relay.h"
#include "safety/safety.h"
#include "watchdog/watchdog.h"

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

int main(void)
{
    usb_enable(NULL);
    k_msleep(1000);

    LOG_INF("=== XIAO-RELAY BOOT ===");

    int err = led_init();
    if (err)
        LOG_ERR("LED init failed: %d", err);

    err = relay_init();
    if (err)
    {
        LOG_ERR("Relay init failed: %d", err);
        while (1)
        {
            led_show_error();
            k_msleep(100);
        }
    }
    LOG_INF("Relay initialized (OFF)");

    err = safety_init();
    if (err)
        LOG_ERR("Safety init failed: %d", err);

    err = ble_relay_service_init();
    if (err)
    {
        LOG_ERR("BLE init failed: %d", err);
        while (1)
        {
            led_show_error();
            k_msleep(100);
        }
    }

    err = watchdog_init();
    if (err)
        LOG_WRN("Watchdog disabled: %d", err);

    LOG_INF("Advertising as 'xiao-relay'");

    while (1)
    {
        watchdog_feed();
        led_update(relay_get_state(), ble_relay_is_connected());
        k_msleep(500);
    }

    return 0;
}
