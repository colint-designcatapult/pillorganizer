# This file was automatically generated for projects
# without default 'CMakeLists.txt' file


# Filter out certs folder
list(FILTER app_sources EXCLUDE REGEX ".*certs/.*")

# Register the component WITH embedded files
idf_component_register(
    SRCS 
        main.c
        mux_io.c
        nvs_wrapper.c
        IS31FL3730.c
        i2c_dev.c
        ledc.c
        supervisor.c
        wifi_provision.c
        device_config.c
        network.c
        rtc.c
        claim.c
        mqtt_wrapper.c
        fleet_provision.c
        mqtt.c
        shadow_state.c
        supervisor_operation.c
        supervisor_provision.c
        battery.c
        web_server.c
        event_outbox.c
    INCLUDE_DIRS 
        ${CMAKE_CURRENT_LIST_DIR}
        ${CMAKE_CURRENT_LIST_DIR}/include
    EMBED_TXTFILES 
        ${CMAKE_CURRENT_LIST_DIR}/certs/root_ca.pem
        ${CMAKE_CURRENT_LIST_DIR}/data/engineering.html
    REQUIRES
        nvs_flash
        efuse
        esp_http_server
        esp_http_client
        wifi_provisioning
        esp_wifi
        esp_event
        esp_netif
        esp_timer
        console
        app_update
        driver
        esp_driver_gpio 
        esp_adc
        ulp
        esp-tls
        mqtt
        bt
        mbedtls
        json
        coreMQTT
        Device-Shadow-for-AWS-IoT-embedded-sdk
        coreJSON
        backoffAlgorithm
        Fleet-Provisioning-for-AWS-IoT-embedded-sdk
        wifi_provisioning
        protocomm
)

# Set C++23 standard
target_compile_options(${COMPONENT_LIB} PRIVATE -std=gnu++23)

set(ulp_app_name "ulp_main")

# 2. Point to your assembly source file(s)
set(ulp_s_sources "ulp/mux.S")

# 3. Tell CMake which C files depend on the generated ULP variables.
# This ensures the ULP is compiled BEFORE app_main.c, so the "ulp_main.h" 
# header is generated in time for your C code to include it.
set(ulp_exp_dep_srcs "main.c")

# 4. Trigger the ULP build and embed the binary into the ESP32 flash
ulp_embed_binary(${ulp_app_name} "${ulp_s_sources}" "${ulp_exp_dep_srcs}")