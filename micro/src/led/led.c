#include "led/led.h"
#include "led/led_hal.h"

static bool blink_phase;

int led_init(void)
{
    blink_phase = false;
    return led_hal_init();
}

led_state_t led_compute_state(bool relay_on, bool ble_connected)
{
    if (relay_on && ble_connected)
        return LED_STATE_RELAY_ON_BLE_CONNECTED;
    if (relay_on && !ble_connected)
        return LED_STATE_RELAY_ON_BLE_DISCONNECTED;
    if (!relay_on && ble_connected)
        return LED_STATE_RELAY_OFF_BLE_CONNECTED;
    return LED_STATE_RELAY_OFF_BLE_DISCONNECTED;
}

void led_update(bool relay_on, bool ble_connected)
{
    led_state_t state = led_compute_state(relay_on, ble_connected);
    blink_phase = !blink_phase;

    switch (state)
    {
    case LED_STATE_RELAY_ON_BLE_CONNECTED:
        led_hal_set(false, false, blink_phase);
        break;
    case LED_STATE_RELAY_ON_BLE_DISCONNECTED:
        led_hal_set(false, false, true);
        break;
    case LED_STATE_RELAY_OFF_BLE_CONNECTED:
        led_hal_set(false, blink_phase, false);
        break;
    case LED_STATE_RELAY_OFF_BLE_DISCONNECTED:
        led_hal_set(false, true, false);
        break;
    case LED_STATE_ERROR:
        led_hal_set(blink_phase, false, false);
        break;
    }
}

void led_show_error(void)
{
    blink_phase = !blink_phase;
    led_hal_set(blink_phase, false, false);
}
