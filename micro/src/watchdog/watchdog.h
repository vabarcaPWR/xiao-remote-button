#ifndef WATCHDOG_H
#define WATCHDOG_H

#ifdef __cplusplus
extern "C"
{
#endif

#define WATCHDOG_TIMEOUT_MS 15000U

    /**
     * @brief Initialize the hardware watchdog with a 15 s timeout.
     *
     * If the watchdog is not fed within the timeout, the SoC resets,
     * which restarts the firmware with the relay GPIO low (fail-safe).
     *
     * @return 0 on success, negative errno on failure.
     */
    int watchdog_init(void);

    /**
     * @brief Feed (kick) the watchdog to prevent a reset.
     *
     * Must be called periodically from the main loop while the system is healthy.
     */
    void watchdog_feed(void);

#ifdef __cplusplus
}
#endif

#endif /* WATCHDOG_H */
