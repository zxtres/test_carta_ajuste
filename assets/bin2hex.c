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
	for (i=0;i<leido;i++)
		fprintf (f, "%.2X\n", scr[i]);
	fclose(f);
	
	return 0;
}

