#include <stdio.h>

int main(int argc, char** argv)
{
  FILE* infile;
  FILE* outfile;
  int c;
  int nextspace = 0;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s logolib.lgo logolib.bin\n",
	    argv[0]);
    return 1;
  }

  infile = fopen(argv[1], "rt");
  if (!infile) {
    perror(argv[1]);
    return 2;
  }

  outfile = fopen(argv[2], "wb");
  if (!outfile) {
    fclose(infile);
    perror(argv[2]);
    return 4;
  }

  do {
    c = fgetc(infile);
    if (c != EOF) {
      if (c == ' ' || c == '\t' || c == '\n') {
	if (!nextspace) {
	  if (c == '\n')
	    nextspace = 0xd6;
	  else
	    nextspace = ' ';
	}
      }
      else if (c == ';') {
	while (c != '\n' && !feof(infile) && !ferror(infile))
	  c = fgetc(infile);
	nextspace = 0xd6;
      }
      else {
	if (nextspace)
	  fputc(nextspace, outfile);
	nextspace = 0;
	if (c >= 'a' && c <= 'z')
	  fputc(c + 'A' - 'a', outfile);
	else if (c == '[')
	  fputc(0xc1, outfile);
	else
	  fputc(c, outfile);
      }
    }
  } while (!feof(infile) && !ferror(infile));

  fclose(infile);
  fclose(outfile);
  return 0;
}
