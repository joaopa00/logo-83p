#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NONE 0xFFFD

static const long int translate[256] =
  {  0,       0x1D45B, 0x1D42E, 0x1D42F,  0x1D430, 0x25B6, '\t',     0x21E9,
     0x222B,  0xD7,    NONE,    NONE,     0xB7,    NONE,   NONE,     0x1D405,
     0x221A,  NONE,    0xB2,    0x2220,   0xB0,    NONE,   NONE,     0x2264,
     0x2260,  0x2265,  0x2212,  NONE,     0x2192,  NONE,   0x2191,   0x2193,
     ' ',     '!',     '"',     '#',      0x2074,  '%',    '&',      '\'',
     '(',     ')',     '*',     '+',      ',',     '-',    '.',      '/',
     '0',     '1',     '2',     '3',      '4',     '5',    '6',      '7',
     '8',     '9',     ':',     ';',      '<',     '=',    '>',      '?',

     '@',     'A',     'B',     'C',      'D',     'E',    'F',      'G',
     'H',     'I',     'J',     'K',      'L',     'M',    'N',      'O',
     'P',     'Q',     'R',     'S',      'T',     'U',    'V',      'W',
     'X',     'Y',     'Z',     0x3B8,    '\\',    ']',    '^',      '_',
     '`',     'a',     'b',     'c',      'd',     'e',    'f',      'g',
     'h',     'i',     'j',     'k',      'l',     'm',    'n',      'o',
     'p',     'q',     'r',     's',      't',     'u',    'v',      'w',
     'x',     'y',     'z',     '{',      '|',     '}',    '~',      NONE,

     0x2080,  0x2081,  0x2082,  0x2083,   0x2084,  0x2085, 0x2086,   0x2087,
     0x2088,  0x2089,  0xC1,    0xC0,     0xC2,    0xC4,   0xE1,     0xE0,
     0xE2,    0xE4,    0xC9,    0xC8,     0xCA,    0xCB,   0xE9,     0xE8,
     0xEA,    0xEB,    0xCD,    0xCC,     0xCE,    0xCF,   0xED,     0xEC,
     0xEE,    0xEF,    0xD3,    0xD2,     0xD4,    0xD6,   0xF3,     0xF2,
     0xF4,    0xF6,    0xDA,    0xD9,     0xDB,    0xDC,   0xFA,     0xF9,
     0xFB,    0xFC,    0xC7,    0xE7,     0xD1,    0xF1,   0xB4,     '`',
     0xA8,    0xBF,    0xA1,    0x3B1,    0x3B2,   0x3B3,  0x394,    0x3B4,

     0x3B5,   '[',     0x3BB,   0x3BC,    0x3C0,   0x3C1,  0x3A3,    0x3C3,
     0x3C4,   0x3C6,   0x3A9,   NONE,     NONE,    NONE,   0x2026,   0x25C0,
     0x25A0,  NONE,    0x2010,  NONE,     NONE,    0xB3,   '\n',     0x2148,
     NONE,    0x3C7,   NONE,    NONE,     NONE,    NONE,   NONE,     NONE,
     NONE,    NONE,    NONE,    NONE,     NONE,    NONE,   NONE,     NONE,
     NONE,    NONE,    NONE,    NONE,     NONE,    NONE,   NONE,     NONE,
     NONE,    ' ',     '$',     0x21E7,   0xDF,    NONE,   NONE,     NONE,
     NONE,    NONE,    NONE,    NONE,     NONE,    NONE,   NONE,     NONE  };

static void write_utf8(long int c, FILE* outfile)
{
  if (c < 0x80)
    fputc(c, outfile);
  else if (c < 0x800) {
    fputc(0xc0 | ((c >> 6) & 0x1f), outfile);
    fputc(0x80 | (c & 0x3f), outfile);
  }
  else if (c < 0x10000) {
    fputc(0xe0 | ((c >> 12) & 0x0f), outfile);
    fputc(0x80 | ((c >> 6) & 0x3f), outfile);
    fputc(0x80 | (c & 0x3f), outfile);
  }
  else if (c < 0x200000) {
    fputc(0xf0 | ((c >> 18) & 0x07), outfile);
    fputc(0x80 | ((c >> 12) & 0x3f), outfile);
    fputc(0x80 | ((c >> 6) & 0x3f), outfile);
    fputc(0x80 | (c & 0x3f), outfile);
  }
}


