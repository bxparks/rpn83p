TARGETS := rpn83p.8xp rpn83p.lst

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := \
	common.asm \
	debug.asm \
	display.asm \
	errorcode.asm \
	handlers.asm \
	handlertab.asm \
	menu.asm \
	menudevdef.asm \
	menuhandlers.asm \
	parsenum.asm \
	pstring.asm \
	rpn83p.asm \
	vars.asm

rpn83p.8xp: $(SRCS)
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

rpn83p.lst: $(SRCS)
	$(SPASM) -I $(SPASM_INC) -N -T rpn83p.asm rpn83p.8xp

menudevdef.asm: menudevdef.txt ../tools/compilemenu.py
	../tools/compilemenu.py -o $@ $<

clean:
	rm -f $(TARGETS)
