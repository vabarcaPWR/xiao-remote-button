#ifndef RELAY_TIMER_H
#define RELAY_TIMER_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

#define RELAY_TIMER_MAX_SECONDS 21600
#define RELAY_TIMER_INDEFINITE_MAX_SECONDS 600

    /**
     * @brief Callback type invoked when the timer expires.
     */
    typedef void (*relay_timer_expired_cb_t)(void);

    /**
     * @brief Initialize the relay timer module.
     *
     * @param on_expired Callback when timer expires (must not be NULL).
     * @return 0 on success, negative errno on failure.
     */
    int relay_timer_init(relay_timer_expired_cb_t on_expired);

    /**
     * @brief Start the relay timer.
     *
     * @param duration_s Duration in seconds. 0 = indefinite (capped at 10 min).
     *                   Non-zero values capped at RELAY_TIMER_MAX_SECONDS.
     */
    void relay_timer_start(uint16_t duration_s);

    /**
     * @brief Cancel the running timer.
     */
    void relay_timer_cancel(void);

    /**
     * @brief Get remaining time in seconds.
     *
     * @return Remaining seconds, 0 if not running.
     */
    uint16_t relay_timer_remaining(void);

    /**
     * @brief Check if the timer is currently running.
     *
     * @return true if running, false otherwise.
     */
    bool relay_timer_is_running(void);

    /**
     * @brief Tick the timer by 1 second. Call from main loop at 1Hz.
     */
    void relay_timer_tick(void);

#ifdef __cplusplus
}
#endif

#endif /* RELAY_TIMER_H */
