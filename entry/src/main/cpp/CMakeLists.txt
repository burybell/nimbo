cmake_minimum_required(VERSION 3.5.0)
project(nimbo_script_runtime LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QUICKJS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/quickjs)

add_library(quickjs STATIC
  ${QUICKJS_DIR}/dtoa.c
  ${QUICKJS_DIR}/libregexp.c
  ${QUICKJS_DIR}/libunicode.c
  ${QUICKJS_DIR}/quickjs.c
)
target_compile_definitions(quickjs PRIVATE _GNU_SOURCE QUICKJS_NG_BUILD)
target_compile_options(quickjs PRIVATE
  -Wno-implicit-fallthrough
  -Wno-sign-compare
  -Wno-unused-parameter
  -Wno-unused-but-set-variable
)
target_include_directories(quickjs PUBLIC ${QUICKJS_DIR})
target_link_libraries(quickjs PUBLIC m)

add_library(nimbo_script SHARED script_runtime.cpp)
target_include_directories(nimbo_script PRIVATE ${QUICKJS_DIR})
target_link_libraries(nimbo_script PUBLIC quickjs libace_napi.z.so)
