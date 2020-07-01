; RUN: opt -inline -barebonecc-legalize -S < %s | FileCheck %s
; RUN: opt -O0 -enable-barebonecc -S < %s | FileCheck %s
; RUN: opt -O1 -enable-barebonecc -S < %s | FileCheck %s

declare barebonecc void @dispatch_next(i32)

define private void @foo(i32) alwaysinline {
  call barebonecc void @dispatch_next(i32 %0) #0
  ret void
}

define barebonecc void @bar(i32) #0 {
; CHECK-LABEL: @bar(
; CHECK-NEXT:    musttail call barebonecc void @dispatch_next(i32 %0)
; CHECK-NEXT:    ret void
  call void @foo(i32 %0)
  ret void
}

attributes #0 = { "hwreg"="rax" "local-area-size"="32" }
