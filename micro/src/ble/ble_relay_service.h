#ifndef BLE_RELAY_SERVICE_H
#define BLE_RELAY_SERVICE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize BLE subsystem and start advertising.
     *
     * Registers the relay control GATT service and begins
     * advertising with device name and service UUID.
     *
     * @return 0 on success, negative errno on failure.
     */
    int ble_relay_service_init(void);

    /**
     * @brief Check if a BLE central is currently connected.
     *
     * @return true if connected, false otherwise.
     */
    bool ble_relay_is_connected(void);

    /**
     * @brief Send a BLE notification with the current timer remaining value.
     */
    void ble_relay_timer_remaining_notify(void);

#ifdef __cplusplus
}
#endif

#endif /* BLE_RELAY_SERVICE_H */
