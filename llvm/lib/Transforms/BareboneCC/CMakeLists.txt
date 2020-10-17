add_llvm_component_library(LLVMBareboneCC
  BareboneCC.cpp

  LINK_COMPONENTS
  Analysis
  Core
  IPO
  Scalar
  Support
  TransformUtils
  )
