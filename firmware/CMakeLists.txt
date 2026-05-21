cmake_minimum_required(VERSION 3.16.0)

list(APPEND EXTRA_COMPONENT_DIRS 
    components/esp-aws-iot/libraries/coreMQTT
    components/esp-aws-iot/libraries/Device-Shadow-for-AWS-IoT-embedded-sdk
    components/esp-aws-iot/libraries/coreJSON
    components/esp-aws-iot/libraries/backoffAlgorithm
    components/esp-aws-iot/libraries/Fleet-Provisioning-for-AWS-IoT-embedded-sdk
    components/esp-aws-iot/libraries/Jobs-for-AWS-IoT-embedded-sdk
)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
set(PROJECT_VER "0.0.2")
project(pill-box)