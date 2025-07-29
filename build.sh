#!/bin/bash

# 确保脚本在任何失败时停止执行
set -e

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo "  --openocd        Start OpenOCD server for debugging (uses cmake target)"
    echo "  --gdb            Start GDB debug session (uses cmake target)"
    echo "  --debug-all      Start OpenOCD server and GDB in separate terminals"
    echo ""
    echo "Examples:"
    echo "  $0 -c           Clean and build"
    echo "  $0 -d           Build in debug mode"
    echo "  $0 -f           Build and flash"
    echo "  $0 --openocd    Start OpenOCD server"
    echo "  $0 --gdb        Start GDB debugging"
    echo "  $0 --debug-all  Start both OpenOCD and GDB"
}

# 检查OpenOCD是否正在运行
function check_openocd() {
    if lsof -Pi :3333 -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # OpenOCD is running
    else
        return 1  # OpenOCD is not running
    fi
}

# 启动OpenOCD服务器（使用cmake目标）
function start_openocd() {
    echo -e "${BLUE}Starting OpenOCD server using cmake target...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop OpenOCD server${NC}"
    cmake --build "$BUILD_DIR" --target openocd
}

# 启动GDB调试会话（使用cmake目标）
function start_gdb() {
    if ! check_openocd; then
        echo -e "${RED}Error: OpenOCD server is not running!${NC}"
        echo -e "${YELLOW}Please start OpenOCD first with: $0 --openocd${NC}"
        echo -e "${YELLOW}Or use: $0 --debug-all to start both${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Starting GDB debug session using cmake target...${NC}"
    echo -e "${YELLOW}Connecting to OpenOCD at localhost:3333${NC}"
    cmake --build "$BUILD_DIR" --target debug
}

# 在分离的终端中启动OpenOCD和GDB
function start_debug_all() {
    echo -e "${BLUE}Starting OpenOCD and GDB in separate terminals using cmake targets...${NC}"
    
    # 检查终端模拟器
    if command -v gnome-terminal >/dev/null 2>&1; then
        TERMINAL_CMD="gnome-terminal --"
    elif command -v xterm >/dev/null 2>&1; then
        TERMINAL_CMD="xterm -e"
    elif command -v konsole >/dev/null 2>&1; then
        TERMINAL_CMD="konsole -e"
    else
        echo -e "${RED}Error: No suitable terminal emulator found!${NC}"
        echo -e "${YELLOW}Please install gnome-terminal, xterm, or konsole${NC}"
        echo -e "${YELLOW}Or run OpenOCD and GDB manually in separate terminals:${NC}"
        echo -e "${YELLOW}Terminal 1: $0 --openocd${NC}"
        echo -e "${YELLOW}Terminal 2: $0 --gdb${NC}"
        exit 1
    fi
    
    # 启动OpenOCD在新终端（使用cmake目标）
    $TERMINAL_CMD bash -c "cd $(pwd); echo 'Starting OpenOCD server using cmake target...'; cmake --build $BUILD_DIR --target openocd; read -p 'Press Enter to close...'" &
    
    # 等待OpenOCD启动
    echo -e "${YELLOW}Waiting for OpenOCD to start...${NC}"
    sleep 3
    
    # 启动GDB在新终端（使用cmake目标）
    $TERMINAL_CMD bash -c "cd $(pwd); echo 'Starting GDB debug session using cmake target...'; cmake --build $BUILD_DIR --target debug; read -p 'Press Enter to close...'" &
    
    echo -e "${GREEN}OpenOCD and GDB started in separate terminals using cmake targets${NC}"
}

# 解析命令行参数
CLEAN=0
DEBUG=0
FLASH=0
SIZE=0
DISASM=0
COMPILE_CMDS=0
START_OPENOCD=0
START_GDB=0
DEBUG_ALL=0

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
        --openocd)
            START_OPENOCD=1
            shift
            ;;
        --gdb)
            START_GDB=1
            shift
            ;;
        --debug-all)
            DEBUG_ALL=1
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

# 如果只是启动OpenOCD或GDB，确保项目已构建
if [[ $START_OPENOCD -eq 1 ]] || [[ $START_GDB -eq 1 ]] || [[ $DEBUG_ALL -eq 1 ]]; then
    if [[ ! -d "$BUILD_DIR" ]]; then
        echo -e "${YELLOW}Build directory not found. Building project first...${NC}"
        mkdir -p "$BUILD_DIR"
        cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="Debug"
        cmake --build "$BUILD_DIR" -j$(nproc)
    fi
fi

# 启动OpenOCD
if [[ $START_OPENOCD -eq 1 ]]; then
    start_openocd
    exit 0
fi

# 启动GDB
if [[ $START_GDB -eq 1 ]]; then
    start_gdb
    exit 0
fi

# 启动调试环境
if [[ $DEBUG_ALL -eq 1 ]]; then
    start_debug_all
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
