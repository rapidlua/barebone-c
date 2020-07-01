; RUN: llc -mtriple=x86_64-- < %s | FileCheck %s

declare void @dispatch_next(i32, i32, i32, i32)
declare void @callout(i32)
declare void @sink(i8*)

define barebonecc void @t1(i32, i32, i32, i32) "hwreg"="rbx,rbp,r12,r13" {
; simple forwarding
; CHECK-LABEL: t1
; CHECK: # %bb.
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call barebonecc void @dispatch_next(i32 %0, i32 %1, i32 %2, i32 %3) "hwreg"="rbx,rbp,r12,r13"
  ret void
}

define barebonecc void @t2(i32, i32, i32, i32) "hwreg"="rbx,rbp,r12,r13" {
; shuffling arguments
; CHECK-LABEL: t2
; CHECK: # %bb.
; CHECK-NEXT: movq %rbx, [[R:%[a-z0-9]+]]
; CHECK-NEXT: movq %rbp, %rbx
; CHECK-NEXT: movq [[R]], %rbp
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call barebonecc void @dispatch_next(i32 %1, i32 %0, i32 %2, i32 %3) "hwreg"="rbx,rbp,r12,r13"
  ret void
}

define barebonecc void @t3(i32, i32, i32, i32) "hwreg"="rbx,rbp,r12,r13" {
; callout - must recognize that the stack is properly aligned for a call; no spills
; CHECK-LABEL: t3
; CHECK: # %bb.
; CHECK-NEXT: movl %ebx, %edi
; CHECK-NEXT: callq {{_?}}callout
; CHECK-NEXT: jmp {{_?}}dispatch_next

  call void @callout(i32 %0)

  musttail call barebonecc void @dispatch_next(i32 %0, i32 %1, i32 %2, i32 %3) "hwreg"="rbx,rbp,r12,r13"
  ret void
}

define barebonecc void @t4(i32, i32, i32, i32) "hwreg"="rbx,rbp,r12,r13" "local-area-size"="32" {
; locals
; CHECK-LABEL: t4
; CHECK: # %bb.
; CHECK-NEXT: movl %ebx, %edi
; CHECK-NEXT: callq {{_?}}callout
; CHECK-NEXT: leaq 8(%rsp), %rdi
; CHECK-NEXT: callq {{_?}}sink
; CHECK-NEXT: jmp {{_?}}dispatch_next

  call void @callout(i32 %0)

  %p = alloca i8, i32 8
  call void @sink(i8* %p)

  musttail call barebonecc void @dispatch_next(i32 %0, i32 %1, i32 %2, i32 %3) "hwreg"="rbx,rbp,r12,r13"
  ret void
}
