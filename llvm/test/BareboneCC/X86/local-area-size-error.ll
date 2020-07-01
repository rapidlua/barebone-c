; RUN: not llc -mtriple=x86_64-- < %s 2> %t1
; RUN: not llc -mtriple=i686-- < %s 2> %t2
; RUN: FileCheck %s --check-prefix X86_64 < %t1
; RUN: FileCheck %s --check-prefix X86 < %t2

declare barebonecc void @dispatch_next()
declare void @sink(i8*)

define barebonecc void @t1() "local-area-size"="x" {
; X86: error: in function t1: bad value in 'local-area-size' attribute: x
; X86_64: error: in function t1: bad value in 'local-area-size' attribute: x

  musttail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t2() "local-area-size"="-1" {
; X86: error: in function t2: bad value in 'local-area-size' attribute: -1
; X86_64: error: in function t2: bad value in 'local-area-size' attribute: -1

  musttail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t3() "local-area-size"="1" {
; X86: error: in function t3: bad value in 'local-area-size' attribute: 1
; X86-NEXT: note: in function t3: the value in 'local-area-size' attribute must be a multiple of 4
; X86_64: error: in function t3: bad value in 'local-area-size' attribute: 1
; X86_64-NEXT: note: in function t3: the value in 'local-area-size' attribute must be a multiple of 16

  musttail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t4() {
; X86: error: in function t4: stack size limit of 0 exceeded: 4 used
; X86_64: error: in function t4: stack size limit of 0 exceeded: 16 used

  %p = alloca i8, i32 1
  call void @sink(i8* %p)
  musttail call barebonecc void @dispatch_next()
  ret void
}
