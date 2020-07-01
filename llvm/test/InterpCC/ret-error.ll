; RUN: not llc -mtriple=i686-- < %s 2> %t1
; RUN: FileCheck %s < %t1

define interpcc void @t1() {
; CHECK: error: in function t1: must terminate by tail-calling another interpcc function

  ret void
}
