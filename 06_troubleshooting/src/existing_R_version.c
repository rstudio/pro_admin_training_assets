/* Modifies permissions on a specific R_HOME directory
 * to rwx for root only.  i.e.  chmod 700 /path/to/R_HOME
 * Used for R Conference Workshop troubleshooting exercise.
 */

//Ref:  https://pubs.opengroup.org/onlinepubs/000095399/functions/chmod.html

#include <sys/stat.h>

int main() {
#define CHANGEDIR "/opt/R/3.5.1/"

//The following sets rwx permissions for the owner, and no permissions for group and others.
chmod(CHANGEDIR, S_IRWXU);
}
