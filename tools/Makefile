# W503 and W504 are both enabled by default and are mutual
# contradictory, so we have to suppress one of them.
# E501 uses 79 columns by default, but 80 is the default line wrap in
# vim, so change the line-length.
flake8:
	flake8 . \
		--ignore W503 \
		--max-line-length=80 \
		--show-source \
		--statistics \
		--count

mypy:
	mypy --strict .

test:
	python3 -m unittest
