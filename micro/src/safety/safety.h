#ifndef SAFETY_H
#define SAFETY_H

#ifdef __cplusplus
extern "C"
{
#endif

#define SAFETY_DISCONNECT_TIMEOUT_MS 30000U

    /**
     * @brief Initialize the safety subsystem.
     *
     * Prepares the disconnect-timeout machinery. Must be called once at boot
     * before any safety_on_ble_* call.
     *
     * @return 0 on success, negative errno on failure.
     */
    int safety_init(void);

    /**
     * @brief Notify the safety subsystem that a BLE central connected.
     *
     * Cancels any pending disconnect timeout so the relay state is preserved
     * while the user is in control.
     */
    void safety_on_ble_connected(void);

    /**
     * @brief Notify the safety subsystem that the BLE central disconnected.
     *
     * Schedules the disconnect timeout. If no reconnection occurs before it
     * expires, the relay is forced OFF.
     */
    void safety_on_ble_disconnected(void);

    /**
     * @brief Called by the HAL when the disconnect timeout expires.
     *
     * Drives the fail-safe action (turns the relay OFF). Public so unit tests
     * can invoke it directly without depending on Zephyr timers.
     */
    void safety_timeout_expired(void);

#ifdef __cplusplus
}
#endif

#endif /* SAFETY_H */
