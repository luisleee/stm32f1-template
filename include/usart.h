#pragma once
#include <stdint.h>
void usart_setup(uint32_t baudrate);
void send_str(const char *s);