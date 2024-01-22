TARGETS := rpn83p.8xk rpn83p.8xp rpn83p.lst

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := \
	appstate.asm \
	arg1.asm \
	arghandlers.asm \
	arghandlertab.asm \
	argparser.asm \
	base.asm \
	base1.asm \
	baseops.asm \
	basehandlers.asm \
	cfithandlers.asm \
	common.asm \
	complex.asm \
	complex1.asm \
	complexhandlers.asm \
	const.asm \
	const1.asm \
	conv.asm \
	crc.asm \
	debug.asm \
	display.asm \
	errorcode.asm \
	float.asm \
	float1.asm \
	fps1.asm \
	handlers.asm \
	handlertab.asm \
	help.asm \
	hms.asm \
	input.asm \
	input1.asm \
	integer1.asm \
	main.asm \
	mainparser.asm \
	memory.asm \
	memory1.asm \
	menu.asm \
	menudef.asm \
	menuhandlers.asm \
	menulookup.asm \
	osstate.asm \
	prime.asm \
	print.asm \
	print1.asm \
	prob.asm \
	pstring1.asm \
	rpn83p.asm \
	showparser.asm \
	show.asm \
	stathandlers.asm \
	tvmhandlers.asm \
	tvm.asm \
	vars.asm

# TI Flash app. Use -DDEBUG to activate functions in debug.asm.
rpn83p.8xk: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

# TI assembly program. No longer works because the program is > 8 kiB.
#rpn83p.8xp: $(SRCS) Makefile
#	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

rpn83p.lst: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N -T rpn83p.asm rpn83p.8xp

menudef.asm: menudef.txt ../tools/compilemenu.py
	../tools/compilemenu.py -o $@ $<

clean:
	rm -f $(TARGETS)
