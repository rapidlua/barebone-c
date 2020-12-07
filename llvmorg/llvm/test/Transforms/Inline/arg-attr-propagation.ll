; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature
; RUN: opt -inline -S < %s | FileCheck --check-prefixes=CHECK,NO_ASSUME %s
; RUN: opt -inline -S --enable-knowledge-retention < %s | FileCheck %s --check-prefixes=CHECK,USE_ASSUME

; The callee guarantees that the pointer argument is nonnull and dereferenceable.
; That information should transfer to the caller.

define i32 @callee(i32* dereferenceable(32) %t1) {
; CHECK-LABEL: define {{[^@]+}}@callee
; CHECK-SAME: (i32* dereferenceable(32) [[T1:%.*]])
; CHECK-NEXT:    [[T2:%.*]] = load i32, i32* [[T1]]
; CHECK-NEXT:    ret i32 [[T2]]
;
  %t2 = load i32, i32* %t1
  ret i32 %t2
}

; FIXME: All dereferenceability information is lost.
; The caller argument could be known nonnull and dereferenceable(32).

define i32 @caller1(i32* %t1) {
; NO_ASSUME-LABEL: define {{[^@]+}}@caller1
; NO_ASSUME-SAME: (i32* [[T1:%.*]])
; NO_ASSUME-NEXT:    [[T2_I:%.*]] = load i32, i32* [[T1]]
; NO_ASSUME-NEXT:    ret i32 [[T2_I]]
;
; USE_ASSUME-LABEL: define {{[^@]+}}@caller1
; USE_ASSUME-SAME: (i32* [[T1:%.*]])
; USE_ASSUME-NEXT:    call void @llvm.assume(i1 true) [ "dereferenceable"(i32* [[T1]], i64 32) ]
; USE_ASSUME-NEXT:    [[T2_I:%.*]] = load i32, i32* [[T1]]
; USE_ASSUME-NEXT:    ret i32 [[T2_I]]
;
  %t2 = tail call i32 @callee(i32* dereferenceable(32) %t1)
  ret i32 %t2
}

; The caller argument is nonnull, but that can be explicit.
; The dereferenceable amount could be increased.

define i32 @caller2(i32* dereferenceable(31) %t1) {
; NO_ASSUME-LABEL: define {{[^@]+}}@caller2
; NO_ASSUME-SAME: (i32* dereferenceable(31) [[T1:%.*]])
; NO_ASSUME-NEXT:    [[T2_I:%.*]] = load i32, i32* [[T1]]
; NO_ASSUME-NEXT:    ret i32 [[T2_I]]
;
; USE_ASSUME-LABEL: define {{[^@]+}}@caller2
; USE_ASSUME-SAME: (i32* dereferenceable(31) [[T1:%.*]])
; USE_ASSUME-NEXT:    call void @llvm.assume(i1 true) [ "dereferenceable"(i32* [[T1]], i64 32) ]
; USE_ASSUME-NEXT:    [[T2_I:%.*]] = load i32, i32* [[T1]]
; USE_ASSUME-NEXT:    ret i32 [[T2_I]]
;
  %t2 = tail call i32 @callee(i32* dereferenceable(32) %t1)
  ret i32 %t2
}

; The caller argument is nonnull, but that can be explicit.
; Make sure that we don't propagate a smaller dereferenceable amount.

define i32 @caller3(i32* dereferenceable(33) %t1) {
; CHECK-LABEL: define {{[^@]+}}@caller3
; CHECK-SAME: (i32* dereferenceable(33) [[T1:%.*]])
; CHECK-NEXT:    [[T2_I:%.*]] = load i32, i32* [[T1]]
; CHECK-NEXT:    ret i32 [[T2_I]]
;
  %t2 = tail call i32 @callee(i32* dereferenceable(32) %t1)
  ret i32 %t2
}

