# Create an `rpn83p.zip` file suitable for uploading to webarchives (e.g.
# cemetech.net, or ticalc.org). This Makefile pipeline contains the following
# steps:
#
# 1) Resize the PNG and GIF files to 75% using ImageMagick
# (https://legacy.imagemagick.org/Usage/resize/) because pandoc seems to insert
# the images which are 33% larger than the images in the HTML produced by
# GitHub's markdown processor. (I tried using `pandoc --dpi=` flag to fix the
# image sizing problem, but it did nothing.)
#
# GitHub-flavored Markdown does NOT support the `width` and `height` sizing
# attributes, so we have to continue to use the PNG and GIF files using 192x128
# pixels for appropriate sizing in the web browser.
#
# 2) Use a `sed(1)` script to rewrite the URI references embedded in the GFM
# files to point to the resized PNG and GIF images, instead of the original
# images.
#
# 3) Convert GitHub-flavored markdown (GFM) files to PDF. Requires pandoc and
# pdflatex. Here are the stackoverflow articles that helped me figure out how
# to do this using pandoc:
#
#	- https://stackoverflow.com/questions/9998337 (pandoc)
#	- https://stackoverflow.com/questions/29240290 (pdflatex not found)
#	- https://stackoverflow.com/questions/13515893 (margin size)
#	- https://stackoverflow.com/questions/23811002 (fontsize)
#	- https://superuser.com/questions/1732392 (colored hyperlinks)
#	- https://stackoverflow.com/questions/18178084 (Greek letters)
#	- https://linuxconfig.org/how-to-install-latex-on-ubuntu-22-04-jammy-jellyfish-linux
#	(installing xelatex on Ubuntu, $ sudo apt install texlive-xetex)
#	- https://stackoverflow.com/questions/18178084 (fc-list command)
#	- https://tex.stackexchange.com/questions/234786 (change font family)
#	- https://superuser.com/questions/1517900 (--monofont flag)
#
# I use `--from gfm` instead of `--from markdown` to handle embedded images
# better. The `--from markdown` option separates out the images into separate
# "Figures" which are out-of-context from the text. The `--from gfm` option
# embeds the images directly into the flow of the text.
#
# Use `$fc-list | grep -v pfb` to do a first cut filtering of fonts which don't
# seem to be supported by xelatex.
#
# 4) Copy the animated gif screenshot files from ../docs to here.
#
# 5) Copy the actual rpn83p.8xk file from ../src to here.
#
# 6) Zip-up all the files into an `rpn83p.zip` file.

TARGETS := \
CHANGELOG.md \
FUTURE.pdf \
README.pdf \
TVM.pdf \
USER_GUIDE.pdf \
USER_GUIDE_BASE.pdf \
USER_GUIDE_COMPLEX.pdf \
USER_GUIDE_DATE.pdf \
USER_GUIDE_STAT.pdf \
USER_GUIDE_TVM.pdf \
rpn83p-example1.gif \
rpn83p-example2.gif \
rpn83p-example3.gif \
rpn83p-example4.gif \
rpn83p.8xk

