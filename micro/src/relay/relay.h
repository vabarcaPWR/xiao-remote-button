#ifndef RELAY_H
#define RELAY_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize the relay module.
     *
     * Configures the relay GPIO and ensures it starts in the OFF state.
     *
     * @return 0 on success, negative error code on failure.
     */
    int relay_init(void);

    /**
     * @brief Turn the relay ON (GPIO HIGH).
     *
     * @return 0 on success, negative error code on failure.
     */
    int relay_on(void);

    /**
     * @brief Turn the relay OFF (GPIO LOW).
     *
     * @return 0 on success, negative error code on failure.
     */
    int relay_off(void);

    /**
     * @brief Get the current relay state.
     *
     * @return true if relay is ON, false if OFF.
     */
    bool relay_get_state(void);

#ifdef __cplusplus
}
#endif

#endif /* RELAY_H */
