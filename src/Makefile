TARGETS := rpn83p.8xp

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := \
	debug.asm \
	display.asm \
	errorcode.asm \
	handlers.asm \
	handlertab.asm \
	parsenum.asm \
	pstring.asm \
	rpn83p.asm \
	vars.asm

rpn83p.8xp: $(SRCS)
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

clean:
	rm -f $(TARGETS)
