; RUN: not llc -mtriple=i686-- < %s 2> %t1
; RUN: FileCheck %s < %t1

declare void @dispatch_next()
declare i32 @personality_dispatch_next(...)

define void @t1() personality i8* bitcast (i32 (...)* @personality_dispatch_next to i8*) {
; CHECK: error: in function t1: function dispatch_next must be tail-called, use musttail marker

  invoke barebonecc void @dispatch_next()
         to label %invoke.cont unwind label %lpad
invoke.cont:
  ret void
lpad:
  %exn = landingpad { i8*, i32 }
         filter [0 x i8*] zeroinitializer
  ret void
}