static long int read_utf8(FILE* infile)
{
  int a, i, n;
  long int v;

  a = fgetc(infile);
  if (a == EOF)
    return -1;

  if (a < 0x80)
    return a;

  if (a < 0xc0)
    return -2;

  if (a < 0xe0) {
    v = (a & 0x1f);
    n = 1;
  }
  else if (a < 0xf0) {
    v = (a & 0x0f);
    n = 2;
  }
  else if (a < 0xf8) {
    v = (a & 0x07);
    n = 3;
  }
  else if (a < 0xfc) {
    v = (a & 0x03);
    n = 4;
  }
  else if (a < 0xfe) {
    v = (a & 0x01);
    n = 5;
  }
  else
    return -2;

  for (i = 0; i < n; i++) {
    a = fgetc(infile);
    if (a == EOF)
      return -2;

    if (a < 0x80 || a > 0xbf)
      return -2;
    
    v = ((v << 6) | (a & 0x3f));
  }

  return v;
}


#define xmalloc(nnn) xrealloc(0, (nnn))

static void* xrealloc(void* p, unsigned long n)
{
  if (n) {
    if (p)
      p = realloc(p, n);
    else
      p = malloc(n);
    if (!p) {
      fprintf(stderr, "out of memory (need %lu bytes)\n", n);
      abort();
    }
  }
  else {
    free(p);
    p = 0;
  }
  return p;
}



#define READ_DATA(bbb, nnn) do {				\
    if ((nnn) > fread((bbb), 1, (nnn), infile)) {		\
      fprintf(stderr, "Unexpected EOF or I/O error in %s\n",	\
	      infilename);					\
      return 1;							\
    }								\
    fsize -= (nnn);						\
  } while (0)

#define READ_WORD(vvv) do {		\
    READ_DATA(ibuf, 2);			\
    (vvv) = (ibuf[0] | (ibuf[1] << 8));	\
  } while (0)

#define SKIP_DATA(nnn) fseek(infile, (nnn), SEEK_CUR)


static int notefolio_to_text(FILE* infile, FILE* outfile, char* infilename)
{
  unsigned char buf[256], ibuf[2];
  char vname[9];
  unsigned int fsize = 0;
  unsigned int hsize, vsize, tsize;
  unsigned int i;

  /* Read file header */
  if (53 > fread(buf, 1, 53, infile)
      || strncmp((char*) buf, "**TI83F*", 8)) {
    fprintf(stderr, "%s is not a valid appvar file.\n", infilename);
    return 1;
  }

  READ_WORD(fsize);

  while (fsize > 0) {

    READ_WORD(hsize);		/* size of variable header */

    if (hsize < 11 || hsize > 32) {
      fprintf(stderr, "%s contains invalid variable data.\n", infilename);
      return 1;
    }

    READ_DATA(buf, hsize);	/* read variable header*/
    READ_WORD(vsize);		/* get size of variable data */

    strncpy(vname, (char*) buf + 3, 8);
    vname[8] = 0;

    if ((buf[2] & 0x1f) != 0x15) {
      fprintf(stderr, "Warning: %s contains non-appvar data.\n", infilename);
      SKIP_DATA(vsize);
    }
    else if (vsize < 26) {
      fprintf(stderr, "Warning: Appvar %s is not a Notefolio file.\n", vname);
      SKIP_DATA(vsize);
    }
    else {
      READ_DATA(buf, 26);	/* read variable length + Notefolio header */
      
      if (buf[2] != 0xf3 || buf[3] != 0x47 || buf[4] != 0xbf || buf[5] != 0xaf) {
	fprintf(stderr, "Warning: Appvar %s is not a Notefolio file.\n", vname);
	SKIP_DATA(vsize - 26);
      }
      else {
	/* Get length of text from Notefolio header */
	tsize = (buf[18] | (buf[19] << 8)) - 26;
	if (tsize > vsize - 26)
	  tsize = vsize - 26;

	for (i = 0; i < tsize; i++) {
	  READ_DATA(buf, 1);
	  write_utf8(translate[buf[0]], outfile);
	}

	SKIP_DATA(vsize - tsize - 26);
      }
    }
  }
  return 0;
}


