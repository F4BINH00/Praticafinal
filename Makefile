CROSS_COMPILE ?= arm-linux-gnueabihf-

SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin
	
src_files = startup.s uart.s utils.s wdt.s cp15.s gpio.s rtc.s

OBJS = $(addprefix $(OBJ_DIR)/, $(src_files:.s=.o))

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(OBJ_DIR)
	$(CROSS_COMPILE)as $< -o $@

all: $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(CROSS_COMPILE)ld -o $(BIN_DIR)/startup -T memmap $(OBJS)

	$(CROSS_COMPILE)objcopy $(BIN_DIR)/startup $(BIN_DIR)/startup.bin -O binary

	$(CROSS_COMPILE)objdump -DSx -b binary -marm $(BIN_DIR)/startup.bin > startup.lst
	sudo cp $(BIN_DIR)/startup.bin /tftpboot
	
clean:
	rm -rf $(OBJ_DIR)/*.o $(BIN_DIR)/* startup.lst
