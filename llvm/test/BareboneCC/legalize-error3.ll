; RUN: not opt -barebonecc-legalize < %s 2> %t1
; RUN: FileCheck %s < %t1

declare void @foo(i32)

define barebonecc void @test(i32) {
; CHECK: error: in function test: must terminate by tail-calling another barebonecc function
  call void @foo(i32 %0)
  ret void
}
