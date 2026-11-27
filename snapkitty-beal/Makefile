# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
XSLTPROC ?= xsltproc
AGDA ?= agda
BSC ?= $(HOME)/workspace/.tools/bsc/bsc-2026.07.1-debian-12.15/bin/bsc

.PHONY: transform manifest render agda-check c-check c-test ats-check ats-pure-check bsv-check asp-check clean

transform:
	mkdir -p build
	$(XSLTPROC) -o build/obligations.xml xslt/theorem-to-obligations.xsl spec/beal.xml
	cat build/obligations.xml

# Deterministic manifest of the theorem and its open holes.
manifest: transform
	$(XSLTPROC) -o build/manifest.xml xslt/theorem-to-manifest.xsl spec/beal.xml
	cat build/manifest.xml

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
	$(AGDA) -i agda agda/SnapKitty/Prelude.agda
	$(AGDA) -i agda agda/SnapKitty/Beal.agda

c-check:
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -c hardware/beal_ref.c -o /tmp/beal_ref.o
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -Ihardware/c11 -c hardware/c11/beal_check.c -o /tmp/beal_check.o

# Build and run the bounded Beal-instance edge-case tests (23 checks).
c-test:
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -Ihardware \
		examples/beal_instance_test.c hardware/beal_ref.c \
		-o /tmp/beal_instance_test
	/tmp/beal_instance_test
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -Ihardware/c11 \
		examples/beal_check_u32_test.c hardware/c11/beal_check.c \
		-o /tmp/beal_check_u32_test
	/tmp/beal_check_u32_test

# Build and run the ATS2 contract program against the C reference.
# patscc leaves an intermediate beal_contract_dats.c beside the source;
# it is removed here so it never lands in the tree.
ats-check:
	patscc -Ihardware -o /tmp/beal_ats \
		ats/beal_contract.dats hardware/beal_ref.c
	/tmp/beal_ats
	rm -f beal_contract_dats.c

# Build and run the pure-ATS bounded check (no C FFI).
# The non-linear Option type needs -DATS_MEMALLOC_LIBC to link.
# patscc leaves an intermediate beal_check_pure_dats.c in the working
# directory; it is removed here so it never lands in the tree.
ats-pure-check:
	patscc -DATS_MEMALLOC_LIBC -o /tmp/beal_ats_pure \
		hardware/ats/beal_check_pure.dats
	/tmp/beal_ats_pure
	rm -f beal_check_pure_dats.c hardware/ats/beal_check_pure_dats.c

# Compile the Bluespec kernels to Verilog (zero warnings).
bsv-check:
	mkdir -p /tmp/bsv_out
	$(BSC) -u -verilog -vdir /tmp/bsv_out -bdir /tmp/bsv_out \
		-info-dir /tmp/bsv_out -g mkBealArithmetic \
		hardware/BealArithmetic.bsv
	$(BSC) -u -verilog -vdir /tmp/bsv_out -bdir /tmp/bsv_out \
		-info-dir /tmp/bsv_out -g mkBealCheck \
		hardware/bluespec/BealCheck.bsv

# Generate ASP facts from the obligations and solve the dependency rules.
# clingo exits 10 or 30 when a model is found (satisfiable); 20 means
# unsatisfiable (a constraint is violated) and any other code is an error.
asp-check: transform
	bash asp/facts.sh build/obligations.xml build/facts.lp
	clingo asp/dependencies.lp build/facts.lp; rc=$$?; case $$rc in 10|30) exit 0;; *) exit $$rc;; esac

clean:
	rm -rf build dag/render
