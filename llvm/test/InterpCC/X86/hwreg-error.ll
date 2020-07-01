; RUN: not llc -mtriple=x86_64-- < %s 2> %t1
; RUN: not llc -mtriple=i686-- < %s 2> %t2
; RUN: FileCheck %s --check-prefix X86_64 < %t1
; RUN: FileCheck %s --check-prefix X86 < %t2

declare interpcc void @dispatch_next(i32, i32, i64)

define interpcc void @t1(i32 "hwreg"="nosuchreg", i32, i64) {
; X86: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid: nosuchreg
; X86_64: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid: nosuchreg

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t2(i32, i32, i64) {
; X86: error: in function t2: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next: nosuchreg
; X86_64: error: in function t2: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next: nosuchreg

  musttail call interpcc void @dispatch_next(i32 "hwreg"="nosuchreg" %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t3(i32 "hwreg"="rax", i32, i64) {
; mismatched types: i64 rax vs. i32
; X86: error: in function t3: register requested by 'hwreg' attribute is unknown or invalid: rax

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t3_1(i32 "hwreg"="esp", i32, i64) {
; esp/rsp is not available
; X86: error: in function t3_1: register requested by 'hwreg' attribute is unknown or invalid: esp
; X86_64: error: in function t3_1: register requested by 'hwreg' attribute is unknown or invalid: esp

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t3_2(i32, i32, i64 "hwreg"="rsp") {
; esp/rsp is not available
; X86: error: in function t3_2: register requested by 'hwreg' attribute is unknown or invalid: rsp
; X86_64: error: in function t3_2: register requested by 'hwreg' attribute is unknown or invalid: rsp

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t3_3(i32 "hwreg"="r10d", i32, i64) {
; X86: error: in function t3_3: register requested by 'hwreg' attribute is unknown or invalid: r10d
; X86_64: error: in function t3_3: register requested by 'hwreg' attribute is unknown or invalid: r10d

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t4(i32, i32, i64) {
; X86: error: in function t4: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next: rax

  musttail call interpcc void @dispatch_next(i32 "hwreg"="rax" %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t5(i32 "hwreg"="eax", i32 "hwreg"="eax", i64) {
; eax requested twice
; X86: error: in function t5: failed to allocate register requested by 'hwreg' attribute: eax
; X86_64: error: in function t5: register requested by 'hwreg' attribute is unknown or invalid: eax

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @t6(i32, i32, i64) {
; eax requested twice
; X86: error: in function t6: failed to allocate register requested by 'hwreg' attribute in a call to dispatch_next: eax
; X86_64: error: in function t6: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next: eax

  musttail call interpcc void @dispatch_next(i32 "hwreg"="eax" %0, i32 "hwreg"="eax" %1, i64 %2)
  ret void
}

define interpcc void @t9(i32, i32, i64 "hwreg"="eax") {
; x86 passes 64-bit arguments in two registers, incompatible with hwreg
; X86: error: in function t9: argument of type i64 is passed in multiple registers, incompatible with 'hwreg'
; X86_64: error: in function t9: register requested by 'hwreg' attribute is unknown or invalid: eax

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 %2)
  ret void
}

define interpcc void @ta(i32, i32, i64) {
; x86 passes 64-bit arguments in two registers, incompatible with hwreg
; X86: error: in function ta: argument of type i64 is passed in multiple registers, incompatible with 'hwreg' in a call to dispatch_next
; X86_64: error: in function ta: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next: eax

  musttail call interpcc void @dispatch_next(i32 %0, i32 %1, i64 "hwreg"="eax" %2)
  ret void
}