#define WRITE_BYTE(bbb) do {			\
    fputc((bbb) & 0xff, outfile);		\
    check += ((bbb) & 0xff);			\
  } while (0)

#define WRITE_WORD(www) do {			\
    WRITE_BYTE((www));				\
    WRITE_BYTE((www) >> 8);			\
  } while (0)

#define WRITE_WORD_NO_CHECK(www) do {		\
    fputc((www) & 0xff, outfile);		\
    fputc(((www) >> 8) & 0xff, outfile);	\
  } while (0)

enum { NORMAL, BACKSLASH, VBAR, VBAR_BACKSLASH, COMMENT };

static int text_to_notefolio(FILE* infile, FILE* outfile, char* infilename)
{
  char* text = NULL;
  unsigned long length = 0, length_a = 0;
  char vname[9];
  char comment[43];
  unsigned long i;
  int warned_invalid = 0;
  unsigned int check = 0;
  long int c;
  char *p = NULL;
  int state = NORMAL;

  for (i = 0; infilename[i]; i++)
    if (infilename[i] == '/' || infilename[i] == '\\')
      p = &infilename[i+1];

  if (!p)
    p = infilename;

  for (i = 0; i < 8 && p[i] && p[i] != '.'; i++) {
    if (p[i] >= 'A' && p[i] <= 'Z')
      vname[i] = p[i];
    else if (p[i] >= 'a' && p[i] <= 'z')
      vname[i] = p[i] + 'A' - 'a';
    else if (p[i] >= '0' && p[i] <= '9')
      vname[i] = p[i];
    else
      vname[i] = '[';
  }
  while (i < 9)
    vname[i++] = 0;

  while (!feof(infile) && !ferror(infile)) {
    if (length >= length_a) {
      length_a += 1024;
      text = xrealloc(text, length_a);
    }

    c = read_utf8(infile);
    if (c == -2) {
      if (!warned_invalid)
	fprintf(stderr, "Warning: invalid UTF-8 text in %s\n", infilename);
      warned_invalid = 1;
    }
    else if (c == '\t')
      text[length++] = ' ';
    else if (c != -1) {

      switch (state) {
      case NORMAL:
	if (c >= 'a' && c <= 'z')
	  c = c + 'A' - 'a';
	else if (c == '\\')
	  state = BACKSLASH;
	else if (c == '|')
	  state = VBAR;
	else if (c == ';')
	  state = COMMENT;
	break;

      case BACKSLASH:
	state = NORMAL;
	break;

      case VBAR:
	if (c == '\\')
	  state = VBAR_BACKSLASH;
	else if (c == '|')
	  state = NORMAL;
	break;

      case VBAR_BACKSLASH:
	state = VBAR;
	break;

      case COMMENT:
	if (c == '\n')
	  state = NORMAL;
	break;
      }

      for (i = 0; i < 256; i++) {
	if (translate[i] == c) {
	  text[length++] = i;
	  break;
	}
      }
    }
  }

  fputs("**TI83F*", outfile);
  fputc(0x1a, outfile);
  fputc(0x0a, outfile);
  fputc(0x00, outfile);

  for (i = 0; i < 42; i++)
    comment[i] = 0;
  snprintf(comment, 43, "Generated by nfconv from %s", infilename);
  fwrite(comment, 1, 42, outfile);

  WRITE_WORD_NO_CHECK(length + 2 + 13 + 2 + 2 + 24 + 3);

  /* data section begins */

  /* variable header */
  WRITE_WORD(13);			  /* size of var header */
  WRITE_WORD(length + 2 + 24 + 3);	  /* size of var data */
  WRITE_BYTE(0x15);			  /* type = appvar */
  for (i = 0; i < 8; i++)
    WRITE_BYTE(vname[i]);		  /* variable name */
  WRITE_BYTE(0);			  /* version */
  WRITE_BYTE(0);			  /* archived */

  /* variable data */
  WRITE_WORD(length + 2 + 24 + 3);	  /* size of var data */
  WRITE_WORD(length + 24 + 3);
  /* Notefolio header */
  WRITE_WORD(0x47F3);			  /* magic number */
  WRITE_WORD(0xAFBF);
  WRITE_WORD(0);			  /* unknown */
  WRITE_WORD(0);
  for (i = 0; i < 8; i++)
    WRITE_BYTE(vname[i]);		  /* copy of variable name */
  WRITE_WORD(length + 24);		  /* offset to end of text section */
  WRITE_WORD(24);			  /* offset to start of window */
  WRITE_WORD(24);			  /* offset to cursor position */
  WRITE_WORD(3);			  /* file does not contain
					     word-wrapping marks */

  /* Text */
  for (i = 0; i < length; i++)
    WRITE_BYTE(text[i]);

  WRITE_BYTE(0);			  /* unknown */
  WRITE_BYTE(0);
  WRITE_BYTE(0);

  /* file checksum */
  WRITE_WORD_NO_CHECK(check);

  if (text)
    free(text);

  return 0;
}


