/* dd - a directory descriptor;
 * descriptors form a slist, node's children found by scanning the list
 * starting after the node itself and checking d_parent */
struct dd {
  struct dd *d_next;
  struct dd *d_parent;
  int d_fd;
  unsigned char d_gcmark;
  char d_name[3];
};

int __dlocate(struct dd **dd, const char *path, int create);
void __dgc(struct dd **p);

extern struct dd __droot, *__dcwd;
extern unsigned char __dgcmark;
extern int __dgccounter;
enum { __DGCTHRESHOLD = 20 };
