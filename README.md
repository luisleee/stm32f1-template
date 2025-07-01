# STM32F1 Template

This is a template project for stm32f1 development.

## Requirements

- arm-none-eabi-gcc
- arm-none-eabi-binutils
- stlink

## How to

### build
 1. `git clone --recurse-submodules https://github.com/luisleee/stm32f1-template.git my-project`
 1. `cd my-project`
 1. `cd libopencm3`
 1. `make`
 1. `cd ..`
 1. `make`

### flash
`make flash`

## LSP (clangd) support
Use `bear -- make`