; RUN: llc -mtriple=x86_64-- < %s | FileCheck %s

declare void @dispatch_next(i32, i32, i32, i32)
declare void @callout(i32)
declare void @sink(i8*)

define interpcc void @t1(i32, i32, i32, i32) {
; simple forwarding - arguments on stack
; note: a comment preceeding the basic block included in the check to
; ensure there're no instructions apart from jmp in the bb
; CHECK-LABEL: t1
; CHECK: # %bb.
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i32 %2, i32 %3)
  ret void
}

define interpcc void @t2(i32 "hwreg"="rbx", i32 "hwreg"="rbp", i32 "hwreg"="r12", i32 "hwreg"="r13") {
; simple forwarding - arguments in registers
; CHECK-LABEL: t2
; CHECK: # %bb.
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 "hwreg"="rbx" %0, i32 "hwreg"="rbp" %1,
                                             i32 "hwreg"="r12" %2, i32 "hwreg"="r13" %3)
  ret void
}

define interpcc void @t3(i32, i32, i32, i32) {
; shuffling arguments - arguments on stack
; CHECK-LABEL: t3
; CHECK: # %bb.
; CHECK-NEXT: movl (%rsp), [[R1:%[a-z0-9]+]]
; CHECK-NEXT: movl 8(%rsp), [[R2:%[a-z0-9]+]]
; CHECK-NEXT: movl [[R2]], (%rsp)
; CHECK-NEXT: movl [[R1]], 8(%rsp)
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 %1, i32 %0, i32 %2, i32 %3)
  ret void
}

define interpcc void @t4(i32 "hwreg"="rbx", i32 "hwreg"="rbp", i32 "hwreg"="r12", i32 "hwreg"="r13") {
; shuffling arguments - arguments in registers
; CHECK-LABEL: t4
; CHECK: # %bb.
; CHECK-NEXT: movq %rbx, [[R:%[a-z0-9]+]]
; CHECK-NEXT: movq %rbp, %rbx
; CHECK-NEXT: movq [[R]], %rbp
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 "hwreg"="rbx" %1, i32 "hwreg"="rbp" %0,
                                             i32 "hwreg"="r12" %2, i32 "hwreg"="r13" %3)
  ret void
}

define interpcc void @t5(i32, i32, i32, i32) "local-area-size"="16" {
; shuffling arguments - arguments on stack + local-area-size
; CHECK-LABEL: t5
; CHECK: # %bb.
; CHECK-NEXT: movl 16(%rsp), [[R1:%[a-z0-9]+]]
; CHECK-NEXT: movl 24(%rsp), [[R2:%[a-z0-9]+]]
; CHECK-NEXT: movl [[R2]], 16(%rsp)
; CHECK-NEXT: movl [[R1]], 24(%rsp)
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 %1, i32 %0, i32 %2, i32 %3)
  ret void
}

define interpcc void @t6(i32 "hwreg"="rbx", i32 "hwreg"="rbp", i32 "hwreg"="r12", i32 "hwreg"="r13") {
; callout - must recognize that the stack is properly aligned for a call; no spills
; CHECK-LABEL: t6
; CHECK: # %bb.
; CHECK-NEXT: movl %ebx, %edi
; CHECK-NEXT: callq {{_?}}callout
; CHECK-NEXT: jmp {{_?}}dispatch_next

  call void @callout(i32 %0)

  musttail call interpcc void @dispatch_next(i32 "hwreg"="rbx" %0, i32 "hwreg"="rbp" %1,
                                             i32 "hwreg"="r12" %2, i32 "hwreg"="r13" %3)
  ret void
}

define interpcc void @t7(i32, i32, i32, i32) "local-area-size"="32" {
; locals together with parameters on stack
; CHECK-LABEL: t7
; CHECK: # %bb.
; CHECK-NEXT: movl 32(%rsp), %edi
; CHECK-NEXT: callq {{_?}}callout
; CHECK-NEXT: leaq 8(%rsp), %rdi
; CHECK-NEXT: callq {{_?}}sink
; CHECK-NEXT: jmp {{_?}}dispatch_next

  call void @callout(i32 %0)

  %p = alloca i8, i32 8
  call void @sink(i8* %p)

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i32 %2, i32 %3)
  ret void
}
