/* remove once emscripten gets full WASI support */
#include <wasi/api.h>
#include <wasi/wasi-helpers.h>

#include <math.h>
#include <stdint.h>
#include <pthread.h>

#include <sys/types.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdlib.h>

#include "d.h"

/* __droot: directory tree at '/'
 * __dcwd: current working directory, normally points into __droot tree */
struct dd __droot = { .d_parent = &__droot, .d_fd = -1 };
struct dd *__dcwd = &__droot;

/* If $PWD is unknown at startup time, converting between abs and rel
 * pathes is NOT possible.  In the later case __dcwd will point into
 * dcwdhack, which is a separate tree.
 * dtarpit: catches attempts to escape dcwdhack via '..' */
static struct dd dtarpit = { .d_parent = &dtarpit, .d_fd = -1 };
static struct dd dcwdhack = { .d_parent = &dtarpit, .d_fd = -1 };

/* cwdfd: set if new fd was opened by chdir; -1 if pre-opened one was reused */
static int cwdfd = -1;

unsigned char __dgcmark;
int __dgccounter;

__attribute__((__noreturn__)) __wasi_errno_t __wasi_proc_raise(__wasi_signal_t);

__attribute__((__noreturn__)) static void __fatal(
  const __wasi_ciovec_t *iovs, size_t iovs_len
) {
  __wasi_size_t sz;
  (void)__wasi_fd_write(2, iovs, iovs_len, &sz);
  (void)__wasi_proc_raise(__WASI_SIGNAL_ABRT);
}

__attribute__((__noreturn__)) static void fatal(const char *msg) {
  __wasi_ciovec_t v[3] = {
    {(const void *)"fatal: ", 7},
    {(const void *)msg, strlen(msg)},
    {(const void *)"\n", 1}
  };
  __fatal(v, 3);
}

__attribute__((__noreturn__)) static void unexpected(const char *msg) {
  __wasi_ciovec_t v[3] = {
    {(const void *)"unexpected: ", 12},
    {(const void *)msg, strlen(msg)},
    {(const void *)"\n", 1}
  };
  __fatal(v, 3);
}

__attribute__((__noreturn__)) static void nyi(const char *msg) {
  __wasi_ciovec_t v[3] = {
    {(const void *)"nyi: ", 5},
    {(const void *)msg, strlen(msg)},
    {(const void *)"\n", 1}
  };
  __fatal(v, 3);
}

static void dremove(struct dd **p) {
  while (*p) {
    struct dd *tmp = *p; *p = (*p)->d_next; free(tmp);
  }
}

void __dgc(struct dd **p) {
  for (struct dd *i = *p; i; i = i->d_next) {
    if (i->d_fd < 0 && i != __dcwd) continue;
    i->d_gcmark = __dgcmark;
    for (struct dd *j = i->d_parent;
         j != j->d_parent && j->d_gcmark != __dgcmark;
         j = j->d_parent) j->d_gcmark = __dgcmark;
  }
  for (struct dd *i = *p; i;) {
    struct dd *tmp = i;
    i = i->d_next;
    if (tmp->d_gcmark == __dgcmark) {
      *p = tmp; p = &tmp->d_next;
    } else free(tmp);
  }
  *p = 0;
}

int __dlocate(struct dd **dd, const char *path, int create) {
  const char *p = path, *start = path;
  int backup = (*dd)->d_fd >= 0 ? 0 : -EPERM;
  struct dd *dbackup = *dd;
  do {
    if (*p != 0 && *p != '/') { ++p; continue; }

    const char *name = start;
    size_t namelen = p - start;
    p = start = p + 1;

    if (namelen == 0 || (namelen == 1 && name[0] == '.')) continue;

    if (namelen == 2 && name[0] == '.' && name[1] == '.') *dd = (*dd)->d_parent;
    else {
      struct dd **ddi = &(*dd)->d_next;
      for (;;) {
        if (!*ddi) {
          if (!create) {
            *dd = dbackup;
            return backup;
          }
          *ddi = malloc(offsetof(struct dd, d_name) + namelen + 1);
          if (!*ddi) return -ENOMEM;
          (*ddi)->d_parent = *dd;
          (*ddi)->d_next = 0;
          (*ddi)->d_fd = -1;
          (*ddi)->d_gcmark = __dgcmark;
          memcpy((*ddi)->d_name, name, namelen);
          (*ddi)->d_name[namelen] = 0;
          *dd = *ddi;
          ++__dgccounter;
          break;
        }
        if ((*ddi)->d_parent == *dd &&
            !strncmp((*ddi)->d_name, name, namelen) &&
            !(*ddi)->d_name[namelen]) { *dd = *ddi; break; }
        ddi = &(*ddi)->d_next;
      }
    }

    if ((*dd)->d_fd >= 0) {
      backup = (int)(p - path);
      dbackup = *dd;
    }

  } while (p[-1]);
  if ((*dd)->d_fd >= 0 || create) return (int)(p - 1 - path);
  *dd = dbackup;
  return backup;
}

