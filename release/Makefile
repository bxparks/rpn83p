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
#	- https://superuser.com/questions/ (--top-level-divsion)
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

# List of files to be added to the rpn83p.zip file.
TARGETS := \
CHANGELOG.md \
README.pdf \
USER_GUIDE.pdf \
rpn83p-example1.gif \
rpn83p-example2.gif \
rpn83p-example3.gif \
rpn83p-example4.gif \
rpn83p.8xk \
rpn83p.zip

# Dependent files of USER_GUIDE.pdf, listed in order of Chapters.
USER_GUIDE_SRCS := \
../docs/USER_GUIDE.md \
../docs/USER_GUIDE_WHY.md \
../docs/USER_GUIDE_INSTALLATION.md \
../docs/USER_GUIDE_BASIC.md \
../docs/USER_GUIDE_FUNCTIONS.md \
../docs/USER_GUIDE_STORAGE.md \
../docs/USER_GUIDE_MODE.md \
../docs/USER_GUIDE_NUM.md \
../docs/USER_GUIDE_BASE.md \
../docs/USER_GUIDE_STAT.md \
../docs/USER_GUIDE_TVM.md \
../docs/USER_GUIDE_COMPLEX.md \
../docs/USER_GUIDE_UNIT.md \
../docs/USER_GUIDE_DATE.md \
../docs/USER_GUIDE_TIOS.md \
../docs/USER_GUIDE_TROUBLESHOOTING.md \
../docs/USER_GUIDE_FUTURE.md

# List of MD files which go into USER_GUIDE.pdf, in order of Chapters.
USER_GUIDE_CHAPTERS := $(subst ../docs/,,$(USER_GUIDE_SRCS))

# List of MD files which go into USER_GUIDE.pdf, in order of Chapters.
USER_GUIDE_CHAPTERS_FILES := $(subst ../docs/,docs/,$(USER_GUIDE_SRCS))

