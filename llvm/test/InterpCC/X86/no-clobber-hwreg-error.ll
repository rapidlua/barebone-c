; RUN: not llc -mtriple=x86_64-- < %s 2> %t1
; RUN: not llc -mtriple=i686-- < %s 2> %t2
; RUN: FileCheck %s --check-prefix X86_64 < %t1
; RUN: FileCheck %s --check-prefix X86 < %t2

declare interpcc void @dispatch_next()

define interpcc void @t1() "no-clobber-hwreg"="nosuchreg" {
; X86: error: in function t1: unknown register in 'no-clobber-hwreg' attribute: nosuchreg
; X86_64: error: in function t1: unknown register in 'no-clobber-hwreg' attribute: nosuchreg

  musttail call interpcc void @dispatch_next()
  ret void
}

define interpcc void @t2() "no-clobber-hwreg"="eax,nosuchreg" {
; X86: error: in function t2: unknown register in 'no-clobber-hwreg' attribute: nosuchreg
; X86_64: error: in function t2: unknown register in 'no-clobber-hwreg' attribute: eax

  musttail call interpcc void @dispatch_next()
  ret void
}

define interpcc void @t3() "no-clobber-hwreg"="rax" {
; X86: error: in function t3: unknown register in 'no-clobber-hwreg' attribute: rax

  musttail call interpcc void @dispatch_next()
  ret void
}