double round(double v) {
  /* UB for NaN and huge numbers, probably fine for LLVM (audited) */
  return (double)(int64_t)(v + (v < .0 ? -.5 : .5));
}

int pthread_mutexattr_destroy(pthread_mutexattr_t *attr) { return 0; }
int pthread_mutexattr_init(pthread_mutexattr_t *attr) { return 0; }
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type) { return 0; }

int sigaction(int signum, const struct sigaction *a, struct sigaction *olda) {
  return 0;
}
int sigemptyset(sigset_t *set) { return 0; }
int sigfillset(sigset_t *set) { return 0; }
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset) { return 0; }
int raise(int sig) { unexpected("raise"); }

int execve(
  const char *pathname, char *const argv[], char *const envp[]
) {
  unexpected("execve");
  /* since fork is ENOSYS */
}

pid_t fork(void) {
  errno = ENOSYS;
  return -1;
}

pid_t wait4(pid_t pid, int *wstatus, int options, struct rusage *rusage) {
  unexpected("wait4");
  /* since fork is ENOSYS */
}

pid_t getpid(void) { return 1; }

int uname(struct utsname *buf) {
  memset(buf, 0, sizeof *buf);
  strcpy(buf->sysname, "wasi");
  strcpy(buf->machine, "wasi");
  return 0;
}

int statvfs(const char *path, struct statvfs *buf) {
  /* refd by llvm::sys::fs::is_local, never called */
  unexpected("statvfs");
}

int fstatvfs(int fd, struct statvfs *buf) {
  /* eliminated, duplicate symbol liker error w/o override */
  unexpected("fstatvfs");
}

int access(const char *pathname, int mode) {
  /* llvm::sys::fs::openFileForRead */
  /* llvm::sys::fs::access */
  nyi("access");
}

char *getcwd(char *buf, size_t size) {
  /* llvm::sys::fs::current_path */
  if (size < 2) { errno = ERANGE; return 0; }
  char *p = buf + size - 1; *p = 0;
  struct dd *dd = __dcwd;
  for (; dd->d_parent != dd; dd = dd->d_parent) {
    size_t len = strlen(dd->d_name);
    if ((p -= len + 1) < buf) { errno = ERANGE; return 0; }
    p[0] = '/'; memcpy(p + 1, dd->d_name, len);
  }
  if (dd != &__droot) return strcpy(buf, ".");
  return memmove(buf, p, size - (p - buf));
}

int chdir(const char *path) {
  /* llvm::sys::fs::set_current_path */
  struct dd *dd = path[0] == '/' ? &__droot : __dcwd;
  int rc = __dlocate(&dd, path, 0);
  path += rc; if (rc < 0) { errno = -rc; return -1; }

  if (path[0] == 0) {
    if (dd == __dcwd) return 0;
    if (cwdfd != -1) {
      __dcwd->d_fd = -1;
      (void)__wasi_fd_close(cwdfd);
      cwdfd = -1;
    }
    __dcwd = dd; return 0;
  }

  /* create new dd, might end up in tarpit */
  int dirfd = dd->d_fd;
  if ((rc = __dlocate(&dd, path, 1)) < 0) {
    errno = -rc; rc = -1; goto gcdd;
  }
  if (dtarpit.d_next) {
    dremove(&dtarpit.d_next);
    errno = EPERM; rc = -1; goto gcdd;
  }

  /* open dir */
  __wasi_fd_t newfd;
  if (__wasi_syscall_ret(__wasi_path_open(
        dirfd, __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW,
        path, strlen(path),
        __WASI_OFLAGS_DIRECTORY, -1, -1, 0, &newfd))) {
    rc = -1; goto gcdd;
  }
  dd->d_fd = newfd; rc = 0;

  /* take care of old cwdfd */
  if (cwdfd != -1) {
    __dcwd->d_fd = -1;
    (void)__wasi_fd_close(cwdfd);
  }
  cwdfd = newfd;
  __dcwd = dd;

gcdd:
  if (__dgccounter > __DGCTHRESHOLD) {
    __dgccounter = 0;
    __dgcmark++;
    __dgc(&__droot.d_next);
    __dgc(&dcwdhack.d_next);
  }
  return rc;
}

