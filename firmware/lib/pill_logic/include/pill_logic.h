#pragma once

#ifdef __cplusplus
#define _PILL_LOGIC_EXTERN extern "C"__attribute__((visibility("default"))) __attribute__((used))
#else
#define _PILL_LOGIC_EXTERN __attribute__((visibility("default"))) __attribute__((used))
#endif

#include "pill_logic.pb.h"

