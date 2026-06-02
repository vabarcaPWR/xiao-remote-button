#include "led/led.h"
#include "mock_led_hal.h"
#include "unity.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_led_compute_state_relay_on_ble_connected(void)
{
    TEST_ASSERT_EQUAL(LED_STATE_RELAY_ON_BLE_CONNECTED, led_compute_state(true, true));
}

void test_led_compute_state_relay_on_ble_disconnected(void)
{
    TEST_ASSERT_EQUAL(LED_STATE_RELAY_ON_BLE_DISCONNECTED, led_compute_state(true, false));
}

void test_led_compute_state_relay_off_ble_connected(void)
{
    TEST_ASSERT_EQUAL(LED_STATE_RELAY_OFF_BLE_CONNECTED, led_compute_state(false, true));
}

void test_led_compute_state_relay_off_ble_disconnected(void)
{
    TEST_ASSERT_EQUAL(LED_STATE_RELAY_OFF_BLE_DISCONNECTED, led_compute_state(false, false));
}

void test_led_init_calls_hal_init(void)
{
    led_hal_init_ExpectAndReturn(0);

    int err = led_init();

    TEST_ASSERT_EQUAL_INT(0, err);
}

void test_led_init_returns_error_on_hal_failure(void)
{
    led_hal_init_ExpectAndReturn(-5);

    int err = led_init();

    TEST_ASSERT_EQUAL_INT(-5, err);
}

void test_led_update_relay_on_ble_connected_blinks_blue(void)
{
    led_hal_init_ExpectAndReturn(0);
    led_init();

    led_hal_set_Expect(false, false, true);
    led_update(true, true);

    led_hal_set_Expect(false, false, false);
    led_update(true, true);
}

void test_led_update_relay_on_ble_disconnected_solid_blue(void)
{
    led_hal_init_ExpectAndReturn(0);
    led_init();

    led_hal_set_Expect(false, false, true);
    led_update(true, false);

    led_hal_set_Expect(false, false, true);
    led_update(true, false);
}

void test_led_update_relay_off_ble_connected_blinks_green(void)
{
    led_hal_init_ExpectAndReturn(0);
    led_init();

    led_hal_set_Expect(false, true, false);
    led_update(false, true);

    led_hal_set_Expect(false, false, false);
    led_update(false, true);
}

void test_led_update_relay_off_ble_disconnected_solid_green(void)
{
    led_hal_init_ExpectAndReturn(0);
    led_init();

    led_hal_set_Expect(false, true, false);
    led_update(false, false);

    led_hal_set_Expect(false, true, false);
    led_update(false, false);
}

void test_led_show_error_blinks_red(void)
{
    led_hal_init_ExpectAndReturn(0);
    led_init();

    led_hal_set_Expect(true, false, false);
    led_show_error();

    led_hal_set_Expect(false, false, false);
    led_show_error();
}
