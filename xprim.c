#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct priminfo {
  char* canonical;
  char** symnames;
  int nsymnames;
} *prims = NULL;
int nprims = 0;

#define xrenew(t, p, n) ((t*) xrealloc((p), (n) * sizeof(t)))

static void* xrealloc(void* p, size_t n)
{
  if (n) {
    if (p)
      p = realloc(p, n);
    else
      p = malloc(n);

    if (!p) {
      fprintf(stderr, "out of memory (need %lu bytes)\n",
	      (unsigned long) n);
      abort();
    }
  }
  else {
    if (p)
      free(p);
    p = NULL;
  }
  return p;
}

static char* xstrdup(const char* s)
{
  char* d = xrenew(char, 0, strlen(s) + 1);
  strcpy(d, s);
  return d;
}

int main(int argc, char** argv)
{
  int i, j;
  char buf[512];
  char *p, *q;
  struct priminfo *prim;
  int errors = 0;
  FILE *inf, *outf;

  if (argc == 1) {
    fprintf(stderr, "Usage: %s ASMFILE ...\n", argv[0]);
    return 1;
  }

  for (i = 1; i < argc; i++) {
    inf = fopen(argv[i], "rb");
    if (!inf) {
      perror(argv[i]);
      return 2;
    }

    while (fgets(buf, sizeof(buf), inf)) {
      if (buf[0] == ';' && buf[1] == ';' && buf[2] == ' '
	  && (p = strchr(buf, ':'))) {

	/* start of adoc comment */
	*p = 0;
	nprims++;
	prims = xrenew(struct priminfo, prims, nprims);
	prim = &prims[nprims-1];
	prim->canonical = xstrdup(&buf[3]);
	prim->symnames = NULL;
	prim->nsymnames = 0;

	/* scan synopsis section */
	while (fgets(buf, sizeof(buf), inf) && buf[0] == ';' && buf[1] == ';') {
	  p = &buf[2];
	  while (*p == ' ' || *p == '(') p++;
	  q = p;
	  while (*q != 0 && *q != ' ' && *q != '\n' && *q != '\r') q++;
	  if (p != q) {
	    *q = 0;
	    for (j = 0; j < prim->nsymnames; j++)
	      if (!strcmp(prim->symnames[j], p))
		break;
	    if (j == prim->nsymnames) {
	      prim->nsymnames++;
	      prim->symnames = xrenew(char*, prim->symnames, j + 1);
	      prim->symnames[j] = xstrdup(p);
	    }
	  }
	  else if (prim->nsymnames)
	    break;
	}

	/* skip rest of comment */
	while (buf[0] == ';' && buf[1] == ';')
	  if (!fgets(buf, sizeof(buf), inf))
	    break;

	/* skip following blank lines */
	while (buf[0] == 0 || buf[0] == '\n' || buf[0] == '\r')
	  if (!fgets(buf, sizeof(buf), inf))
	    break;

	if (buf[0] != 'p' || buf[1] != '_'
	    || strncmp(&buf[2], prim->canonical, strlen(prim->canonical))
	    || buf[2 + strlen(prim->canonical)] != ':') {
	  fprintf(stderr, "%s: %s: label/comment mismatch\n",
		  argv[i], prim->canonical);
	  errors++;
	  nprims--;
	}
      }
    }

    fclose(inf);
  }

  if (errors || !nprims)
    return 3;

  inf = fopen("data.asm.in", "rb");
  if (!inf) {
    perror("data.asm.in");
    return 2;
  }

  outf = fopen("data.asm", "wb");
  if (!outf) {
    perror("data.asm");
    fclose(inf);
    return 4;
  }

  fgets(buf, sizeof(buf), inf);	/* skip first line */
  fprintf(outf, ";;; -*- Text -*-\n;;; AUTOMATICALLY GENERATED -- DO NOT EDIT\n");

  while (fgets(buf, sizeof(buf), inf)) {
    if (!strncmp(buf, "@XPRIM-OBJECTS@", 15)) {
      fprintf(outf,
	      "TRUE_Sym: SYMBOL voidNode, voidNode,"
	      " voidNode, falseNode, \"TRUE\"\n"
	      "FALSE_Sym: SYMBOL voidNode, voidNode,"
	      " voidNode, %s_Node0, \"FALSE\"\n",
	      prims[0].symnames[0]);

      for (i = 0; i < nprims; i++) {
	for (j = 0; j < prims[i].nsymnames; j++) {
	  fprintf(outf, "%s_Sym%d: SYMBOL %s_Subr, voidNode, voidNode, ",
		  prims[i].canonical, j, prims[i].canonical);
	  if (j + 1 < prims[i].nsymnames)
	    fprintf(outf, "%s_Node%d", prims[i].canonical, j + 1);
	  else if (i + 1 < nprims)
	    fprintf(outf, "%s_Node0", prims[i+1].canonical);
	  else
	    fprintf(outf, "0");
	  fprintf(outf, ", \"%s\"\n", prims[i].symnames[j]);
	}
      }
    }
    else if (!strncmp(buf, "@XPRIM-SYM-NODES@", 17)) {
      fprintf(outf, "trueNode:       NODE T_SYMBOL, 0, TRUE_Sym\n");
      fprintf(outf, "falseNode:      NODE T_SYMBOL, 0, FALSE_Sym\n");
      for (i = 0; i < nprims; i++) {
	for (j = 0; j < prims[i].nsymnames; j++) {
	  fprintf(outf, "%s_Node%d: NODE T_SYMBOL, 0, %s_Sym%d\n",
		  prims[i].canonical, j, prims[i].canonical, j);
	}
      }
    }
    else if (!strncmp(buf, "@XPRIM-SUBR-NODES@", 18)) {
      for (i = 0; i < nprims; i++) {
	fprintf(outf, "%s_Subr: NODE T_SUBR, 0, p_%s\n",
		prims[i].canonical, prims[i].canonical);
      }
    }
    else {
      fputs(buf, outf);
    }
  }

  fclose(outf);
  return 0;
}
