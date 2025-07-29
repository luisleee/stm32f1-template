#include "usart.h"
#include <libopencm3/stm32/usart.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>

void usart_setup(uint32_t baudrate) {
    // Enable clocks for USART1 and GPIOA
    rcc_periph_clock_enable(RCC_USART1);
    rcc_periph_clock_enable(RCC_GPIOA);
    
    // Configure TX pin (PA9) as alternate function push-pull
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, 
                 GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO_USART1_TX);
    
    // Configure RX pin (PA10) as input floating
    gpio_set_mode(GPIOA, GPIO_MODE_INPUT,
                 GPIO_CNF_INPUT_FLOAT, GPIO_USART1_RX);
    
    // USART configuration
    usart_set_baudrate(USART1, baudrate);
    usart_set_databits(USART1, 8);
    usart_set_stopbits(USART1, USART_STOPBITS_1);
    usart_set_parity(USART1, USART_PARITY_NONE);
    usart_set_flow_control(USART1, USART_FLOWCONTROL_NONE);
    
    // Enable both TX and RX modes
    usart_set_mode(USART1, USART_MODE_TX_RX);
    
    usart_enable(USART1);
}

void send_str(const char *s) {
    while (*s) {
        usart_send_blocking(USART1, *s++);
    }
}