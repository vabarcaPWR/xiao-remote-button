#ifndef RELAY_HAL_H
#define RELAY_HAL_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize the relay hardware (GPIO pins).
     *
     * Configures both relay GPIOs (P0.02 and P0.10) as output and sets them to inactive (LOW).
     * If one pin fails, the system operates with the other (graceful degradation).
     * Returns error only if both pins are unavailable.
     *
     * @return 0 on success, negative error code if both pins fail.
     */
    int relay_hal_init(void);

    /**
     * @brief Set the relay hardware output on both pins simultaneously.
     *
     * @param on true to set GPIOs HIGH (relay ON), false for LOW (relay OFF).
     * @return 0 on success, negative error code on failure.
     */
    int relay_hal_set(bool on);

#ifdef __cplusplus
}
#endif

#endif /* RELAY_HAL_H */
