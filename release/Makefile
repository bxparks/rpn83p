# Create a rpn83p.zip file suitable for uploading to webarchives (e.g.
# cemetech.net, or ticalc.org). The zip file contains the following:
#
# 1) README.pdf, USER_GUIDE.pdf, and TVM.pdf are converted from the original
# GitHub-flavored Markdown files README.md, USER_GUIDE.md and TVM.md. Requires
# pandoc and pdflatex. Here are the stackoverflow articles that helped me solve
# this problem:
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
#
# 2) Copy the animated gif screenshot files from ../docs.
#
# 3) Copy the actual rpn83p.8xk file from ../src.

TARGETS := README.pdf \
USER_GUIDE.pdf \
TVM.pdf \
CHANGELOG.md \
rpn83p.8xk \
rpn83p-example1.gif \
rpn83p-example2.gif \
rpn83p-example3.gif

# Create a zip file suitable for third party archives, like cemetech.net and
# ticalc.org.
rpn83p.zip: $(TARGETS)
	rm -f $@
	zip -r $@ $^

# Convert markdown to PDF.
README.pdf: ../README.md Makefile
	(cd ..; \
	pandoc -V geometry:margin=1in -V fontsize=12pt -f gfm -s -o $@ README.md; \
	mv -f $@ release)

# Convert markdown to PDF.
USER_GUIDE.pdf: ../USER_GUIDE.md Makefile
	(cd ..; \
	pandoc -V geometry:margin=1in -V fontsize=12pt -f gfm -s -o $@ USER_GUIDE.md; \
	mv -f $@ release)

# Convert markdown to PDF.
TVM.pdf: ../TVM.md Makefile
	(cd ..; \
	pandoc -V geometry:margin=1in -V fontsize=12pt -f gfm -s -o $@ TVM.md; \
	mv -f $@ release)

# Copy the CHANGELOG.md as is, without conversion to PDF. It's just a text
# file without any embedded images.
CHANGELOG.md: ../CHANGELOG.md Makefile
	cp -f $< $@

# Copy to local directory to place it at top level in the zip file.
rpn83p.8xk: ../src/rpn83p.8xk
	cp -f $< $@

# Compile the binary if needed.
../src/rpn83p.8xk: ../src/*.asm
	$(MAKE) -C ../src rpn83p.8xk

# Copy the animated GIF as a sample screenshot.
rpn83p-example1.gif: ../docs/rpn83p-example1.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example2.gif: ../docs/rpn83p-example2.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example3.gif: ../docs/rpn83p-example3.gif
	cp -f $< $@

clean:
	rm -f $(TARGETS)
