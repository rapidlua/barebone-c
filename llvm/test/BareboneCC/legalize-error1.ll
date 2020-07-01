; RUN: not opt -barebonecc-legalize < %s 2> %t1
; RUN: FileCheck %s < %t1

declare void @foo(i32)
declare void @bar(i32)

define barebonecc void @test(i32) {
; CHECK: error: in function test: a call to function foo must be in tail-call position
  call barebonecc void @foo(i32 %0)
  call barebonecc void @bar(i32 %0)
  ret void
}