static int mode(__wasi_filetype_t i) {
  static const int m[] = {
    [__WASI_FILETYPE_BLOCK_DEVICE] = S_IFBLK,
    [__WASI_FILETYPE_CHARACTER_DEVICE] = S_IFCHR,
    [__WASI_FILETYPE_DIRECTORY] = S_IFDIR,
    [__WASI_FILETYPE_REGULAR_FILE] = S_IFREG,
    [__WASI_FILETYPE_SOCKET_DGRAM] = S_IFSOCK,
    [__WASI_FILETYPE_SOCKET_STREAM] = S_IFSOCK,
    [__WASI_FILETYPE_SYMBOLIC_LINK] = S_IFLNK,
  };
  return i >= 0 && i < sizeof(m)/sizeof(m[1]) ? m[i] : 0;
}

static struct timespec ts(__wasi_timestamp_t ts) {
  const __wasi_timestamp_t nsinsec = 10e9;
  struct timespec res = { .tv_sec = ts / nsinsec, .tv_nsec = ts % nsinsec };
  return res;
}

static void stat_from_wasi(
  struct stat *statbuf, const __wasi_filestat_t *stat
) {
  statbuf->st_dev = stat->dev;
  statbuf->st_ino = stat->ino;
  statbuf->st_mode = 0777|mode(stat->filetype);
  statbuf->st_nlink = stat->nlink;
  statbuf->st_uid = 0;
  statbuf->st_gid = 0;
  statbuf->st_rdev = 0;
  statbuf->st_size = stat->size;
  statbuf->st_blksize = 4096;
  statbuf->st_blocks = (stat->size + 4095) >> 11;
  statbuf->st_atim = ts(stat->atim);
  statbuf->st_mtim = ts(stat->mtim);
  statbuf->st_ctim = ts(stat->ctim);
}

int fstat(int fd, struct stat *statbuf) {
  /* realpath */
  /* llvm::sys::fs::status */
  /* llvm::raw_fd_ostream::preferred_buffer_size */
  __wasi_filestat_t stat;
  __wasi_errno_t err = __wasi_fd_filestat_get(fd, &stat);
  if (__wasi_syscall_ret(err)) {
    return -1;
  }
  stat_from_wasi(statbuf, &stat);
  return 0;
}

DIR *opendir(const char *name) {
  nyi("opendir");
}

int closedir(DIR *dirp) {
  nyi("closedir");
}

struct dirent *readdir(DIR *dirp) {
  /* llvm::sys::fs::detail::directory_iterator_increment */
  nyi("readdir");
}

int lstat(const char *path, struct stat *statbuf) {
  /* llvm::sys::fs::remove */
  struct dd *dd = path[0] == '/' ? &__droot : __dcwd;
  int rc = __dlocate(&dd, path, 0);
  path += rc; if (rc < 0) { errno = -rc; return -1; }
  __wasi_filestat_t stat;
  if (__wasi_syscall_ret(__wasi_path_filestat_get(
    dd->d_fd, 0, path, strlen(path), &stat
  ))) return -1;
  stat_from_wasi(statbuf, &stat);
  return 0;
}

int stat(const char *path, struct stat *statbuf) {
  /* llvm::sys::fs::remove */
  /* llvm::sys::fs::status */
  struct dd *dd = path[0] == '/' ? &__droot : __dcwd;
  int rc = __dlocate(&dd, path, 0);
  path += rc; if (rc < 0) { errno = -rc; return -1; }
  __wasi_filestat_t stat;
  if (__wasi_syscall_ret(__wasi_path_filestat_get(
    dd->d_fd, __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW, path, strlen(path), &stat
  ))) return -1;
  stat_from_wasi(statbuf, &stat);
  return 0;
}

ssize_t pread(int fd, void *buf, size_t count, off_t offset) {
  /* llvm::sys::fs::readNativeFileSlice */
  __wasi_iovec_t v[1] = {{(uint8_t *)buf, count}};
  __wasi_size_t sz;
  __wasi_errno_t err = __wasi_fd_pread(fd, v, 1, offset, &sz);
  if (__wasi_syscall_ret(err)) {
    return -1;
  }
  return sz;
}

