cmake_minimum_required(VERSION 3.16)

# 项目名称
project(stm32_template C ASM)

# STM32配置
set(STM32_FAMILY "f1" CACHE STRING "STM32 family (f1, f4, etc.)")
set(STM32_DEVICE "stm32f103c8" CACHE STRING "STM32 device")
set(CPU_TYPE "cortex-m3" CACHE STRING "CPU type")

# 设置交叉编译工具链
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

# 设置编译器
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_SIZE arm-none-eabi-size)

# 禁用编译器检查（避免交叉编译问题）
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# 设置输出目录到build目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# 编译器标志
set(COMMON_FLAGS "-mcpu=${CPU_TYPE} -mthumb -msoft-float -fno-common -ffunction-sections -fdata-sections -g3 -Os -Wall -Wextra")

# C标志
set(CMAKE_C_FLAGS "${COMMON_FLAGS} -std=c11 -DSTM32F1")

# ASM标志
set(CMAKE_ASM_FLAGS "${COMMON_FLAGS} -x assembler-with-cpp")

# 链接标志
set(CMAKE_EXE_LINKER_FLAGS "${COMMON_FLAGS} -static -nostartfiles -Wl,--gc-sections -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group")

# libopencm3配置
set(LIBOPENCM3_DIR ${CMAKE_SOURCE_DIR}/libopencm3)

# 确保libopencm3子模块已初始化
if(NOT EXISTS ${LIBOPENCM3_DIR}/Makefile)
    message(STATUS "Initializing libopencm3 submodule...")
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} submodule update --init
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        RESULT_VARIABLE GIT_SUBMOD_RESULT
    )
    if(NOT GIT_SUBMOD_RESULT EQUAL "0")
        message(FATAL_ERROR "git submodule update --init failed")
    endif()
endif()

# 构建libopencm3
set(LIBOPENCM3_LIB ${LIBOPENCM3_DIR}/lib/libopencm3_stm32${STM32_FAMILY}.a)
add_custom_command(
    OUTPUT ${LIBOPENCM3_LIB}
    COMMAND make -C ${LIBOPENCM3_DIR}
    COMMENT "Building libopencm3"
    VERBATIM
)
add_custom_target(libopencm3 DEPENDS ${LIBOPENCM3_LIB})

# 包含目录
include_directories(${LIBOPENCM3_DIR}/include)

# 链接目录
link_directories(${LIBOPENCM3_DIR}/lib)

# 源文件
set(SOURCES src/main.c)

# 创建可执行文件
add_executable(${PROJECT_NAME}.elf ${SOURCES})

# 添加libopencm3依赖
add_dependencies(${PROJECT_NAME}.elf libopencm3)

# 链接库
target_link_libraries(${PROJECT_NAME}.elf opencm3_stm32${STM32_FAMILY})

# 设置链接脚本
target_link_options(${PROJECT_NAME}.elf PRIVATE
    -T${CMAKE_SOURCE_DIR}/src/ld.stm32.basic
)

# 生成hex和bin文件 - 输出到build目录
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -Oihex ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -Obinary ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE} ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf
    COMMENT "Building ${PROJECT_NAME}.hex and ${PROJECT_NAME}.bin in build directory"
)

# 烧录目标 - 使用OpenOCD烧录elf文件
add_custom_target(flash
    COMMAND openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf verify reset exit"
    DEPENDS ${PROJECT_NAME}.elf
    COMMENT "Flashing the target using OpenOCD"
)

# 启动OpenOCD服务器
add_custom_target(openocd
    COMMAND openocd -f interface/stlink.cfg -f target/stm32f1x.cfg
    COMMENT "Starting OpenOCD server"
)

# 调试目标 - 连接到OpenOCD服务器
add_custom_target(debug
    COMMAND arm-none-eabi-gdb -ex "target extended-remote localhost:3333" -ex "monitor reset halt" -ex "load" -ex "monitor reset init" ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf
    DEPENDS ${PROJECT_NAME}.elf
    COMMENT "Starting GDB debug session with OpenOCD"
)

# 显示内存使用情况
add_custom_target(size
    COMMAND ${CMAKE_SIZE} --format=berkeley ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf
    DEPENDS ${PROJECT_NAME}.elf
    COMMENT "Displaying memory usage"
)

# 反汇编 - 输出到build目录
add_custom_target(disasm
    COMMAND ${CMAKE_OBJDUMP} -d ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.elf > ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.s
    DEPENDS ${PROJECT_NAME}.elf
    COMMENT "Generating disassembly in build directory"
)

# 显示配置信息
message(STATUS "========== Configuration ==========")
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "STM32 Family: ${STM32_FAMILY}")
message(STATUS "STM32 Device: ${STM32_DEVICE}")
message(STATUS "CPU Type: ${CPU_TYPE}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Output Directory: ${CMAKE_BINARY_DIR}")
message(STATUS "===================================")