ORIG_IMAGES := \
$(wildcard ../docs/images/*.png) \
$(wildcard ../docs/images/*.gif) \
$(wildcard ../docs/images/base/*.png) \
$(wildcard ../docs/images/complex/*.png) \
$(wildcard ../docs/images/date/*.png) \
$(wildcard ../docs/images/stat/*.png) \
$(wildcard ../docs/images/tvm/*.png)

# Resized images are used for PDF files.
RESIZED_IMAGES := \
$(subst images/,resized/,$(ORIG_IMAGES))

# The default font used by xelatex seems to be "Latin Modern". Unfortunately,
# it does not support the Unicode angle character U+2220, producing a warning
# message: "Missing character: There is no ∠ (U+2220) (U+2220) in font
# [lmmono12-regular]".
#
# I tested various fonts which were installed on my Linux Mint 21.1 system.
# Some font families (e.g. "Nimbus Roman") supports the U+2220 (angle) symbol
# in the regular font, but not the mono font. Eventually, I discovered that the
# "FreeSerif" and the "FreeMono" fonts support U+2220 in both proportional and
# monospaced fonts.
#
# Proportional fonts tried:
#	- "FreeSans" - supports U+2220, but looks ugly w/o serif
#	- "FreeSerif" - supports U+2220
#	- "Latin Modern Roman" - no U+2220 angle
#	- "LiberationSerif" - no U+2220
#	- "Nimbus Roman" - supports U+2220
#	- "Ubuntu" - no U+2220
#
# Mono fonts tried:
#	- "Courier" - triggers font errors in xelatex
#	- "FreeMono" - supports U+2220 angle character (!)
#	- "Latin Modern Mono" (default) - no U+2220 angle
#	- "Liberation Mono" - no U+2220 angle
#	- "Nimbus Mono L" - triggers font errors in xelatex
#	- "Nimbus Mono PS" - triggers font errors in xelatex
#	- "Ubuntu Mono" - no U+2220 angle
PANDOC_FLAGS := \
--pdf-engine=xelatex \
--variable mainfont='FreeSerif' \
--variable monofont='FreeMono' \
--variable geometry:margin=1in \
--variable fontsize=12pt \
--variable colorlinks=true \
--from gfm \
--to pdf \
--standalone

# Name of the ImageMagick binary. My Linux Mint 21.1 (aka Ubuntu 20.04)
# installation comes with ImageMagick 6 (https://legacy.imagemagick.org). It
# supports many different resizing techniques and I tested a number of them
# (-scale, -resize, -sample, -magnify, -adaptive-resize,
# -interpolative-resize). The best seems to be -adaptive-resize for my
# use-case.
MAGICK := convert

# Create a zip file suitable for third party archives, like cemetech.net and
# ticalc.org.
rpn83p.zip: $(TARGETS)
	rm -f $@
	zip -r $@ $^

#-----------------------------------------------------------------------------

# Convert markdown to PDF.
README.pdf: ../README.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(docs/images/:(docs/resized/:g' < $< \
		| (cd ..; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE.pdf: ../docs/USER_GUIDE.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE_BASE.pdf: ../docs/USER_GUIDE_BASE.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE_COMPLEX.pdf: ../docs/USER_GUIDE_COMPLEX.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE_DATE.pdf: ../docs/USER_GUIDE_DATE.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE_STAT.pdf: ../docs/USER_GUIDE_STAT.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
USER_GUIDE_TVM.pdf: ../docs/USER_GUIDE_TVM.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images/:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
TVM.pdf: ../docs/DEVELOPER_TVM.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Convert markdown to PDF.
FUTURE.pdf: ../docs/FUTURE.md Makefile $(RESIZED_IMAGES)
	sed -e 's:(images:(resized/:g' < $< \
		| (cd ../docs; pandoc $(PANDOC_FLAGS)) > $@

# Copy the CHANGELOG.md as is, without conversion to PDF. It's just a text
# file without any embedded images.
CHANGELOG.md: ../CHANGELOG.md Makefile
	cp -f $< $@

#-----------------------------------------------------------------------------

# Resize the PNG files under images/ to 75% before embedding into PDF.
../docs/resized/%.png: ../docs/images/%.png
	@mkdir -p ../docs/resized
	$(MAGICK) $< -adaptive-resize 75% $@

# Resize the PNG files under images/date/ to 75% before embedding into PDF.
../docs/resized/base/%.png: ../docs/images/base/%.png
	@mkdir -p ../docs/resized/base
	$(MAGICK) $< -adaptive-resize 75% $@

# Resize the PNG files under images/complex/ to 75% before embedding into PDF.
../docs/resized/complex/%.png: ../docs/images/complex/%.png
	@mkdir -p ../docs/resized/complex
	$(MAGICK) $< -adaptive-resize 75% $@

# Resize the PNG files under images/date/ to 75% before embedding into PDF.
../docs/resized/date/%.png: ../docs/images/date/%.png
	@mkdir -p ../docs/resized/date
	$(MAGICK) $< -adaptive-resize 75% $@

# Resize the PNG files under images/stat/ to 75% before embedding into PDF.
../docs/resized/stat/%.png: ../docs/images/stat/%.png
	@mkdir -p ../docs/resized/stat
	$(MAGICK) $< -adaptive-resize 75% $@

# Resize the PNG files under images/tvm/ to 75% before embedding into PDF.
../docs/resized/tvm/%.png: ../docs/images/tvm/%.png
	@mkdir -p ../docs/resized/tvm
	$(MAGICK) $< -adaptive-resize 75% $@

# Just copy the GIF files, no resizing. They take too much CPU time to resize.
# They are only used in the README.md, with only one per line, so even if they
# are 33% too large, it's ok.
../docs/resized/%.gif: ../docs/images/%.gif
	@mkdir -p ../docs/resized
	cp -f $< $@

#-----------------------------------------------------------------------------

# Copy to local directory to place it at top level in the zip file.
rpn83p.8xk: ../src/rpn83p.8xk
	cp -f $< $@

# Compile the binary if needed.
../src/rpn83p.8xk: ../src/*.asm
	$(MAKE) -C ../src rpn83p.8xk

# Copy the animated GIF as a sample screenshot.
rpn83p-example1.gif: ../docs/images/rpn83p-example1.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example2.gif: ../docs/images/rpn83p-example2.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example3.gif: ../docs/images/rpn83p-example3.gif
	cp -f $< $@

# Copy the animated GIF as a sample screenshot.
rpn83p-example4.gif: ../docs/images/rpn83p-example4.gif
	cp -f $< $@

clean:
	rm -rf $(TARGETS) ../docs/resized
