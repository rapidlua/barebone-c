#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <wasi/api.h>

#include "d.h"

static void expect_dlocate(
  int lineno, struct dd *ddarg, const char *patharg,
  int res, struct dd *ddres
) {
  int rc = __dlocate(&ddarg, patharg, 0);
  if (rc != res) {
    fprintf(stderr, "%d: result must be %d, got %d\n", lineno, res, rc);
  }
  if (res >= 0 && rc >= 0 && ddres != ddarg) {
    fprintf(stderr, "%d: wrong node: ", lineno);
    while (ddarg && ddarg->d_parent != ddarg) {
      fprintf(stderr, "|%s", ddarg->d_name);
      ddarg = ddarg->d_parent;
    }
    fputs("\n", stderr);

  }
}

#define EXPECT_DLOCATE(ddarg, patharg, res, ddres) \
  expect_dlocate(__LINE__, ddarg, patharg, res, ddres)

static void ddump(struct dd *droot) {
  for(struct dd *dd = droot; dd; dd = dd->d_next) {
    printf("[%p] fd=%2d parent=%p '%s'%s\n",
           dd, dd->d_fd, dd->d_parent, dd->d_name,
           dd == __dcwd ? " [cwd]": "");
  }
  puts("");
}

int main(int argc, char **argv) {

  struct dd droot = { .d_parent = &droot };
  EXPECT_DLOCATE(&droot, "", 0, &droot);
  EXPECT_DLOCATE(&droot, "/", 1, &droot);
  EXPECT_DLOCATE(&droot, "/////", 5, &droot);
  EXPECT_DLOCATE(&droot, "..", 2, &droot);
  EXPECT_DLOCATE(&droot, ".", 1, &droot);
  EXPECT_DLOCATE(&droot, "../", 3, &droot);
  EXPECT_DLOCATE(&droot, "./", 2, &droot);
  EXPECT_DLOCATE(&droot, "./foobar", 0, &droot);

  struct dd *a_b_c = &droot;
  __dlocate(&a_b_c, "a/b/c", 1); a_b_c->d_fd = 0;

  struct dd *a_b_d = &droot;
  __dlocate(&a_b_d, "a/b/e/../d", 1); a_b_d->d_fd = 0;

  EXPECT_DLOCATE(&droot, "a/b/c", 5, a_b_c);
  EXPECT_DLOCATE(&droot, "a/b/d", 5, a_b_d);
  EXPECT_DLOCATE(&droot, "a/b/d/foobar", 6, a_b_d);

  EXPECT_DLOCATE(&droot, "a/b/e", 0, &droot);
  EXPECT_DLOCATE(&droot, "a/b/c/../e", 6, a_b_c);

  puts("(droot)/");
  ddump(&droot);
  puts("(droot, after gc)/");
  ++__dgcmark;
  __dgc(&droot.d_next);
  ddump(&droot);

  ddump(&__droot);
  if (argc > 2 && chdir(argv[2])) perror("chdir");
  int fd = open(argv[1], O_CREAT|O_RDWR, 0);
  if (fd == -1) perror("open"); else printf("%d\n", fd);
  char buf[128];
  puts(getcwd(buf, sizeof(buf)));

  puts("/");
  ddump(&__droot);
  puts(".");
  ddump(__dcwd);

  return 0;
}
