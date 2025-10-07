all: flake8 mypy test

# W503 and W504 are both enabled by default and are mutual
# contradictory, so we have to suppress one of them.
# E501 uses 79 columns by default, but 80 is the default line wrap in
# vim, so change the line-length.
flake8:
	python3 -m flake8 . \
		--ignore W503 \
		--max-line-length=80 \
		--show-source \
		--statistics \
		--count

mypy:
	python3 -m mypy --strict .

test:
	python3 -m unittest

menusample.asm: menusample.txt compilemenu.py
	./compilemenu.py --debug -o $@ $<

unitsample.asm: unitsample.txt compileunit.py
	./compileunit.py --debug -o $@ $<
