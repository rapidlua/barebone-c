# barebone-c

LuaJIT and JavaScriptCore (from WebKit) implement their interpreters in hand-crafted assembly.
Both projects have performance as the major goal.
Optimising compilers might be catching up, but a determined human being can still beat them.

Someone once said: *If there's an optimisation oportunity a compiler misses,
you'd better use your time to improve the compiler, rather than hand-crafting assembly*.
If we consider a compiler job as an optimisation problem, it's quite apparent that
the search space is enourmous. A typical compiler has many optimisation passes,
each of them designed to improve code in certain ways. A compiler pass may even
improve some aspects while simultaneously introducing performance regressions in
other areas, which are hopefully fixed by later passes. A compiler reliably
reaches a local maxima. It doesn't produce the best solution possible.

Another challenge is that compiler heuristics must be general enough to be
benificial for a large variety of programs. Bytecode interpreters
might be a special case after all.

## Why not hand-crafted assembly

Coding in assembly is slow and error-prone. Implementation has to be
replicated for every supported architecture. Don't forget that a
programming language is a moving target — there will be new versions
unless the language is dead. The implementation will inevitably require changes.
It might be less challenging when the language tries hard to remain
backwards-compatible. However Lua is known for introducing breaking
changes. Does it mean that not only a separate implementation is required
for every supported architecture, but also for every language version as well?

Very few projects have sufficient resources to pull it off.

## Enter `barebone-c`

```c
__attribute__((barebone("hwreg=rbx,rsi,rdi,rcx,rax")))
void OP_Add(const void *dispatch, const uint32_t *pc, double *base, uintptr_t b, uintptr_t ac);
```
