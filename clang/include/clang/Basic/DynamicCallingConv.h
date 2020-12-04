#ifndef LLVM_CLANG_AST_DYNAMIC_CALLING_CONV_H
#define LLVM_CLANG_AST_DYNAMIC_CALLING_CONV_H

#include "clang/Basic/Specifiers.h"
#include "llvm/ADT/FoldingSet.h"

namespace clang {

class ASTContext;

// Base class for all dynamic calling conventions.
// Normal calling conventions are fixed in stone.  Dynamic ones, on the
// other hand, are user-defined.  To reuse the existing framework, we
// had to smugle dynamic calling convention pointers as CallingConv
// values (enum, extends uintptr_t).
class DynamicCallingConv {
  friend class ASTContext;
public:
  enum TypeClass {
    Barebone
  };
  TypeClass getTypeClass() const { return TC; }
  CallingConv asCC() const {
    uintptr_t v = reinterpret_cast<uintptr_t>(this);
    assert(!(v&1) && "Pointer must be aligned");
    return static_cast<CallingConv>(-(v >> 1));
  }
  static const DynamicCallingConv *get(CallingConv CC) {
    // Detects truncation and doesn't make assumptions about pointer
    // bit patterns (apart from alignment).
    if (CC < -CC)
      return nullptr;
    return reinterpret_cast<DynamicCallingConv *>(-CC << 1);
  }
  llvm::StringRef getName() const;
  void printName(llvm::raw_ostream &OS) const;
  void printFunctionAfter(llvm::raw_ostream &OS) const;
protected:
  DynamicCallingConv(TypeClass TC) : TC(TC) {}
private:
  mutable std::string NameCache;
  TypeClass TC;

  void resetNameCache() { std::string().swap(NameCache); }
};

class BareboneCallingConv : public DynamicCallingConv,
                            public llvm::FoldingSetNode {
public:
  static bool classof(const DynamicCallingConv *DCC) {
    return DCC->getTypeClass() == Barebone;
  }
  BareboneCallingConv(llvm::StringRef HWReg, llvm::StringRef NoClobberHWReg,
                      unsigned LocalAreaSize)
   : DynamicCallingConv(Barebone), HWReg(HWReg), NoClobberHWReg(NoClobberHWReg),
     LocalAreaSize(LocalAreaSize) {}
  llvm::StringRef getHWReg() const { return HWReg; }
  llvm::StringRef getNoClobberHWReg() const { return NoClobberHWReg; }
  unsigned getLocalAreaSize() const { return LocalAreaSize; }
private:
  llvm::StringRef HWReg, NoClobberHWReg;
  unsigned LocalAreaSize;
public:
  void Profile(llvm::FoldingSetNodeID &ID) const {
    Profile(ID, HWReg, NoClobberHWReg, LocalAreaSize);
  }
  static void Profile(llvm::FoldingSetNodeID &ID, llvm::StringRef HWReg,
                      llvm::StringRef NoClobberHWReg, unsigned LocalAreaSize);
  void printName(llvm::raw_ostream& OS) const;
  void printFunctionAfter(llvm::raw_ostream &OS) const;
};

} // namespace clang

#endif // LLVM_CLANG_AST_DYNAMIC_CALLING_CONV_H
