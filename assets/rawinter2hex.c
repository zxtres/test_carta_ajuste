#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char *argv[])
{
	FILE *f;
	unsigned char *scr;
	char nombre[256];
	int i,leido;
	
	if (argc<2)
		return 1;
	
	scr = malloc(1048576);
	f = fopen (argv[1],"rb");
	if (!f)
		return 1;
		
	leido = fread (scr, 1, 1048576, f);
	fclose (f);
	
	strcpy (nombre, argv[1]);
	nombre[strlen(nombre)-3]=0;
	strcat (nombre, "hex");
	
	f = fopen (nombre, "wt");
  for (int y=0; y<576; y+=2)
    for (int x=0; x<704; x++)
      fprintf (f, "%.2X\n", scr[y*704+x]);
  for (int y=1; y<576; y+=2)
    for (int x=0; x<704; x++)
      fprintf (f, "%.2X\n", scr[y*704+x]);
  
	fclose(f);
	
	return 0;
}

