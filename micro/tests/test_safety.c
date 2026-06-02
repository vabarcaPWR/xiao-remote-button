#include "mock_relay.h"
#include "mock_safety_hal.h"
#include "safety/safety.h"
#include "unity.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_safety_init_initializes_hal_and_cancels_any_pending_timeout(void)
{
    safety_hal_init_ExpectAndReturn(0);
    safety_hal_cancel_timeout_Expect();

    int err = safety_init();

    TEST_ASSERT_EQUAL_INT(0, err);
}

void test_safety_init_returns_error_when_hal_init_fails(void)
{
    safety_hal_init_ExpectAndReturn(-5);

    int err = safety_init();

    TEST_ASSERT_EQUAL_INT(-5, err);
}

void test_safety_on_ble_disconnected_schedules_30s_timeout(void)
{
    safety_hal_schedule_timeout_Expect(SAFETY_DISCONNECT_TIMEOUT_MS);

    safety_on_ble_disconnected();
}

void test_safety_on_ble_connected_cancels_pending_timeout(void)
{
    safety_hal_cancel_timeout_Expect();

    safety_on_ble_connected();
}

void test_safety_timeout_expired_turns_relay_off(void)
{
    relay_off_ExpectAndReturn(0);

    safety_timeout_expired();
}

void test_safety_reconnect_within_window_cancels_timeout(void)
{
    safety_hal_schedule_timeout_Expect(SAFETY_DISCONNECT_TIMEOUT_MS);
    safety_on_ble_disconnected();

    safety_hal_cancel_timeout_Expect();
    safety_on_ble_connected();
}

void test_safety_multiple_disconnects_reschedule_timeout(void)
{
    safety_hal_schedule_timeout_Expect(SAFETY_DISCONNECT_TIMEOUT_MS);
    safety_on_ble_disconnected();

    safety_hal_schedule_timeout_Expect(SAFETY_DISCONNECT_TIMEOUT_MS);
    safety_on_ble_disconnected();
}
