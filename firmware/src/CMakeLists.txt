# This file was automatically generated for projects
# without default 'CMakeLists.txt' file

# Collect all C and C++ source files
file(GLOB_RECURSE app_sources 
    ${CMAKE_CURRENT_LIST_DIR}/*.c
    ${CMAKE_CURRENT_LIST_DIR}/*.cpp
)

# Filter out certs folder
list(FILTER app_sources EXCLUDE REGEX ".*certs/.*")

# Register the component WITH embedded files
idf_component_register(
    SRCS ${app_sources}
    INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}
    EMBED_TXTFILES 
        ${CMAKE_CURRENT_LIST_DIR}/certs/root_ca.pem
        ${CMAKE_CURRENT_LIST_DIR}/certs/device_cert.crt
        ${CMAKE_CURRENT_LIST_DIR}/certs/device_key.key
        ${CMAKE_CURRENT_LIST_DIR}/certs/claim_cert.pem
        ${CMAKE_CURRENT_LIST_DIR}/certs/claim_key.pem
        ${CMAKE_CURRENT_LIST_DIR}/data/engineering.html
    REQUIRES
        nvs_flash
        esp_http_server
        esp_http_client
        esp_wifi
        esp_event
        esp_netif
        esp_timer
        driver
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
)

# Set C++23 standard
target_compile_options(${COMPONENT_LIB} PRIVATE -std=gnu++23)