/* The function is invoked when Emscripten runtime grows memory.
 * It must be present but doesn't have to do anything. */
#include <stddef.h>
void emscripten_notify_memory_growth(size_t memory_index) {
}
