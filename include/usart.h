#pragma once
#include <stdint.h>
void usart_setup(uint32_t baudrate);
int _write(int fd, char *ptr, int len);