# List of screenshots that need to be resized because pandoc and GitHub seem to
# disagree how big they should be in the document. Pandoc is 33% too big. The
# only solution that I could find was to reduc the PNG sizes by 33%, before
# converting the MD files into PDF.
ORIG_IMAGES := \
$(wildcard ../docs/images/readme/*.gif) \
$(wildcard ../docs/images/base/*.png) \
$(wildcard ../docs/images/basic/*.png) \
$(wildcard ../docs/images/complex/*.png) \
$(wildcard ../docs/images/date/*.png) \
$(wildcard ../docs/images/date/clk/*.png) \
$(wildcard ../docs/images/date/d/*.png) \
$(wildcard ../docs/images/date/dr/*.png) \
$(wildcard ../docs/images/date/dt/*.png) \
$(wildcard ../docs/images/date/dw/*.png) \
$(wildcard ../docs/images/date/dz/*.png) \
$(wildcard ../docs/images/date/epch/*.png) \
$(wildcard ../docs/images/date/regs/*.png) \
$(wildcard ../docs/images/date/t/*.png) \
$(wildcard ../docs/images/date/tz/*.png) \
$(wildcard ../docs/images/fullshot/*.png) \
$(wildcard ../docs/images/installation/*.png) \
$(wildcard ../docs/images/menu/*.png) \
$(wildcard ../docs/images/mode/*.png) \
$(wildcard ../docs/images/num/*.png) \
$(wildcard ../docs/images/stat/*.png) \
$(wildcard ../docs/images/storage/*.png) \
$(wildcard ../docs/images/tvm/*.png) \
$(wildcard ../docs/images/unit/*.png)

# Resized images are used for PDF files.
RESIZED_IMAGES := $(subst ../docs/,docs/,$(ORIG_IMAGES))

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

#-----------------------------------------------------------------------------
# Build the final ZIP file artifact.
#-----------------------------------------------------------------------------

# Create a zip file suitable for third party archives, like cemetech.net and
# ticalc.org.
rpn83p.zip: $(TARGETS)
	rm -f $@
	zip -r $@ $^

#-----------------------------------------------------------------------------
# Build the PDF files using pandoc.
#-----------------------------------------------------------------------------

# Convert the top-level README.md to markdown to PDF. (Not to be confused with
# the release/README.md file in this directory.)
README.pdf: ../README.md Makefile $(RESIZED_IMAGES)
	pandoc ../README.md $(PANDOC_FLAGS) > $@

# Convert multiple USER_GUIDE*.md to a single PDF.
# Resources:
# - concatenate multiple MD files into pandoc:
#	https://stackoverflow.com/questions/14899283/
# - pandocfilters to fix intra-document links
#   https://stackoverflow.com/questions/41139830
USER_GUIDE.pdf: $(USER_GUIDE_CHAPTERS_FILES) Makefile $(RESIZED_IMAGES)
	(\
	cd docs; \
	pandoc $(USER_GUIDE_CHAPTERS) \
		$(PANDOC_FLAGS) \
		--toc \
		--top-level-division=chapter \
	) > $@

# Copy the CHANGELOG.md as is, without conversion to PDF. It's just a text
# file without any embedded images.
CHANGELOG.md: ../CHANGELOG.md Makefile
	cp -f $< $@

#-----------------------------------------------------------------------------
# Resize the PNG files under ../docs/images and place them under ./docs/images
# They need to be resized to 75% before embedding into PDF because pandoc
# inserts images which are 33% larger than GitHub.
#-----------------------------------------------------------------------------

docs/images/%.png: ../docs/images/%.png
	@mkdir -p docs/images
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/base/%.png: ../docs/images/base/%.png
	@mkdir -p docs/images/base
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/basic/%.png: ../docs/images/basic/%.png
	@mkdir -p docs/images/basic
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/complex/%.png: ../docs/images/complex/%.png
	@mkdir -p docs/images/complex
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/%.png: ../docs/images/date/%.png
	@mkdir -p docs/images/date
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/clk/%.png: ../docs/images/date/clk/%.png
	@mkdir -p docs/images/date/clk
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/d/%.png: ../docs/images/date/d/%.png
	@mkdir -p docs/images/date/d
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/dr/%.png: ../docs/images/date/dr/%.png
	@mkdir -p docs/images/date/dr
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/dt/%.png: ../docs/images/date/dt/%.png
	@mkdir -p docs/images/date/dt
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/dw/%.png: ../docs/images/date/dw/%.png
	@mkdir -p docs/images/date/dw
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/dz/%.png: ../docs/images/date/dz/%.png
	@mkdir -p docs/images/date/dz
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/epch/%.png: ../docs/images/date/epch/%.png
	@mkdir -p docs/images/date/epch
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/regs/%.png: ../docs/images/date/regs/%.png
	@mkdir -p docs/images/date/regs
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/t/%.png: ../docs/images/date/t/%.png
	@mkdir -p docs/images/date/t
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/date/tz/%.png: ../docs/images/date/tz/%.png
	@mkdir -p docs/images/date/tz
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/fullshot/%.png: ../docs/images/fullshot/%.png
	@mkdir -p docs/images/fullshot
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/installation/%.png: ../docs/images/installation/%.png
	@mkdir -p docs/images/installation
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/menu/%.png: ../docs/images/menu/%.png
	@mkdir -p docs/images/menu
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/mode/%.png: ../docs/images/mode/%.png
	@mkdir -p docs/images/mode
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/num/%.png: ../docs/images/num/%.png
	@mkdir -p docs/images/num
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/stat/%.png: ../docs/images/stat/%.png
	@mkdir -p docs/images/stat
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/storage/%.png: ../docs/images/storage/%.png
	@mkdir -p docs/images/storage
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/tvm/%.png: ../docs/images/tvm/%.png
	@mkdir -p docs/images/tvm
	$(MAGICK) $< -adaptive-resize 75% $@

docs/images/unit/%.png: ../docs/images/unit/%.png
	@mkdir -p docs/images/unit
	$(MAGICK) $< -adaptive-resize 75% $@

# Just copy the GIF files, no resizing. They take too much CPU time to resize.
# They are only used in the README.md, with only one per line, so even if they
# are 33% too large, it's ok.
docs/images/readme/%.gif: ../docs/images/readme/%.gif
	@mkdir -p docs/images/readme
	cp -f $< $@

#-----------------------------------------------------------------------------
# Copy the MD files to ./docs from ../docs, with some processing:
# - remove redundant TOC in the main USER_GUIDE.md
# - remove link to "Parent Document: USER_GUIDE.md" since everything is
# processed into a single PDF file
# - remove the dangling backslash on the previous line, after "Parent Document"
# line is removed
#-----------------------------------------------------------------------------

# Remove redudant TOC from the temporary MD file, pandoc generates its own.
docs/USER_GUIDE.md: ../docs/USER_GUIDE.md Makefile
	@mkdir -p docs
	sed -e '/## Chapters/,$$d' \
		< $< > $@

docs/USER_GUIDE_WHY.md: ../docs/USER_GUIDE_WHY.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_INSTALLATION.md: ../docs/USER_GUIDE_INSTALLATION.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_BASIC.md: ../docs/USER_GUIDE_BASIC.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_FUNCTIONS.md: ../docs/USER_GUIDE_FUNCTIONS.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_STORAGE.md: ../docs/USER_GUIDE_STORAGE.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_MODE.md: ../docs/USER_GUIDE_MODE.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_NUM.md: ../docs/USER_GUIDE_NUM.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_BASE.md: ../docs/USER_GUIDE_BASE.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_STAT.md: ../docs/USER_GUIDE_STAT.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_TVM.md: ../docs/USER_GUIDE_TVM.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_COMPLEX.md: ../docs/USER_GUIDE_COMPLEX.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_UNIT.md: ../docs/USER_GUIDE_UNIT.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_DATE.md: ../docs/USER_GUIDE_DATE.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_TIOS.md: ../docs/USER_GUIDE_TIOS.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_TROUBLESHOOTING.md: ../docs/USER_GUIDE_TROUBLESHOOTING.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

docs/USER_GUIDE_FUTURE.md: ../docs/USER_GUIDE_FUTURE.md Makefile
	@mkdir -p docs
	sed -e '/^\*\*Parent Document/d' \
		-e '/^\*\*Project Home/s/\\$$//' \
		< $< > $@

# README.md requires some URL rewriting.
README.md: ../README.md Makefile
	sed -e 's:(docs/images/:(images/:g' < $< > $@

#-----------------------------------------------------------------------------
# Build and copy the binary.
#-----------------------------------------------------------------------------

# Copy to local directory to place it at top level in the zip file.
rpn83p.8xk: ../src/rpn83p.8xk
	cp -f $< $@

# Compile the binary if needed.
../src/rpn83p.8xk: ../src/*.asm
	$(MAKE) -C ../src rpn83p.8xk

#-----------------------------------------------------------------------------
# Copy the animated GIFs to top level for inclusion in the ZIP file. Used
# during archiving to cemetech.net, so I include them in the ZIP file for
# completeness.
#-----------------------------------------------------------------------------

rpn83p-example1.gif: ../docs/images/readme/rpn83p-example1.gif
	cp -f $< $@

rpn83p-example2.gif: ../docs/images/readme/rpn83p-example2.gif
	cp -f $< $@

rpn83p-example3.gif: ../docs/images/readme/rpn83p-example3.gif
	cp -f $< $@

rpn83p-example4.gif: ../docs/images/readme/rpn83p-example4.gif
	cp -f $< $@

#-----------------------------------------------------------------------------

clean:
	rm -rf $(TARGETS) docs
