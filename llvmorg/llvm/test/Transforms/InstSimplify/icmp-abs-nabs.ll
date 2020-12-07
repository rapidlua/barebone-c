; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instsimplify -S | FileCheck %s

; This is canonical form for this IR.

define i1 @abs_nsw_is_positive(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_positive(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sgt i32 %abs, -1
  ret i1 %r
}

; Test non-canonical predicate and non-canonical form of abs().

define i1 @abs_nsw_is_positive_sge(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_positive_sge(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sge i32 %abs, 0
  ret i1 %r
}

; This is a range-based analysis. Any negative constant works.

define i1 @abs_nsw_is_positive_reduced_range(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_positive_reduced_range(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sgt i32 %abs, -42
  ret i1 %r
}

; Negative test - we need 'nsw' in the abs().

define i1 @abs_is_positive_reduced_range(i32 %x) {
; CHECK-LABEL: @abs_is_positive_reduced_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 0
; CHECK-NEXT:    [[NEGX:%.*]] = sub i32 0, [[X]]
; CHECK-NEXT:    [[ABS:%.*]] = select i1 [[CMP]], i32 [[NEGX]], i32 [[X]]
; CHECK-NEXT:    [[R:%.*]] = icmp sgt i32 [[ABS]], 42
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sgt i32 %abs, 42
  ret i1 %r
}

; Negative test - range intersection is not subset.

define i1 @abs_nsw_is_positive_wrong_range(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_positive_wrong_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 0
; CHECK-NEXT:    [[NEGX:%.*]] = sub nsw i32 0, [[X]]
; CHECK-NEXT:    [[ABS:%.*]] = select i1 [[CMP]], i32 [[NEGX]], i32 [[X]]
; CHECK-NEXT:    [[R:%.*]] = icmp sgt i32 [[ABS]], 0
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sgt i32 %abs, 0
  ret i1 %r
}

; This is canonical form for this IR.

define i1 @abs_nsw_is_not_negative(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp slt i32 %abs, 0
  ret i1 %r
}

; Test non-canonical predicate and non-canonical form of abs().

define i1 @abs_nsw_is_not_negative_sle(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative_sle(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sle i32 %abs, -1
  ret i1 %r
}

; This is a range-based analysis. Any negative constant works.

define i1 @abs_nsw_is_not_negative_reduced_range(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative_reduced_range(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp slt i32 %abs, -24
  ret i1 %r
}

; Negative test - we need 'nsw' in the abs().

define i1 @abs_is_not_negative_reduced_range(i32 %x) {
; CHECK-LABEL: @abs_is_not_negative_reduced_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 0
; CHECK-NEXT:    [[NEGX:%.*]] = sub i32 0, [[X]]
; CHECK-NEXT:    [[ABS:%.*]] = select i1 [[CMP]], i32 [[NEGX]], i32 [[X]]
; CHECK-NEXT:    [[R:%.*]] = icmp slt i32 [[ABS]], 42
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp slt i32 %abs, 42
  ret i1 %r
}

; Negative test - range intersection is not empty.

define i1 @abs_nsw_is_not_negative_wrong_range(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative_wrong_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 0
; CHECK-NEXT:    [[NEGX:%.*]] = sub nsw i32 0, [[X]]
; CHECK-NEXT:    [[ABS:%.*]] = select i1 [[CMP]], i32 [[NEGX]], i32 [[X]]
; CHECK-NEXT:    [[R:%.*]] = icmp sle i32 [[ABS]], 0
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp sle i32 %abs, 0
  ret i1 %r
}

; Even if we don't have nsw, the range is still limited in the unsigned domain.
define i1 @abs_positive_or_signed_min(i32 %x) {
; CHECK-LABEL: @abs_positive_or_signed_min(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp ult i32 %abs, 2147483649
  ret i1 %r
}

define i1 @abs_positive_or_signed_min_reduced_range(i32 %x) {
; CHECK-LABEL: @abs_positive_or_signed_min_reduced_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 0
; CHECK-NEXT:    [[NEGX:%.*]] = sub i32 0, [[X]]
; CHECK-NEXT:    [[ABS:%.*]] = select i1 [[CMP]], i32 [[NEGX]], i32 [[X]]
; CHECK-NEXT:    [[R:%.*]] = icmp ult i32 [[ABS]], -2147483648
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp ult i32 %abs, 2147483648
  ret i1 %r
}

; This is canonical form for this IR. For nabs(), we don't require 'nsw'

define i1 @nabs_is_negative_or_0(i32 %x) {
; CHECK-LABEL: @nabs_is_negative_or_0(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp slt i32 %nabs, 1
  ret i1 %r
}

; Test non-canonical predicate and non-canonical form of nabs().

define i1 @nabs_is_negative_or_0_sle(i32 %x) {
; CHECK-LABEL: @nabs_is_negative_or_0_sle(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp sle i32 %nabs, 0
  ret i1 %r
}

; This is a range-based analysis. Any positive constant works.

define i1 @nabs_is_negative_or_0_reduced_range(i32 %x) {
; CHECK-LABEL: @nabs_is_negative_or_0_reduced_range(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp slt i32 %nabs, 421
  ret i1 %r
}

; Negative test - range intersection is not subset.

define i1 @nabs_is_negative_or_0_wrong_range(i32 %x) {
; CHECK-LABEL: @nabs_is_negative_or_0_wrong_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 1
; CHECK-NEXT:    [[NEGX:%.*]] = sub i32 0, [[X]]
; CHECK-NEXT:    [[NABS:%.*]] = select i1 [[CMP]], i32 [[X]], i32 [[NEGX]]
; CHECK-NEXT:    [[R:%.*]] = icmp slt i32 [[NABS]], 0
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp slt i32 %nabs, 0
  ret i1 %r
}

; This is canonical form for this IR. For nabs(), we don't require 'nsw'

define i1 @nabs_is_not_over_0(i32 %x) {
; CHECK-LABEL: @nabs_is_not_over_0(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 0
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp sgt i32 %nabs, 0
  ret i1 %r
}

; Test non-canonical predicate and non-canonical form of nabs().

define i1 @nabs_is_not_over_0_sle(i32 %x) {
; CHECK-LABEL: @nabs_is_not_over_0_sle(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp sge i32 %nabs, 1
  ret i1 %r
}

; This is a range-based analysis. Any positive constant works.

define i1 @nabs_is_not_over_0_reduced_range(i32 %x) {
; CHECK-LABEL: @nabs_is_not_over_0_reduced_range(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp sgt i32 %nabs, 4223
  ret i1 %r
}

; Negative test - range intersection is not subset.

define i1 @nabs_is_not_over_0_wrong_range(i32 %x) {
; CHECK-LABEL: @nabs_is_not_over_0_wrong_range(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[X:%.*]], 1
; CHECK-NEXT:    [[NEGX:%.*]] = sub i32 0, [[X]]
; CHECK-NEXT:    [[NABS:%.*]] = select i1 [[CMP]], i32 [[X]], i32 [[NEGX]]
; CHECK-NEXT:    [[R:%.*]] = icmp sgt i32 [[NABS]], -1
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub i32 0, %x
  %nabs = select i1 %cmp, i32 %x, i32 %negx
  %r = icmp sgt i32 %nabs, -1
  ret i1 %r
}

; More miscellaneous tests for predicates/types.

; Equality predicates are ok.

define i1 @abs_nsw_is_positive_eq(i32 %x) {
; CHECK-LABEL: @abs_nsw_is_positive_eq(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i32 %x, 1
  %negx = sub nsw i32 0, %x
  %abs = select i1 %cmp, i32 %negx, i32 %x
  %r = icmp eq i32 %abs, -8
  ret i1 %r
}

; An unsigned compare may work.

define i1 @abs_nsw_is_positive_ult(i8 %x) {
; CHECK-LABEL: @abs_nsw_is_positive_ult(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i8 %x, 0
  %negx = sub nsw i8 0, %x
  %abs = select i1 %cmp, i8 %negx, i8 %x
  %r = icmp ult i8 %abs, 139
  ret i1 %r
}

; An unsigned compare may work.

define i1 @abs_nsw_is_not_negative_ugt(i8 %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative_ugt(
; CHECK-NEXT:    ret i1 false
;
  %cmp = icmp slt i8 %x, 0
  %negx = sub nsw i8 0, %x
  %abs = select i1 %cmp, i8 %negx, i8 %x
  %r = icmp ugt i8 %abs, 127
  ret i1 %r
}

; Vector types are ok.

define <2 x i1> @abs_nsw_is_not_negative_vec_splat(<2 x i32> %x) {
; CHECK-LABEL: @abs_nsw_is_not_negative_vec_splat(
; CHECK-NEXT:    ret <2 x i1> zeroinitializer
;
  %cmp = icmp slt <2 x i32> %x, zeroinitializer
  %negx = sub nsw <2 x i32> zeroinitializer, %x
  %abs = select <2 x i1> %cmp, <2 x i32> %negx, <2 x i32> %x
  %r = icmp slt <2 x i32> %abs, <i32 -8, i32 -8>
  ret <2 x i1> %r
}

; Equality predicates are ok.

define i1 @nabs_is_negative_or_0_ne(i8 %x) {
; CHECK-LABEL: @nabs_is_negative_or_0_ne(
; CHECK-NEXT:    ret i1 true
;
  %cmp = icmp slt i8 %x, 0
  %negx = sub i8 0, %x
  %nabs = select i1 %cmp, i8 %x, i8 %negx
  %r = icmp ne i8 %nabs, 12
  ret i1 %r
}

; Vector types are ok.

define <3 x i1> @nabs_is_not_over_0_sle_vec_splat(<3 x i33> %x) {
; CHECK-LABEL: @nabs_is_not_over_0_sle_vec_splat(
; CHECK-NEXT:    ret <3 x i1> zeroinitializer
;
  %cmp = icmp slt <3 x i33> %x, <i33 1, i33 1, i33 1>
  %negx = sub <3 x i33> zeroinitializer, %x
  %nabs = select <3 x i1> %cmp, <3 x i33> %x, <3 x i33> %negx
  %r = icmp sge <3 x i33> %nabs, <i33 1, i33 1, i33 1>
  ret <3 x i1> %r
}

; Negative test - intersection does not equal absolute value range.
; PR39510 - https://bugs.llvm.org/show_bug.cgi?id=39510

define i1 @abs_no_intersection(i32 %a) {
; CHECK-LABEL: @abs_no_intersection(
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[A:%.*]], 0
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 0, [[A]]
; CHECK-NEXT:    [[COND:%.*]] = select i1 [[CMP]], i32 [[SUB]], i32 [[A]]
; CHECK-NEXT:    [[R:%.*]] = icmp ne i32 [[COND]], 2
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp slt i32 %a, 0
  %sub = sub nsw i32 0, %a
  %cond = select i1 %cmp, i32 %sub, i32 %a
  %r = icmp ne i32 %cond, 2
  ret i1 %r
}

; Negative test - intersection does not equal absolute value range.

define i1 @nabs_no_intersection(i32 %a) {
; CHECK-LABEL: @nabs_no_intersection(
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[A:%.*]], 0
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 0, [[A]]
; CHECK-NEXT:    [[COND:%.*]] = select i1 [[CMP]], i32 [[SUB]], i32 [[A]]
; CHECK-NEXT:    [[R:%.*]] = icmp ne i32 [[COND]], -2
; CHECK-NEXT:    ret i1 [[R]]
;
  %cmp = icmp sgt i32 %a, 0
  %sub = sub i32 0, %a
  %cond = select i1 %cmp, i32 %sub, i32 %a
  %r = icmp ne i32 %cond, -2
  ret i1 %r
}

; We can't fold this to false unless both subs have nsw.
define i1 @abs_sub_sub_missing_nsw(i32 %x, i32 %y) {
; CHECK-LABEL: @abs_sub_sub_missing_nsw(
; CHECK-NEXT:    [[A:%.*]] = sub i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[B:%.*]] = sub nsw i32 [[Y]], [[X]]
; CHECK-NEXT:    [[C:%.*]] = icmp sgt i32 [[A]], -1
; CHECK-NEXT:    [[D:%.*]] = select i1 [[C]], i32 [[A]], i32 [[B]]
; CHECK-NEXT:    [[E:%.*]] = icmp slt i32 [[D]], 0
; CHECK-NEXT:    ret i1 [[E]]
;
  %a = sub i32 %x, %y
  %b = sub nsw i32 %y, %x
  %c = icmp sgt i32 %a, -1
  %d = select i1 %c, i32 %a, i32 %b
  %e = icmp slt i32 %d, 0
  ret i1 %e
}
