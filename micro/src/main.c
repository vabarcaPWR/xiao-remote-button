#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/usb/usb_device.h>

#include "ble/ble_relay_service.h"

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

#define RELAY_NODE DT_ALIAS(led0)
static const struct gpio_dt_spec relay_gpio = GPIO_DT_SPEC_GET(RELAY_NODE, gpios);

int main(void)
{
    if (usb_enable(NULL))
        LOG_WRN("USB init failed");

    if (!gpio_is_ready_dt(&relay_gpio))
    {
        LOG_ERR("GPIO device not ready");
        return -1;
    }

    gpio_pin_configure_dt(&relay_gpio, GPIO_OUTPUT_INACTIVE);
    LOG_INF("Relay GPIO configured as OUTPUT LOW (OFF)");

    int err = ble_relay_service_init();
    if (err)
    {
        LOG_ERR("BLE init failed (err %d)", err);
        return err;
    }

    while (1)
        k_sleep(K_FOREVER);

    return 0;
}

