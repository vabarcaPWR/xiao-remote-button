#include "timer/relay_timer.h"
#include "unity.h"

static int expired_count;

static void on_expired(void)
{
    expired_count++;
}

void setUp(void)
{
    expired_count = 0;
    relay_timer_init(on_expired);
}

void tearDown(void)
{
}

void test_init_returns_error_with_null_callback(void)
{
    TEST_ASSERT_EQUAL_INT(-22, relay_timer_init(NULL));
}

void test_init_success(void)
{
    TEST_ASSERT_EQUAL_INT(0, relay_timer_init(on_expired));
}

void test_not_running_after_init(void)
{
    TEST_ASSERT_FALSE(relay_timer_is_running());
    TEST_ASSERT_EQUAL_UINT16(0, relay_timer_remaining());
}

void test_start_with_duration_sets_running(void)
{
    relay_timer_start(60);

    TEST_ASSERT_TRUE(relay_timer_is_running());
    TEST_ASSERT_EQUAL_UINT16(60, relay_timer_remaining());
}

void test_start_indefinite_caps_at_600(void)
{
    relay_timer_start(0);

    TEST_ASSERT_EQUAL_UINT16(RELAY_TIMER_INDEFINITE_MAX_SECONDS, relay_timer_remaining());
}

void test_start_over_max_caps_at_max(void)
{
    relay_timer_start(30000);

    TEST_ASSERT_EQUAL_UINT16(RELAY_TIMER_MAX_SECONDS, relay_timer_remaining());
}

void test_tick_decrements_remaining(void)
{
    relay_timer_start(10);

    relay_timer_tick();

    TEST_ASSERT_EQUAL_UINT16(9, relay_timer_remaining());
}

void test_tick_fires_callback_on_expiry(void)
{
    relay_timer_start(2);

    relay_timer_tick();
    TEST_ASSERT_EQUAL_INT(0, expired_count);

    relay_timer_tick();
    TEST_ASSERT_EQUAL_INT(1, expired_count);
    TEST_ASSERT_FALSE(relay_timer_is_running());
}

void test_tick_does_nothing_when_not_running(void)
{
    relay_timer_tick();

    TEST_ASSERT_EQUAL_INT(0, expired_count);
    TEST_ASSERT_FALSE(relay_timer_is_running());
}

void test_cancel_stops_timer(void)
{
    relay_timer_start(60);
    relay_timer_cancel();

    TEST_ASSERT_FALSE(relay_timer_is_running());
    TEST_ASSERT_EQUAL_UINT16(0, relay_timer_remaining());
}

void test_cancel_prevents_expiry_callback(void)
{
    relay_timer_start(2);
    relay_timer_tick();
    relay_timer_cancel();
    relay_timer_tick();

    TEST_ASSERT_EQUAL_INT(0, expired_count);
}

void test_restart_resets_countdown(void)
{
    relay_timer_start(10);
    relay_timer_tick();
    relay_timer_tick();

    relay_timer_start(60);

    TEST_ASSERT_EQUAL_UINT16(60, relay_timer_remaining());
}

void test_full_countdown_fires_once(void)
{
    relay_timer_start(3);

    relay_timer_tick();
    relay_timer_tick();
    relay_timer_tick();
    relay_timer_tick();

    TEST_ASSERT_EQUAL_INT(1, expired_count);
}
