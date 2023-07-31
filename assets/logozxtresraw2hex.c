#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char *argv[])
{
	FILE *f;
	unsigned char *scr;
	int i,leido;
	
	scr = malloc(49152);
	f = fopen ("logo_zxtres_24bpp.raw","rb");
	if (!f)
		return 1;
		
	leido = fread (scr, 1, 49152, f);
	fclose (f);
	
	f = fopen ("logo_zxtres.hex", "wt");
  for (int y=0; y<64; y++)
  {
    for (int x=0; x<256*3; x+=3)
    {
      int v = 0;
      
      if (scr[y*256*3+x+0] != 0)
        v = 4;

      if (scr[y*256*3+x+1] != 0)
        v += 2;
      
      if (scr[y*256*3+x+2] != 0)
        v += 1;

      fprintf (f, "%1.1X\n", v);
    }
  }
  
	fclose(f);
	
	return 0;
}

