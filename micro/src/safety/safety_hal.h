#ifndef SAFETY_HAL_H
#define SAFETY_HAL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Initialize the safety HAL (delayable work item).
     *
     * @return 0 on success, negative errno on failure.
     */
    int safety_hal_init(void);

    /**
     * @brief Schedule the disconnect timeout to expire after @p ms milliseconds.
     *
     * If a timeout is already scheduled it is rescheduled to the new deadline.
     *
     * @param ms Delay in milliseconds.
     */
    void safety_hal_schedule_timeout(uint32_t ms);

    /**
     * @brief Cancel a pending disconnect timeout, if any.
     */
    void safety_hal_cancel_timeout(void);

#ifdef __cplusplus
}
#endif

#endif /* SAFETY_HAL_H */
