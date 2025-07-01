PREFIX?=arm-none-eabi-
CC=$(PREFIX)gcc
OBJCOPY=$(PREFIX)objcopy
OD=build

SFLAGS= --static -nostartfiles -std=c11 -g3 -Os
SFLAGS+= -fno-common -ffunction-sections -fdata-sections
SFLAGS+= -I./libopencm3/include -L./libopencm3/lib

LFLAGS+=-Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

# Change this part if it's not cortex-m3
M3_FLAGS= $(SFLAGS) -mcpu=cortex-m3 -mthumb -msoft-float
LFLAGS_STM32=$(LFLAGS) src/main.c -T src/ld.stm32.basic

# Change this part if it's not stm32f1
STM32F1_CFLAGS=$(M3_FLAGS) -DSTM32F1 $(LFLAGS_STM32) -lopencm3_stm32f1

PROJECT_NAME=template

all: outdir $(OD)/$(PROJECT_NAME).elf $(OD)/$(PROJECT_NAME).hex $(OD)/$(PROJECT_NAME).bin

$(OD)/$(PROJECT_NAME).elf: src/main.c
	$(CC) $(STM32F1_CFLAGS) -o $(OD)/$(PROJECT_NAME).elf

libopencm3/Makefile:
	@echo "Initializing libopencm3 submodule"
	git submodule update --init

libopencm3/lib/libopencm3_%.a: libopencm3/Makefile
	$(MAKE) -C libopencm3

%.bin: %.elf
	@#printf "  OBJCOPY $(*).bin\n"
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.hex: %.elf
	@#printf "  OBJCOPY $(*).hex\n"
	$(OBJCOPY) -Oihex $(*).elf $(*).hex

clean:
	$(RM) -r $(OD)

outdir:
	mkdir $(OD)

flash:
	st-flash write $(OD)/$(PROJECT_NAME).bin 0x8000000

.PHONY: clean all
$(V).SILENT:
