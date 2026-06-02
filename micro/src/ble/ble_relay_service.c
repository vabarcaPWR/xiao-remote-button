#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

#include "ble_relay_service.h"
#include "relay/relay.h"
#include "safety/safety.h"
#include "timer/relay_timer.h"

LOG_MODULE_REGISTER(ble_relay, LOG_LEVEL_INF);

#define BT_UUID_RELAY_SERVICE_VAL BT_UUID_128_ENCODE(0x00001523, 0x1212, 0xefde, 0x1523, 0x785feabcd123)

#define BT_UUID_RELAY_CMD_VAL BT_UUID_128_ENCODE(0x00001524, 0x1212, 0xefde, 0x1523, 0x785feabcd123)

#define BT_UUID_RELAY_STATE_VAL BT_UUID_128_ENCODE(0x00001525, 0x1212, 0xefde, 0x1523, 0x785feabcd123)

#define BT_UUID_TIMER_DURATION_VAL BT_UUID_128_ENCODE(0x00001526, 0x1212, 0xefde, 0x1523, 0x785feabcd123)

#define BT_UUID_TIMER_REMAINING_VAL BT_UUID_128_ENCODE(0x00001527, 0x1212, 0xefde, 0x1523, 0x785feabcd123)

static struct bt_uuid_128 relay_service_uuid = BT_UUID_INIT_128(BT_UUID_RELAY_SERVICE_VAL);
static struct bt_uuid_128 relay_cmd_uuid = BT_UUID_INIT_128(BT_UUID_RELAY_CMD_VAL);
static struct bt_uuid_128 relay_state_uuid = BT_UUID_INIT_128(BT_UUID_RELAY_STATE_VAL);
static struct bt_uuid_128 timer_duration_uuid = BT_UUID_INIT_128(BT_UUID_TIMER_DURATION_VAL);
static struct bt_uuid_128 timer_remaining_uuid = BT_UUID_INIT_128(BT_UUID_TIMER_REMAINING_VAL);

static struct bt_conn *current_conn;

static ssize_t cmd_write_handler(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len,
                                 uint16_t offset, uint8_t flags)
{
    if (len < 1)
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);

    const uint8_t *data = buf;
    uint8_t cmd = data[0];

    LOG_INF("Relay cmd received: 0x%02X", cmd);

    int err;
    if (cmd == 0x01)
    {
        err = relay_on();
        if (!err)
            relay_timer_start(0);
    }
    else if (cmd == 0x00)
    {
        err = relay_off();
        if (!err)
            relay_timer_cancel();
    }
    else
        return BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED);

    if (err)
        return BT_GATT_ERR(BT_ATT_ERR_UNLIKELY);

    return len;
}

static ssize_t timer_duration_write_handler(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf,
                                            uint16_t len, uint16_t offset, uint8_t flags)
{
    if (len < 2)
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);

    const uint8_t *data = buf;
    uint16_t duration = (uint16_t)data[0] | ((uint16_t)data[1] << 8);

    LOG_INF("Timer duration set: %u s", duration);

    if (relay_get_state())
        relay_timer_start(duration);

    return len;
}

static ssize_t timer_remaining_read_handler(struct bt_conn *conn, const struct bt_gatt_attr *attr, void *buf,
                                            uint16_t len, uint16_t offset)
{
    uint16_t remaining = relay_timer_remaining();
    uint8_t val[2] = {remaining & 0xFF, (remaining >> 8) & 0xFF};
    return bt_gatt_attr_read(conn, attr, buf, len, offset, val, sizeof(val));
}

static ssize_t state_read_handler(struct bt_conn *conn, const struct bt_gatt_attr *attr, void *buf, uint16_t len,
                                  uint16_t offset)
{
    uint8_t state = relay_get_state() ? 0x01 : 0x00;
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &state, sizeof(state));
}

BT_GATT_SERVICE_DEFINE(relay_svc, BT_GATT_PRIMARY_SERVICE(&relay_service_uuid),
                       BT_GATT_CHARACTERISTIC(&relay_cmd_uuid.uuid, BT_GATT_CHRC_WRITE, BT_GATT_PERM_WRITE, NULL,
                                              cmd_write_handler, NULL),
                       BT_GATT_CHARACTERISTIC(&relay_state_uuid.uuid, BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                                              BT_GATT_PERM_READ, state_read_handler, NULL, NULL),
                       BT_GATT_CCC(NULL, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
                       BT_GATT_CHARACTERISTIC(&timer_duration_uuid.uuid, BT_GATT_CHRC_WRITE, BT_GATT_PERM_WRITE, NULL,
                                              timer_duration_write_handler, NULL),
                       BT_GATT_CHARACTERISTIC(&timer_remaining_uuid.uuid, BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                                              BT_GATT_PERM_READ, timer_remaining_read_handler, NULL, NULL),
                       BT_GATT_CCC(NULL, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE), );

static void relay_state_notify(bool state)
{
    uint8_t value = state ? 0x01 : 0x00;
    bt_gatt_notify(NULL, &relay_svc.attrs[4], &value, sizeof(value));
}

void ble_relay_timer_remaining_notify(void)
{
    uint16_t remaining = relay_timer_remaining();
    uint8_t val[2] = {remaining & 0xFF, (remaining >> 8) & 0xFF};
    bt_gatt_notify(NULL, &relay_svc.attrs[9], val, sizeof(val));
}

static void on_timer_expired(void)
{
    LOG_INF("Timer expired, turning relay OFF");
    relay_off();
}

static const struct bt_data ad[] = {
    BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
    BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1),
};

static const struct bt_data sd[] = {
    BT_DATA_BYTES(BT_DATA_UUID128_ALL, BT_UUID_RELAY_SERVICE_VAL),
};

static void advertising_start(void)
{
    int err = bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd, ARRAY_SIZE(sd));
    if (err)
        LOG_ERR("Advertising failed (err %d)", err);
    else
        LOG_INF("Advertising started");
}

static void connected_cb(struct bt_conn *conn, uint8_t err)
{
    if (err)
    {
        LOG_ERR("Connection failed (err %u)", err);
        return;
    }

    char addr[BT_ADDR_LE_STR_LEN];
    bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));
    LOG_INF("BLE connected: %s", addr);

    current_conn = bt_conn_ref(conn);
    safety_on_ble_connected();
}

static void disconnected_cb(struct bt_conn *conn, uint8_t reason)
{
    LOG_INF("BLE disconnected (reason %u)", reason);

    if (current_conn)
    {
        bt_conn_unref(current_conn);
        current_conn = NULL;
    }

    safety_on_ble_disconnected();
    advertising_start();
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
    .connected = connected_cb,
    .disconnected = disconnected_cb,
};

bool ble_relay_is_connected(void)
{
    return current_conn != NULL;
}

int ble_relay_service_init(void)
{
    int err = bt_enable(NULL);
    if (err)
    {
        LOG_ERR("Bluetooth init failed (err %d)", err);
        return err;
    }
    LOG_INF("Bluetooth initialized");

    relay_set_state_changed_cb(relay_state_notify);

    err = relay_timer_init(on_timer_expired);
    if (err)
    {
        LOG_ERR("Timer init failed (err %d)", err);
        return err;
    }

    advertising_start();
    return 0;
}
