# barebone-c
This project extends Clang with **barebone functions**, eliminating the need for hand-crafted
assembly in high-performance interpreters.

This [document](http://lua-users.org/lists/lua-l/2011-02/msg00742.html)
by Mike Pall outlines advantages of implementing an interpretor in hand-crafted assembly.
LuaJIT, Google's V8 and Apple's JavaScriptCore are prime examples of this approach.

<hr>

Barebone function gets parameters in explicitly named registers (`r15` and `rbx` in the following example):

```c
__attribute__((barebone(hwreg="r15,rbx")))
void Fn(void *p1, void *p2);
```

A barebone function call is essentially a `goto`. It doesn't bear the normal function call overhead.
It is advised to keep barebone functions small — i.e. each opcode handler should be in a separate
function.

Barebone function doesn't record the return address. It doesn't setup a stack frame, hence there is
no prologue or epilogue. A function must terminate by tail-calling another barebone function.
Barebone function calls are only allowed in barebone functions in a tail-call position.
Restrictions on barebone functions are enforced after inlining happens.

A barebone function can freely call regular functions.

Explicit register assignment only applies to function parameters/call arguments.  It doesn't mean that
a register is put aside; the optimizer is free to repurpose the register in a function body
as it sees fit.  For efficiency it is recommended to pass the most frequently accessed fields in the
interpreter state as function parameters.  Assuming that the register allocator does a decent job,
this will ensure that the most frequently accessed fields stay in registers.

Picking callee-saved registers for interpreter state will reduce the number of spills.

## The stack

Barebone function doesn't alter the stack pointer.  Therefore it is possible to put
some state in the stack and access it at a known offset relative to the stack pointer.
Other creative hacks are possible: e.g. allocating stack frames of the interpreted
language on the host stack.

Barebone attribute accepts `local_area_size=N` keyword argument.

It marks the topmost `N` bytes on the stack as a scratch space.  A function may use it for
spilling registers and for placing outgoing arguments in regular function calls.
Local area is also used for placing local variables in `-O0` compilation mode.

## Example usage

Below you will find a simple interpretor with the instruction encoding resembling Lua.
The sample includes instruction decoding and `JMP` opcode handler.

```c
#include <stdint.h>

struct Dispatch;

// Bytecode instruction: op(code) + args
struct Inst {
  uint32_t op: 8;
  uint32_t b:  8;
  uint32_t ac: 16;
};

typedef __attribute__((barebone(hwreg="r15,rbx,rax,rcx")))
void (*OpHandler) (const struct Dispatch *dispatch,
                   const struct Inst *ip,
                   uintptr_t b, uintptr_t ac);

// Dispatch table: a function pointer per opcode
struct Dispatch {
  OpHandler h[1];
};

// Instruction decode + dispatch.
__attribute__((barebone(hwreg="r15,rbx"),noinline))
void InstNext(const struct Dispatch *dispatch,
              const struct Inst *ip) {

  dispatch->h[ip->op](dispatch, ip + 1, ip->b, ip->ac);
}

// JMP opcode
__attribute__((barebone(hwreg="r15,rbx,rax,rcx")))
void OpJmp (const struct Dispatch *dispatch,
            const struct Inst *ip,
            uintptr_t b, uintptr_t ac) {

  InstNext(dispatch, ip + (int16_t)ac);
}
```

Compiler output at `-O3`:

```asm
	.globl	_InstNext                       ## -- Begin function InstNext
	.p2align	4, 0x90
_InstNext:                              ## @InstNext
## %bb.0:                               ## %entry
	movl	(%rbx), %ecx
	movzbl	%cl, %eax
	movq	(%r15,%rax,8), %rdx
	addq	$4, %rbx
	movzbl	%ch, %eax
	shrq	$16, %rcx
	jmpq	*%rdx                           ## TAILCALL
                                        ## -- End function
	.globl	_OpJmp                          ## -- Begin function OpJmp
	.p2align	4, 0x90
_OpJmp:                                 ## @OpJmp
## %bb.0:                               ## %entry
	movswq	%cx, %rax
	leaq	(%rbx,%rax,4), %rbx
	jmp	_InstNext                       ## TAILCALL
                                        ## -- End function
```
