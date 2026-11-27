# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
XSLTPROC ?= xsltproc
AGDA ?= agda

.PHONY: transform agda-check c-check clean

transform:
	mkdir -p build
	$(XSLTPROC) -o build/obligations.xml xslt/theorem-to-obligations.xsl spec/beal.xml
	cat build/obligations.xml

agda-check:
	$(AGDA) -i agda agda/Beal.agda
	$(AGDA) -i agda agda/BealReduction.agda

c-check:
	$(CC) -std=c11 -Wall -Wextra -Werror -c hardware/beal_ref.c -o /tmp/beal_ref.o

clean:
	rm -rf build
