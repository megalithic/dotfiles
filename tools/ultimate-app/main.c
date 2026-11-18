// Ultimate.app: the hub LaunchAgent's program. macOS blames a privacy prompt on the
// responsible process, which for anything launchd starts is that program itself. Bare
// node made every prompt say "node"; this signed bundle stays the parent of the hub
// (it never execs), so prompts from the hub and everything it runs say "Ultimate".
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;
static pid_t child;

static void forward(int sig) {
  if (child > 0) kill(child, sig);
}

int main(void) {
  const char *home = getenv("HOME");
  if (!home) {
    fprintf(stderr, "Ultimate.app: HOME is not set\n");
    return 1;
  }
  char script[1024];
  snprintf(script, sizeof script, "%s/.dotfiles/mise/scripts/ultimate-hub-launchd", home);
  char *argv[] = {script, NULL};

  signal(SIGTERM, forward);
  signal(SIGINT, forward);
  signal(SIGHUP, forward);
  int err = posix_spawn(&child, script, NULL, NULL, argv, environ);
  if (err) {
    fprintf(stderr, "Ultimate.app: cannot start %s (errno %d)\n", script, err);
    return 1;
  }

  int status;
  while (waitpid(child, &status, 0) < 0) {}
  if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
  return WEXITSTATUS(status);
}
