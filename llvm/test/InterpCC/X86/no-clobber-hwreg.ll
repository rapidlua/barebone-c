; RUN: llc -mtriple=x86_64-- < %s | FileCheck %s

declare void @dispatch_next(i32, i32)

define interpcc void @t1(i32 "hwreg"="r15", i32 "hwreg"="r14") "no-clobber-hwreg"="rax,rcx,rbx,rdx,rsi,rdi,rbp" {
; CHECK-LABEL: t1
; CHECK: movq %r15, %r8
; CHECK-NEXT: movq %r14, %r15
; CHECK-NEXT: movq %r8, %r14
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 "hwreg"="r15" %1, i32 "hwreg"="r14" %0)
  ret void
}

define interpcc void @t2(i32 "hwreg"="r15", i32 "hwreg"="r14") "no-clobber-hwreg"="rax,rcx,rbx,rdx,rsi,rdi,rbp,r8" {
; CHECK-LABEL: t2
; CHECK: movq %r15, %r9
; CHECK-NEXT: movq %r14, %r15
; CHECK-NEXT: movq %r9, %r14
; CHECK-NEXT: jmp {{_?}}dispatch_next

  musttail call interpcc void @dispatch_next(i32 "hwreg"="r15" %1, i32 "hwreg"="r14" %0)
  ret void
}
