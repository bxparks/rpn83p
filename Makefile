# Convert GitHub-flavored Markdown to PDF, including embedded images.
#
# Requires pandoc and pdflatex. Here are the stackoverflow articles that helped
# me solve this problem:
#
#	- https://stackoverflow.com/questions/9998337 (pandoc)
#	- https://stackoverflow.com/questions/29240290 (pdflatex not found)
#	- https://stackoverflow.com/questions/13515893 (margin size)
#	- https://stackoverflow.com/questions/23811002 (fontsize)
#
# I use '-f gfm' instead of '-f markdown' to handler embedded images better.
# The `-f mardown` option separates out the images into separate Figures which
# are out of context from the text. The `-f gfm` embeds the images directly
# into the flow of the text.

TARGETS := README.pdf \
USER_GUIDE.pdf \
rpn83p.8xk \
rpn83p-example1.gif \
rpn83p-example2.gif

# Create a zip file suitable for third party archives, like cemetech.net and
# ticalc.org.
rpn83p.zip: $(TARGETS)
	rm -f $@
	zip -r $@ $^

# Convert markdown to PDF.
README.pdf: README.md Makefile
	pandoc -V geometry:margin=1in -V fontsize=12pt -f gfm -s -o $@ $<

# Convert markdown to PDF.
USER_GUIDE.pdf: USER_GUIDE.md Makefile
	pandoc -V geometry:margin=1in -V fontsize=12pt -f gfm -s -o $@ $<

# Copy to local directory to place it at top level in the zip file.
rpn83p.8xk: src/rpn83p.8xk
	cp -f $< $@

# Compile the binary if needed.
src/rpn83p.8xk: src/*.asm
	$(MAKE) -C src rpn83p.8xk

# Copy the animated GIF as a sample screenshot.
rpn83p-example1.gif: docs/rpn83p-example1.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example2.gif: docs/rpn83p-example2.gif
	cp -f $< $@

clean:
	rm -f $(TARGETS)