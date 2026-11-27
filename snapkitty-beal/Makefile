# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
XSLTPROC ?= xsltproc
AGDA ?= agda

.PHONY: transform render agda-check c-check clean

transform:
	mkdir -p build
	$(XSLTPROC) -o build/obligations.xml xslt/theorem-to-obligations.xsl spec/beal.xml
	cat build/obligations.xml

# Render every obligation through templates/obligation.mustache
# (the source of truth for the node format) into build/rendered/<id>.xml.
# Builds the Mustache renderer first (strict C11, zero warnings).
render: transform dag/render
	bash dag/render_all.sh .

dag/render: dag/render.c
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -o $@ $<

agda-check:
	$(AGDA) -i agda agda/Beal.agda
	$(AGDA) -i agda agda/BealReduction.agda

c-check:
	$(CC) -std=c11 -Wall -Wextra -Werror -c hardware/beal_ref.c -o /tmp/beal_ref.o

clean:
	rm -rf build dag/render
