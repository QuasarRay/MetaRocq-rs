/*
 * Minimal host bridge for UnifiedE2EPipeline.cml.
 *
 * CakeML owns stage ordering and fail-closed policy.  The controller passes
 * only fixed commands of the form ./tools/unified_e2e_stage.sh NN.
 * This bridge is orchestration plumbing and is never accepted as proof
 * evidence.
 */
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

void ffie2e_exec(unsigned char *c, long clen, unsigned char *a, long alen) {
  if (alen < 2) return;
  a[0] = 127;
  a[1] = 1;

  if (clen <= 0 || clen > 256) return;

  char *cmd = (char *)malloc((size_t)clen + 1);
  if (cmd == NULL) return;
  memcpy(cmd, c, (size_t)clen);
  cmd[clen] = '\0';

  /* Defense in depth: the CakeML program can only request the fixed dispatcher. */
  const char prefix[] = "./tools/unified_e2e_stage.sh ";
  if (strncmp(cmd, prefix, sizeof(prefix) - 1) != 0) {
    free(cmd);
    return;
  }

  int rc = system(cmd);
  free(cmd);

  if (rc == -1) return;
  if (WIFEXITED(rc)) {
    a[0] = (unsigned char)WEXITSTATUS(rc);
    a[1] = 0;
    return;
  }

  if (WIFSIGNALED(rc)) {
    int sig = WTERMSIG(rc);
    a[0] = (unsigned char)(128 + (sig & 0x7f));
    a[1] = 1;
  }
}
