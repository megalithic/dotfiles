// Ultimate.app: the hub LaunchAgent's program. macOS blames a privacy prompt on the
// responsible process, which for anything launchd starts is that program itself. Bare
// node made every prompt say "node"; this signed bundle stays the parent of the hub
// (it never execs), so prompts from the hub and everything it runs say "Ultimate".
//
// It also starts the menu bar count (Contents/MacOS/UltimateMenu, built from menu/) as a
// separate child, so a menu crash never takes the hub down: a menu that exits is started
// again 30 s later. The launcher exits with the hub, and launchd's KeepAlive restarts both.
#include <errno.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;
static pid_t hub, menu;
static volatile sig_atomic_t restart_menu;

static void forward(int sig) {
  if (hub > 0) kill(hub, sig);
  if (menu > 0) kill(menu, sig);
}

static void alarmed(int sig) {
  (void)sig;
  restart_menu = 1;
}

static pid_t spawn(const char *path) {
  pid_t pid;
  char *argv[] = {(char *)path, NULL};
  int err = posix_spawn(&pid, path, NULL, NULL, argv, environ);
  if (err) {
    fprintf(stderr, "Ultimate.app: cannot start %s (errno %d)\n", path, err);
    return 0;
  }
  return pid;
}

int main(void) {
  const char *home = getenv("HOME");
  if (!home) {
    fprintf(stderr, "Ultimate.app: HOME is not set\n");
    return 1;
  }
  char script[1024];
  snprintf(script, sizeof script, "%s/.dotfiles/mise/scripts/ultimate-hub-launchd", home);

  // The menu sits beside this executable; a bundle built without it runs the hub alone.
  char self[1024], resolved[1024], menu_path[1100] = "";
  uint32_t size = sizeof self;
  if (_NSGetExecutablePath(self, &size) == 0 && realpath(self, resolved)) {
    snprintf(menu_path, sizeof menu_path, "%s/UltimateMenu", dirname(resolved));
    if (access(menu_path, X_OK) != 0) menu_path[0] = '\0';
  }

  signal(SIGTERM, forward);
  signal(SIGINT, forward);
  signal(SIGHUP, forward);
  // Without SA_RESTART, the alarm interrupts waitpid below.
  struct sigaction alarm_action = {.sa_handler = alarmed};
  sigaction(SIGALRM, &alarm_action, NULL);

  hub = spawn(script);
  if (!hub) return 1;
  if (menu_path[0]) menu = spawn(menu_path);

  for (;;) {
    int status;
    pid_t pid = waitpid(-1, &status, 0);
    if (pid == hub) {
      if (menu > 0) kill(menu, SIGTERM);
      if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
      return WEXITSTATUS(status);
    }
    if (pid > 0 && pid == menu) {
      fprintf(stderr, "Ultimate.app: the menu bar exited (status %d); starting it again in 30 s\n", status);
      menu = 0;
      alarm(30);
    }
    if (pid < 0 && errno != EINTR) return 1;
    if (restart_menu) {
      restart_menu = 0;
      menu = spawn(menu_path);
    }
  }
}
