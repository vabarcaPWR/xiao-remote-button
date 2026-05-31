#ifndef BLE_RELAY_SERVICE_H
#define BLE_RELAY_SERVICE_H

#ifdef __cplusplus
extern "C" {
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

#ifdef __cplusplus
}
#endif

#endif /* BLE_RELAY_SERVICE_H */
