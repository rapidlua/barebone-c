; RUN: not opt -barebonecc-legalize < %s 2> %t1
; RUN: FileCheck %s < %t1

declare void @foo(i32)

define void @test(i32) {
; CHECK: error: in function test: a call to function foo is only allowed in barebonecc functions
  call barebonecc void @foo(i32 %0)
  ret void
}
