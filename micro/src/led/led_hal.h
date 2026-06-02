#ifndef LED_HAL_H
#define LED_HAL_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize LED GPIO hardware.
     *
     * @return 0 on success, negative errno on failure.
     */
    int led_hal_init(void);

    /**
     * @brief Set individual LED outputs.
     *
     * @param red   true = red LED on.
     * @param green true = green LED on.
     * @param blue  true = blue LED on.
     */
    void led_hal_set(bool red, bool green, bool blue);

#ifdef __cplusplus
}
#endif

#endif /* LED_HAL_H */
