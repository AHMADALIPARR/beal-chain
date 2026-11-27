# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
XSLTPROC ?= xsltproc
AGDA ?= agda
BSC ?= $(HOME)/workspace/.tools/bsc/bsc-2026.07.1-debian-12.15/bin/bsc

.PHONY: transform render agda-check c-check c-test ats-check bsv-check asp-check clean

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
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -c hardware/beal_ref.c -o /tmp/beal_ref.o

# Build and run the bounded Beal-instance edge-case tests (23 checks).
c-test:
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -Ihardware \
		examples/beal_instance_test.c hardware/beal_ref.c \
		-o /tmp/beal_instance_test
	/tmp/beal_instance_test

# Build and run the ATS2 contract program against the C reference.
# patscc leaves an intermediate beal_contract_dats.c beside the source;
# it is removed here so it never lands in the tree.
ats-check:
	patscc -Ihardware -o /tmp/beal_ats \
		ats/beal_contract.dats hardware/beal_ref.c
	/tmp/beal_ats
	rm -f beal_contract_dats.c

# Compile the Bluespec kernel to Verilog (zero warnings).
bsv-check:
	mkdir -p /tmp/bsv_out
	$(BSC) -u -verilog -vdir /tmp/bsv_out -bdir /tmp/bsv_out \
		-info-dir /tmp/bsv_out -g mkBealArithmetic \
		hardware/BealArithmetic.bsv

# Generate ASP facts from the obligations and solve the dependency rules.
# clingo exits 10 or 30 when a model is found (satisfiable); 20 means
# unsatisfiable (a constraint is violated) and any other code is an error.
asp-check: transform
	bash asp/facts.sh build/obligations.xml build/facts.lp
	clingo asp/dependencies.lp build/facts.lp; rc=$$?; case $$rc in 10|30) exit 0;; *) exit $$rc;; esac

clean:
	rm -rf build dag/render
