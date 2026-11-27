// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
//
// render.c — minimal Mustache renderer for the obligation template.
//
// Handles exactly the constructs used by templates/obligation.mustache:
//   {{! comment }}        — stripped
//   {{variable}}          — substituted from the data file
//   {{#dependencies}}...{{/dependencies}} — repeated once per dependency,
//                           with {{.}} substituted by the dependency id.
//                           An empty list renders nothing.
//
// Data file format (one entry per line):
//   key=value
//   dependencies=id1,id2,...   (comma-separated; empty means no dependencies)
//
// Usage:
//   render <template> <datafile>
//   Writes the rendered output to stdout. Exits non-zero on any error
//   (missing file, unknown variable, malformed template).
//
// Exit codes:
//   0 — rendered successfully
//   1 — usage / I/O error
//   2 — unknown variable or malformed template

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TEMPLATE 65536
#define MAX_LINE 4096
#define MAX_VARS 64
#define MAX_DEPS 64
#define MAX_NAME 128
#define MAX_VALUE 1024

typedef struct {
    char name[MAX_NAME];
    char value[MAX_VALUE];
} Var;

static Var vars[MAX_VARS];
static int nvars = 0;
static char deps[MAX_DEPS][MAX_NAME];
static int ndeps = 0;

static void die(const char *msg) {
    fprintf(stderr, "render: %s\n", msg);
    exit(1);
}

static const char *lookup(const char *name) {
    for (int i = 0; i < nvars; i++) {
        if (strcmp(vars[i].name, name) == 0) return vars[i].value;
    }
    return NULL;
}

// Read the data file. Lines are key=value. The special key "dependencies"
// holds a comma-separated list.
static void read_data(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) die("cannot open data file");
    char line[MAX_LINE];
    while (fgets(line, sizeof(line), f)) {
        // strip trailing newline
        size_t len = strlen(line);
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = '\0';
        if (len == 0) continue;
        char *eq = strchr(line, '=');
        if (!eq) {
            fclose(f);
            die("malformed data line (expected key=value)");
        }
        *eq = '\0';
        const char *key = line;
        const char *val = eq + 1;
        if (strcmp(key, "dependencies") == 0) {
            if (val[0] == '\0') {
                ndeps = 0;
            } else {
                // split on commas
                char buf[MAX_VALUE];
                if (strlen(val) >= sizeof(buf)) { fclose(f); die("dependencies value too long"); }
                strcpy(buf, val);
                char *tok = strtok(buf, ",");
                while (tok) {
                    if (ndeps >= MAX_DEPS) { fclose(f); die("too many dependencies"); }
                    if (strlen(tok) >= MAX_NAME) { fclose(f); die("dependency id too long"); }
                    strcpy(deps[ndeps++], tok);
                    tok = strtok(NULL, ",");
                }
            }
        } else {
            if (nvars >= MAX_VARS) { fclose(f); die("too many variables"); }
            if (strlen(key) >= MAX_NAME || strlen(val) >= MAX_VALUE) {
                fclose(f);
                die("variable name or value too long");
            }
            strcpy(vars[nvars].name, key);
            strcpy(vars[nvars].value, val);
            nvars++;
        }
    }
    fclose(f);
}

// Render a template fragment [start, end) to stdout.
// Handles {{! comment}}, {{var}}, {{.}} and {{#dependencies}}...{{/dependencies}}.
static void render_range(const char *start, const char *end) {
    const char *p = start;
    while (p < end) {
        const char *open = strstr(p, "{{");
        if (!open || open >= end) {
            fwrite(p, 1, (size_t)(end - p), stdout);
            return;
        }
        fwrite(p, 1, (size_t)(open - p), stdout);
        const char *close = strstr(open + 2, "}}");
        if (!close || close >= end) {
            fprintf(stderr, "render: unterminated tag\n");
            exit(2);
        }
        // tag content between {{ and }}
        size_t taglen = (size_t)(close - (open + 2));
        if (taglen >= MAX_NAME) {
            fprintf(stderr, "render: tag too long\n");
            exit(2);
        }
        char tag[MAX_NAME];
        memcpy(tag, open + 2, taglen);
        tag[taglen] = '\0';
        // trim surrounding whitespace in the tag
        char *t = tag;
        while (*t == ' ' || *t == '\t') t++;
        char *e = t + strlen(t);
        while (e > t && (e[-1] == ' ' || e[-1] == '\t')) *--e = '\0';

        if (t[0] == '!') {
            // comment: strip, emit nothing
        } else if (t[0] == '#') {
            // section start: only "dependencies" is supported
            if (strcmp(t + 1, "dependencies") != 0) {
                fprintf(stderr, "render: unsupported section #%s\n", t + 1);
                exit(2);
            }
            // find matching {{/dependencies}}
            char endtag[64];
            snprintf(endtag, sizeof(endtag), "{{/%s}}", t + 1);
            const char *sec_end = strstr(close + 2, endtag);
            if (!sec_end || sec_end >= end) {
                fprintf(stderr, "render: unterminated section %s\n", t + 1);
                exit(2);
            }
            const char *body_start = close + 2;
            const char *body_end = sec_end;
            for (int i = 0; i < ndeps; i++) {
                // render body with {{.}} = deps[i]
                const char *q = body_start;
                while (q < body_end) {
                    const char *o = strstr(q, "{{.}}");
                    if (!o || o >= body_end) {
                        fwrite(q, 1, (size_t)(body_end - q), stdout);
                        break;
                    }
                    fwrite(q, 1, (size_t)(o - q), stdout);
                    fputs(deps[i], stdout);
                    q = o + 5;
                }
            }
            p = sec_end + strlen(endtag);
            continue;
        } else if (t[0] == '/') {
            fprintf(stderr, "render: unexpected closing tag %s\n", t);
            exit(2);
        } else if (strcmp(t, ".") == 0) {
            fprintf(stderr, "render: {{.}} outside a section\n");
            exit(2);
        } else {
            const char *val = lookup(t);
            if (!val) {
                fprintf(stderr, "render: unknown variable %s\n", t);
                exit(2);
            }
            fputs(val, stdout);
        }
        p = close + 2;
    }
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: render <template> <datafile>\n");
        return 1;
    }
    read_data(argv[2]);

    FILE *f = fopen(argv[1], "r");
    if (!f) die("cannot open template file");
    static char tmpl[MAX_TEMPLATE];
    size_t n = fread(tmpl, 1, sizeof(tmpl) - 1, f);
    if (ferror(f)) { fclose(f); die("cannot read template file"); }
    fclose(f);
    tmpl[n] = '\0';
    // refuse a template that was truncated by the buffer
    if (n == sizeof(tmpl) - 1) die("template too large");

    render_range(tmpl, tmpl + n);
    return 0;
}
