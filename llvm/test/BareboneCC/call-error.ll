; RUN: not llc -mtriple=i686-- < %s 2> %t1
; RUN: FileCheck %s < %t1

declare void @dispatch_next()

define void @t1() {
; CHECK: error: in function t1: function dispatch_next must be tail-called, use musttail marker

  call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t2() {
; CHECK: error: in function t2: function dispatch_next must be tail-called, use musttail marker

  call barebonecc void @dispatch_next()
  ret void
}

define void @t3() {
; CHECK: error: in function t3: function dispatch_next must be tail-called, use musttail marker

  tail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t4() {
; CHECK: error: in function t4: function dispatch_next must be tail-called, use musttail marker

  tail call barebonecc void @dispatch_next()
  ret void
}
