#!/bin/bash

# 确保脚本在任何失败时停止执行
set -e

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 帮助函数
function show_help() {
    echo -e "${GREEN}Usage: $0 [options]${NC}"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -c, --clean      Clean the build directory before building"
    echo "  -d, --debug      Build in debug mode (default is release)"
    echo "  -f, --flash      Build and flash the target"
    echo "  -s, --size       Show memory usage after building"
    echo "  --disasm         Generate disassembly file"
    echo "  --compile-cmds   Generate compile_commands.json and copy to project root"
    echo ""
    echo "Examples:"
    echo "  $0 -c           Clean and build"
    echo "  $0 -d           Build in debug mode"
    echo "  $0 -f           Build and flash"
}

# 解析命令行参数
CLEAN=0
DEBUG=0
FLASH=0
SIZE=0
DISASM=0
COMPILE_CMDS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN=1
            shift
            ;;
        -d|--debug)
            DEBUG=1
            shift
            ;;
        -f|--flash)
            FLASH=1
            shift
            ;;
        -s|--size)
            SIZE=1
            shift
            ;;
        --disasm)
            DISASM=1
            shift
            ;;
        --compile-cmds)
            COMPILE_CMDS=1
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 设置构建目录
BUILD_DIR="build"

# 清理构建目录
if [[ $CLEAN -eq 1 ]]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "$BUILD_DIR"
    exit 0
fi

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 设置构建类型
BUILD_TYPE="Release"
if [[ $DEBUG -eq 1 ]]; then
    BUILD_TYPE="Debug"
fi

# 运行CMake配置
echo -e "${GREEN}Configuring CMake with ${BUILD_TYPE} build...${NC}"
cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"

# 额外生成compile_commands.json并复制到项目根目录
if [[ $COMPILE_CMDS -eq 1 ]]; then
    echo -e "${GREEN}Generating compile_commands.json...${NC}"
    cmake -B "$BUILD_DIR" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    cp "$BUILD_DIR/compile_commands.json" .
    echo -e "${GREEN}compile_commands.json copied to project root${NC}"
fi

# 构建项目
echo -e "${GREEN}Building project...${NC}"
cmake --build "$BUILD_DIR" -j$(nproc)

# 显示内存使用情况
if [[ $SIZE -eq 1 ]]; then
    echo -e "${GREEN}Memory usage:${NC}"
    cmake --build "$BUILD_DIR" --target size
fi

# 生成反汇编文件
if [[ $DISASM -eq 1 ]]; then
    echo -e "${GREEN}Generating disassembly...${NC}"
    cmake --build "$BUILD_DIR" --target disasm
fi

# 烧录目标
if [[ $FLASH -eq 1 ]]; then
    echo -e "${GREEN}Flashing target...${NC}"
    cmake --build "$BUILD_DIR" --target flash
fi

echo -e "${GREEN}Build completed successfully!${NC}"