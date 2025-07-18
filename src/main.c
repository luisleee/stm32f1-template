#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>
#define LITTLE_BIT 200000

int main(void) {
  rcc_periph_clock_enable(RCC_GPIOC);
  gpio_set_mode(GPIOC, GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL,
                GPIO13);

  gpio_set(GPIOC, GPIO13);
  while (1) {
    /* wait a little bit */
    for (int i = 0; i < LITTLE_BIT; i++) {
      __asm__("nop");
    }
    gpio_toggle(GPIOC, GPIO13);
  }
}