static int do_convert(char* infilename, char* outfilename)
{
  FILE *infile, *outfile;
  char *p;
  int status;

  infile = fopen(infilename, "rb");
  if (!infile) {
    perror(infilename);
    return 1;
  }

  outfile = fopen(outfilename, "wb");
  if (!outfile) {
    perror(outfilename);
    fclose(infile);
    return 1;
  }

  p = strrchr(infilename, '.');

  if (p && p[1] == '8'
      && (p[2] == 'X' || p[2] == 'x')) {
    status = notefolio_to_text(infile, outfile, infilename);
  }
  else {
    status = text_to_notefolio(infile, outfile, infilename);
  }

  fclose(infile);
  fclose(outfile);
  return status;
}


static const char usage[] = "Usage: %s INPUT-FILE [-o OUTPUT-FILE]\n";

int main(int argc, char** argv)
{
  int i;
  int status = 0;
  char *infilename = NULL, *outfilename = NULL;
  char *p;

  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      if (argv[i][1] == 'o') {
	if (outfilename) {
	  fprintf(stderr, "%s: multiple output filenames specified\n",
		  argv[0]);
	  fprintf(stderr, usage, argv[0]);
	  return 1;
	}
	if (argv[i][2])
	  outfilename = &argv[i][2];
	else if (++i < argc)
	  outfilename = argv[i];
      }
      else if (!strcmp(argv[i], "--help")) {
	fprintf(stderr, usage, argv[0]);
	return 0;
      }
      else {
	fprintf(stderr, "%s: unknown option %s\n",
		argv[0], argv[i]);
	fprintf(stderr, usage, argv[0]);
	return 1;
      }
    }
    else {
      if (infilename) {
	fprintf(stderr, "%s: multiple input filenames specified\n",
		argv[0]);
	fprintf(stderr, usage, argv[0]);
	return 1;
      }
      infilename = argv[i];
    }
  }

  if (!infilename) {
    fprintf(stderr, usage, argv[0]);
    return 1;
  }

  if (!outfilename) {
    outfilename = xmalloc(strlen(infilename) + 5);
    strcpy(outfilename, infilename);
    p = strrchr(outfilename, '.');

    if (p && p[1] == '8'
	&& (p[2] == 'X' || p[2] == 'x'))
      strcpy(p, ".lgo");
    else if (p)
      strcpy(p, ".8xv");
    else
      strcat(outfilename, ".8xv");

    status = do_convert(infilename, outfilename);
    free(outfilename);
  }
  else
    status = do_convert(infilename, outfilename);

  return status;
}
