cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(xiao-remote-button)

target_sources(app PRIVATE
    src/main.c
    src/ble/ble_relay_service.c
    src/relay/relay.c
    src/relay/relay_hal.c
    src/safety/safety.c
    src/safety/safety_hal.c
    src/watchdog/watchdog.c
)

target_include_directories(app PRIVATE src)
