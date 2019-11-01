/* Creates or overwrites a .bashrc in the current execution dir
 * .bashrc exports an invalid R_HOME directory, named "invalid"
 * Used for R Conference Workshop troubleshooting exercise.
 */

#include <stdio.h>

int main() {
  FILE * fp;
  fp = fopen(".bashrc", "w+");
  fputs("export R_HOME=invalid/\n", fp);
  fclose(fp);
  return (0);
}