ssize_t read(int fd, void *buf, size_t count) {
  /* llvm::sys::fs::readNativeFile */
  /* llvm::sys::Process::GetRandomNumber */
  __wasi_iovec_t v[1] = {{(uint8_t *)buf, count}};
  __wasi_size_t sz;
  __wasi_errno_t err = __wasi_fd_read(fd, v, 1, &sz);
  if (__wasi_syscall_ret(err)) {
    return -1;
  }
  return sz;
}

ssize_t readlink(const char *pathname, char *buf, size_t bufsiz) {
  /* realpath */
  /* llvm::sys::fs::openFileForRead */
  nyi("readlink");
}

int unlink(const char *path) {
  /* llvm::sys::RunInterruptHandlers */
  struct dd *dd = path[0] == '/' ? &__droot : __dcwd;
  int rc = __dlocate(&dd, path, 0);
  path += rc; if (rc < 0) { errno = -rc; return -1; }
  return __wasi_syscall_ret(__wasi_path_unlink_file(
    dd->d_fd, path, strlen(path)
  ));
}

int remove(const char *pathname) {
  /* llvm::sys::fs::remove, only regular files */
  return unlink(pathname);
}

int open(const char* path, int flags, ...) {
  struct dd *dd = path[0] == '/' ? &__droot : __dcwd;
  int rc = __dlocate(&dd, path, 0);
  path += rc; if (rc < 0) { errno = -rc; return -1; }
  __wasi_fd_t fd;
  __wasi_oflags_t oflags = 0;
  if (flags&O_CREAT) oflags = __WASI_OFLAGS_CREAT;
  if (flags&O_DIRECTORY) oflags |= __WASI_OFLAGS_DIRECTORY;
  if (flags&O_EXCL) oflags |= __WASI_OFLAGS_EXCL;
  if (flags&O_TRUNC) oflags |= __WASI_OFLAGS_TRUNC;
  __wasi_rights_t rights = -1;
  switch (flags&O_ACCMODE) {
  case O_RDONLY: rights = ~__WASI_RIGHTS_FD_WRITE; break;
  case O_WRONLY: rights = ~__WASI_RIGHTS_FD_READ; break;
  case O_RDWR: rights = -1;
  }
  __wasi_fdflags_t fdflags = 0;
  if (flags&O_APPEND) fdflags = __WASI_FDFLAGS_APPEND;
  int err = __wasi_path_open(
    dd->d_fd, __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW,
    path, strlen(path), oflags, rights, rights, fdflags, &fd
  );
  if (__wasi_syscall_ret(err)) {
    return -1;
  }
  return fd;
}

__attribute__((__constructor__)) static void init() {
  static const char oom[] = "out of memory";
  const char *cwd = getenv("PWD");
  if (!cwd) __dcwd = &dcwdhack;
  else if (__dlocate(&__dcwd, cwd, 1) < 0) fatal(oom);
  char *buf = 0; size_t bufsize = 0;
  __wasi_prestat_t st;
  for (int fd = 3;
       __wasi_fd_prestat_get(fd, &st) == __WASI_ERRNO_SUCCESS; ++fd) {
    if (st.pr_type != __WASI_PREOPENTYPE_DIR) continue;
    if (bufsize <= st.u.dir.pr_name_len) {
      bufsize = st.u.dir.pr_name_len + 1;
      if (!(buf = realloc(buf, bufsize))) fatal(oom);
    }
    (void)__wasi_fd_prestat_dir_name(fd, (uint8_t *)buf, bufsize);
    struct dd *dd = buf[0] == '/' ? &__droot : __dcwd;
    if (__dlocate(&dd, buf, 1) < 0) fatal(oom);
    dd->d_fd = fd;
  }
  free(buf);
  /* in case a dir was mapped into tarpit, e.g. ../foobar */
  dremove(&dtarpit.d_next);
  if (!cwd || __dcwd->d_fd >= 0) return;
  struct dd *dd = &__droot;
  int rc = __dlocate(&dd, cwd, 0);
  cwd += rc; if (rc < 0) return;
  __wasi_fd_t fd;
  if (__wasi_path_open(dd->d_fd, __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW,
                       cwd, strlen(cwd),
                       __WASI_OFLAGS_DIRECTORY, -1, -1, 0, &fd)
      == __WASI_ERRNO_SUCCESS) __dcwd->d_fd = cwdfd = fd;
  /* if initial cwd failed to open this is probably non-fatal:
   * the program might NOT need access to cwd */
}
