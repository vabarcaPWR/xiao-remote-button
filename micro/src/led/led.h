#ifndef LED_H
#define LED_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum
    {
        LED_STATE_RELAY_ON_BLE_CONNECTED,
        LED_STATE_RELAY_ON_BLE_DISCONNECTED,
        LED_STATE_RELAY_OFF_BLE_CONNECTED,
        LED_STATE_RELAY_OFF_BLE_DISCONNECTED,
        LED_STATE_ERROR,
    } led_state_t;

    /**
     * @brief Initialize the LED module.
     *
     * @return 0 on success, negative errno on failure.
     */
    int led_init(void);

    /**
     * @brief Update LED output based on relay and BLE state.
     *
     * @param relay_on  true if relay is ON.
     * @param ble_connected true if a BLE central is connected.
     */
    void led_update(bool relay_on, bool ble_connected);

    /**
     * @brief Show error pattern (fast red blink). Non-returning in production.
     */
    void led_show_error(void);

    /**
     * @brief Compute the LED state from relay and BLE inputs.
     *
     * Pure logic, no side effects. Useful for unit testing.
     *
     * @param relay_on  true if relay is ON.
     * @param ble_connected true if a BLE central is connected.
     * @return The corresponding led_state_t.
     */
    led_state_t led_compute_state(bool relay_on, bool ble_connected);

#ifdef __cplusplus
}
#endif

#endif /* LED_H */
