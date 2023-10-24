TARGETS := rpn83p.8xk rpn83p.8xp rpn83p.lst

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := \
	base.asm \
	basehandlers.asm \
	cfithandlers.asm \
	common.asm \
	const.asm \
	crc.asm \
	debug.asm \
	display.asm \
	errorcode.asm \
	handlers.asm \
	handlertab.asm \
	input.asm \
	integer.asm \
	menu.asm \
	menudef.asm \
	menuhandlers.asm \
	prime.asm \
	print.asm \
	pstring.asm \
	rpn83p.asm \
	stathandlers.asm \
	vars.asm

# TI Flash app
rpn83p.8xk: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

# Debug version of assembly prpgram.
#rpn83p.8xp: $(SRCS) Makefile
#	$(SPASM) -DDEBUG -I $(SPASM_INC) -N rpn83p.asm $@

rpn83p.lst: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N -T rpn83p.asm rpn83p.8xp

menudef.asm: menudef.txt ../tools/compilemenu.py
	../tools/compilemenu.py -o $@ $<

clean:
	rm -f $(TARGETS)
