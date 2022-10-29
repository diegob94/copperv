
SHELL = bash

COPPERV_RTL = 	rtl/copperv/copperv.v \
				rtl/copperv/control_unit.v \
				rtl/copperv/execution.v \
				rtl/copperv/idecoder.v \
				rtl/copperv/register_file.v

COPPERV_INCLUDES = rtl/include

TOP_RTL = 	$(COPPERV_RTL) \
			rtl/top.v \
			rtl/uart/wb2uart.v \
			rtl/memory/sram_1r1w.v \
			rtl/wishbone/wb_adapter.v \
			rtl/wishbone/wb_copperv.v \
			rtl/wishbone/wb_sram.v \
			external_ip/wb2axip/rtl/wbxbar.v \
			external_ip/wb2axip/rtl/skidbuffer.v \
			external_ip/wb2axip/rtl/addrdecode.v

APP_START_ADDR := 0x1000
BOOTLOADER_MAGIC_ADDR := $(APP_START_ADDR)-4
T_ADDR := $(APP_START_ADDR)-8
O_ADDR := $(APP_START_ADDR)-12
TC_ADDR := $(APP_START_ADDR)-16
T_PASS := 0x01000001
T_FAIL := 0x02000001

space := $(subst ,, )
comma := $(subst ,,,)
list2toml = $(addprefix $(1)=[\n,$(addsuffix \n]\n,$(subst $(space),$(comma)\n,$(patsubst %,"%",$($(1))))))
list2tcl = $(addprefix set $(1) {\n,$(addsuffix \n}\n,$(subst $(space),\n,$($(1)))))
var2toml = "$(shell printf '$(1) = 0x%X' $$(($($(1)))))\n"
var2cmacro = "$(shell printf '\#define $(1) 0x%X' $$(($($(1)))))\n"
var2vmacro = "$(shell printf "\\\`define $(1) 32'h%X" $$(($($(1)))))\n"

getvar-%:
	$(info $($*))
	@true

