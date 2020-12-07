; RUN: not llc -mtriple=i686-- < %s 2> %t1
; RUN: FileCheck %s < %t1

declare barebonecc void @dispatch_next(i32)
declare void @consume(i8 *)

define barebonecc void @t1(i32) "frame-pointer"="all" {
; explicitly requested frame pointer
; CHECK: error: in function t1: frame pointer not allowed

  musttail call barebonecc void @dispatch_next(i32 %0)
  ret void
}

define barebonecc void @t2(i32) "stackrealign"="64" {
; stack realignment implicitly enables the frame pointer
; CHECK: error: in function t2: frame pointer not allowed

  musttail call barebonecc void @dispatch_next(i32 %0)
  ret void
}

define barebonecc void @t3(i32) {
; alloca implicitly enables the frame pointer
; CHECK: error: in function t3: frame pointer not allowed

  %buf = alloca i8, i32 %0
  call void @consume(i8* %buf)
  musttail call barebonecc void @dispatch_next(i32 %0)
  ret void
}
