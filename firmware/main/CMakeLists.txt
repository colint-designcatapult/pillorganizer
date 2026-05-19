# This file was automatically generated for projects
# without default 'CMakeLists.txt' file


# Filter out certs folder
list(FILTER app_sources EXCLUDE REGEX ".*certs/.*")

# --- Source files ---
# Core sources always compiled (hardware-specific code is #if-guarded inside)
set(MAIN_SRCS
    main.c
    mux_io.c
    nvs_wrapper.c
    IS31FL3730.c
    i2c_dev.c
    ledc.c
    ledc_emu.c
    supervisor.c
    wifi_provision.c
    device_config.c
    sleep_state.c
    network.c
    rtc.c
    claim.c
    mqtt_wrapper.c
    fleet_provision.c
    mqtt.c
    shadow_state.c
    supervisor_operation.c
    supervisor_provision.c
    supervisor_ota.c
    battery.c
    web_server.c
    event_outbox.c
    eng_cli.c
    ota.c
)

# --- Required components ---
set(MAIN_REQUIRES
    nvs_flash
    efuse
    fatfs
    sdmmc
    esp_driver_sdmmc
    esp_http_server
    esp_http_client
    esp_event
    esp_netif
    esp_timer
    console
    app_update
    driver
    esp_driver_gpio
    esp_adc
    esp-tls
    mqtt
    mbedtls
    json
    coreMQTT
    Device-Shadow-for-AWS-IoT-embedded-sdk
    coreJSON
    backoffAlgorithm
    Fleet-Provisioning-for-AWS-IoT-embedded-sdk
    Jobs-for-AWS-IoT-embedded-sdk
    esp_https_ota
)

list(APPEND MAIN_REQUIRES
    wifi_provisioning
    esp_wifi
    ulp
    bt
    protocomm
    esp_eth
)

# Register the component WITH embedded files
idf_component_register(
    SRCS
        ${MAIN_SRCS}
    INCLUDE_DIRS 
        ${CMAKE_CURRENT_LIST_DIR}
        ${CMAKE_CURRENT_LIST_DIR}/include
    EMBED_TXTFILES 
        ${CMAKE_CURRENT_LIST_DIR}/certs/root_ca.pem
        ${CMAKE_CURRENT_LIST_DIR}/data/engineering.html
    REQUIRES
        ${MAIN_REQUIRES}
)

# Set C++23 standard
target_compile_options(${COMPONENT_LIB} PRIVATE -std=gnu++23)

set(ulp_app_name "ulp_main")
set(ulp_s_sources "ulp/mux.S")
set(ulp_exp_dep_srcs "main.c")
ulp_embed_binary(${ulp_app_name} "${ulp_s_sources}" "${ulp_exp_dep_srcs}")