; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt < %s -argpromotion -S | FileCheck %s
; RUN: opt < %s -passes=argpromotion -S | FileCheck %s

%struct.ss = type { i32, i64 }

; Don't drop 'byval' on %X here.
define internal void @f(%struct.ss* byval %b, i32* byval %X, i32 %i) nounwind {
; CHECK-LABEL: define {{[^@]+}}@f
; CHECK-SAME: (i32 [[B_0:%.*]], i64 [[B_1:%.*]], i32* byval [[X:%.*]], i32 [[I:%.*]])
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B:%.*]] = alloca [[STRUCT_SS:%.*]], align 8
; CHECK-NEXT:    [[DOT0:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[B]], i32 0, i32 0
; CHECK-NEXT:    store i32 [[B_0]], i32* [[DOT0]], align 4
; CHECK-NEXT:    [[DOT1:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[B]], i32 0, i32 1
; CHECK-NEXT:    store i64 [[B_1]], i64* [[DOT1]], align 4
; CHECK-NEXT:    [[TMP:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[B]], i32 0, i32 0
; CHECK-NEXT:    [[TMP1:%.*]] = load i32, i32* [[TMP]], align 4
; CHECK-NEXT:    [[TMP2:%.*]] = add i32 [[TMP1]], 1
; CHECK-NEXT:    store i32 [[TMP2]], i32* [[TMP]], align 4
; CHECK-NEXT:    store i32 0, i32* [[X]], align 4
; CHECK-NEXT:    ret void
;
entry:

  %tmp = getelementptr %struct.ss, %struct.ss* %b, i32 0, i32 0
  %tmp1 = load i32, i32* %tmp, align 4
  %tmp2 = add i32 %tmp1, 1
  store i32 %tmp2, i32* %tmp, align 4

  store i32 0, i32* %X
  ret void
}

; Also make sure we don't drop the call zeroext attribute.
define i32 @test(i32* %X) {
; CHECK-LABEL: define {{[^@]+}}@test
; CHECK-SAME: (i32* [[X:%.*]])
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[S:%.*]] = alloca [[STRUCT_SS:%.*]], align 8
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[S]], i32 0, i32 0
; CHECK-NEXT:    store i32 1, i32* [[TMP1]], align 8
; CHECK-NEXT:    [[TMP4:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[S]], i32 0, i32 1
; CHECK-NEXT:    store i64 2, i64* [[TMP4]], align 4
; CHECK-NEXT:    [[S_0:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[S]], i32 0, i32 0
; CHECK-NEXT:    [[S_0_VAL:%.*]] = load i32, i32* [[S_0]], align 4
; CHECK-NEXT:    [[S_1:%.*]] = getelementptr [[STRUCT_SS]], %struct.ss* [[S]], i32 0, i32 1
; CHECK-NEXT:    [[S_1_VAL:%.*]] = load i64, i64* [[S_1]], align 4
; CHECK-NEXT:    call void @f(i32 [[S_0_VAL]], i64 [[S_1_VAL]], i32* byval [[X]], i32 zeroext 0)
; CHECK-NEXT:    ret i32 0
;
entry:
  %S = alloca %struct.ss
  %tmp1 = getelementptr %struct.ss, %struct.ss* %S, i32 0, i32 0
  store i32 1, i32* %tmp1, align 8
  %tmp4 = getelementptr %struct.ss, %struct.ss* %S, i32 0, i32 1
  store i64 2, i64* %tmp4, align 4

  call void @f( %struct.ss* byval %S, i32* byval %X, i32 zeroext 0)

  ret i32 0
}
