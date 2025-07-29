#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <stdio.h>
#include "usart.h"

int main(void) {
    rcc_clock_setup_pll(&rcc_hse_configs[RCC_CLOCK_HSE8_72MHZ]);
    usart_setup(115200);
    
    while (1) {
        printf("Hello World! %d %.6f\r\n", 42, 114.514);
        for (int i = 0; i < 800000; i++) __asm__("nop");
    }
}