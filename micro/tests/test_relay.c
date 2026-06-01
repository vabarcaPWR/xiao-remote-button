#include "mock_relay_hal.h"
#include "relay/relay.h"
#include "unity.h"

void setUp(void)
{
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
