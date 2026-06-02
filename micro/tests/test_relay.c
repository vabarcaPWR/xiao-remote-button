#include "mock_relay_hal.h"
#include "relay/relay.h"
#include "unity.h"

static bool cb_called;
static bool cb_received_state;

static void test_state_changed_cb(bool state)
{
    cb_called = true;
    cb_received_state = state;
}

void setUp(void)
{
    cb_called = false;
    cb_received_state = false;
    relay_set_state_changed_cb(NULL);

    relay_hal_init_ExpectAndReturn(0);
    int err = relay_init();
    TEST_ASSERT_EQUAL_INT(0, err);
}

void tearDown(void)
{
}

void test_relay_init_sets_state_off(void)
{
    TEST_ASSERT_FALSE(relay_get_state());
}

void test_relay_on_sets_state_true(void)
{
    relay_hal_set_ExpectAndReturn(true, 0);

    int err = relay_on();

    TEST_ASSERT_EQUAL_INT(0, err);
    TEST_ASSERT_TRUE(relay_get_state());
}

void test_relay_off_sets_state_false(void)
{
    relay_hal_set_ExpectAndReturn(true, 0);
    relay_on();

    relay_hal_set_ExpectAndReturn(false, 0);
    int err = relay_off();

    TEST_ASSERT_EQUAL_INT(0, err);
    TEST_ASSERT_FALSE(relay_get_state());
}

void test_relay_on_returns_zero_on_success(void)
{
    relay_hal_set_ExpectAndReturn(true, 0);

    TEST_ASSERT_EQUAL_INT(0, relay_on());
}

void test_relay_off_returns_zero_on_success(void)
{
    relay_hal_set_ExpectAndReturn(false, 0);

    TEST_ASSERT_EQUAL_INT(0, relay_off());
}

void test_relay_on_returns_error_on_hal_failure(void)
{
    relay_hal_set_ExpectAndReturn(true, -1);

    int err = relay_on();

    TEST_ASSERT_EQUAL_INT(-1, err);
    TEST_ASSERT_FALSE(relay_get_state());
}

void test_relay_off_returns_error_on_hal_failure(void)
{
    relay_hal_set_ExpectAndReturn(true, 0);
    relay_on();

    relay_hal_set_ExpectAndReturn(false, -1);
    int err = relay_off();

    TEST_ASSERT_EQUAL_INT(-1, err);
    TEST_ASSERT_TRUE(relay_get_state());
}

void test_relay_init_returns_error_on_hal_failure(void)
{
    relay_hal_init_ExpectAndReturn(-5);

    int err = relay_init();

    TEST_ASSERT_EQUAL_INT(-5, err);
}

void test_relay_on_calls_state_changed_callback_with_true(void)
{
    relay_set_state_changed_cb(test_state_changed_cb);
    relay_hal_set_ExpectAndReturn(true, 0);

    relay_on();

    TEST_ASSERT_TRUE(cb_called);
    TEST_ASSERT_TRUE(cb_received_state);
}

void test_relay_off_calls_state_changed_callback_with_false(void)
{
    relay_set_state_changed_cb(test_state_changed_cb);
    relay_hal_set_ExpectAndReturn(true, 0);
    relay_on();
    cb_called = false;

    relay_hal_set_ExpectAndReturn(false, 0);
    relay_off();

    TEST_ASSERT_TRUE(cb_called);
    TEST_ASSERT_FALSE(cb_received_state);
}

void test_relay_callback_not_called_on_hal_failure(void)
{
    relay_set_state_changed_cb(test_state_changed_cb);
    relay_hal_set_ExpectAndReturn(true, -1);

    relay_on();

    TEST_ASSERT_FALSE(cb_called);
}

void test_relay_no_crash_when_callback_not_set(void)
{
    relay_hal_set_ExpectAndReturn(true, 0);

    int err = relay_on();

    TEST_ASSERT_EQUAL_INT(0, err);
}
