; RUN: not llc -mtriple=x86_64-- < %s 2> %t1
; RUN: not llc -mtriple=i686-- < %s 2> %t2
; RUN: FileCheck %s --check-prefix X86_64 < %t1
; RUN: FileCheck %s --check-prefix X86 < %t2

declare barebonecc void @dispatch_next_i32(i32)
declare barebonecc void @dispatch_next_i32_i32(i32, i32)
declare barebonecc void @dispatch_next_i64(i64)

define barebonecc void @t1(i32) "hwreg"="nosuchreg" {
; X86: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid: nosuchreg
; X86: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next_i32: nosuchreg
; X86_64: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid: nosuchreg
; X86_64: error: in function t1: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next_i32: nosuchreg

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="nosuchreg"
  ret void
}

define barebonecc void @t3(i32) "hwreg"="rax" {
; X86: error: in function t3: register requested by 'hwreg' attribute is unknown or invalid: rax
; X86-NEXT: error: in function t3: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next_i32: rax

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="rax"
  ret void
}

define barebonecc void @t4(i32) "hwreg"="esp" {
; esp/rsp is not available
; X86: error: in function t4: register requested by 'hwreg' attribute is unknown or invalid: esp
; X86_64: error: in function t4: register requested by 'hwreg' attribute is unknown or invalid: esp

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="esp"
  ret void
}

define barebonecc void @t5(i32) "hwreg"="rsp" {
; esp/rsp is not available
; X86: error: in function t5: register requested by 'hwreg' attribute is unknown or invalid: rsp
; X86_64: error: in function t5: register requested by 'hwreg' attribute is unknown or invalid: rsp

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="rsp"
  ret void
}

define barebonecc void @t6(i32) "hwreg"="r10d" {
; X86: error: in function t6: register requested by 'hwreg' attribute is unknown or invalid: r10d
; X86_64: error: in function t6: register requested by 'hwreg' attribute is unknown or invalid: r10d

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="r10d"
  ret void
}

define barebonecc void @t7(i32) "hwreg"="rax" {
; X86: error: in function t7: register requested by 'hwreg' attribute is unknown or invalid: rax

  musttail call barebonecc void @dispatch_next_i32(i32 %0) "hwreg"="rax"
  ret void
}

define barebonecc void @t8(i32, i32) "hwreg"="eax,eax" {
; eax requested twice
; X86: error: in function t8: failed to allocate register requested by 'hwreg' attribute: eax
; X86: error: in function t8: failed to allocate register requested by 'hwreg' attribute in a call to dispatch_next_i32_i32: eax
; X86_64: error: in function t8: register requested by 'hwreg' attribute is unknown or invalid: eax
; X86_64: error: in function t8: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next_i32_i32: eax

  musttail call barebonecc void @dispatch_next_i32_i32(i32 %0, i32 %1) "hwreg"="eax,eax"
  ret void
}

define barebonecc void @t9(i64) "hwreg"="eax" {
; x86 passes 64-bit arguments in two registers, incompatible with hwreg
; X86: error: in function t9: argument of type i64 is passed in multiple registers, incompatible with 'hwreg'
; X86: error: in function t9: argument of type i64 is passed in multiple registers, incompatible with 'hwreg' in a call to dispatch_next_i64
; X86_64: error: in function t9: register requested by 'hwreg' attribute is unknown or invalid: eax
; X86_64: error: in function t9: register requested by 'hwreg' attribute is unknown or invalid in a call to dispatch_next_i64: eax

  musttail call barebonecc void @dispatch_next_i64(i64 %0) "hwreg"="eax"
  ret void
}
