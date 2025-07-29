# STM32F1 Template

This is a template project for stm32f1 development.

## Requirements

- arm-none-eabi-gcc
- arm-none-eabi-binutils
- cmake
- make
- stlink
- openocd

## How to

### build
 1. `git clone --recurse-submodules https://github.com/luisleee/stm32f1-template.git my-project`
 1. `cd my-project`
 1. `./build.sh`

### flash
`./build.sh -f`

### clean
`./build.sh -c`

## LSP (clangd) support
Use `./build.sh --compile-cmds`