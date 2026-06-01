#ifndef RELAY_HAL_H
#define RELAY_HAL_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize the relay hardware (GPIO pin).
     *
     * Configures the relay GPIO as output and sets it to inactive (LOW).
     *
     * @return 0 on success, negative error code on failure.
     */
    int relay_hal_init(void);

    /**
     * @brief Set the relay hardware output.
     *
     * @param on true to set GPIO HIGH (relay ON), false for LOW (relay OFF).
     * @return 0 on success, negative error code on failure.
     */
    int relay_hal_set(bool on);

#ifdef __cplusplus
}
#endif

#endif /* RELAY_HAL_H */
