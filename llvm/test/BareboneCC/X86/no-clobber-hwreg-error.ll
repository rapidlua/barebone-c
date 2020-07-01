; RUN: not llc -mtriple=x86_64-- < %s 2> %t1
; RUN: not llc -mtriple=i686-- < %s 2> %t2
; RUN: FileCheck %s --check-prefix X86_64 < %t1
; RUN: FileCheck %s --check-prefix X86 < %t2

declare barebonecc void @dispatch_next()

define barebonecc void @t1() "no-clobber-hwreg"="nosuchreg" {
; X86: error: in function t1: unknown register in 'no-clobber-hwreg' attribute: nosuchreg
; X86_64: error: in function t1: unknown register in 'no-clobber-hwreg' attribute: nosuchreg

  musttail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t2() "no-clobber-hwreg"="eax,nosuchreg" {
; X86: error: in function t2: unknown register in 'no-clobber-hwreg' attribute: nosuchreg
; X86_64: error: in function t2: unknown register in 'no-clobber-hwreg' attribute: eax

  musttail call barebonecc void @dispatch_next()
  ret void
}

define barebonecc void @t3() "no-clobber-hwreg"="rax" {
; X86: error: in function t3: unknown register in 'no-clobber-hwreg' attribute: rax

  musttail call barebonecc void @dispatch_next()
  ret void
}
