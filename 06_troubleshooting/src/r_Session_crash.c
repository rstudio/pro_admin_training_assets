/* Creates or overwrites the /etc/profile file with 
 * an invalid LD_LIBRARY_PATH directory, named "invalid"
 * Used for R Conference Workshop troubleshooting exercise.
 */

#include <stdio.h>

int main() {
  FILE * fp;
  fp = fopen("/etc/profile", "a+");
  fputs("export LD_LIBRARY_PATH=invalid/\n", fp);
  fclose(fp);
  return (0);
}
