# Convert GitHub-flavored Markdown to PDF, including embedded images.
#
# Requires pandoc and pdflatex.
# See:
#	- https://stackoverflow.com/questions/9998337
#	- https://stackoverflow.com/questions/13515893
#	- https://stackoverflow.com/questions/29240290
#
# Use '-f gfm' instead of '-f markdown' to handler embedded images better. The
# `-f mardown` option separates out the images into separate Figures which are
# out of context from the text. The `-f gfm` embeds the images directly into
# the flow of the text.

# Create a zip file suitable for third party archives, like cemetech.net and
# ticalc.org.
rpn83p.zip: README.pdf USER_GUIDE.pdf rpn83p.8xk
	rm -f $@
	zip -r $@ $^

# Convert markdown to PDF.
README.pdf: README.md Makefile
	pandoc -V geometry:margin=1in -f gfm -s -o $@ $<

# Convert markdown to PDF.
USER_GUIDE.pdf: USER_GUIDE.md Makefile
	pandoc -V geometry:margin=1in -f gfm -s -o $@ $<

# Copy to local directory to place it at top level in the zip file.
rpn83p.8xk: src/rpn83p.8xk
	cp -f $< $@

# Compile the binary if needed.
src/rpn83p.8xk: src/*.asm
	$(MAKE) -C src rpn83p.8xk

clean:
	rm -f README.pdf USER_GUIDE.pdf rpn83p.8xk
