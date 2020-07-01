; RUN: not llc -mtriple=i686-- < %s 2> %t1
; RUN: FileCheck %s < %t1

define barebonecc void @t1() {
; CHECK: error: in function t1: must terminate by tail-calling another barebonecc function

  ret void
}
