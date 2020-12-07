#include "clang/Basic/DynamicCallingConv.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace clang {

StringRef DynamicCallingConv::getName() const {
  if (NameCache.empty()) {
    raw_string_ostream OS(NameCache);
    printName(OS);
    OS.flush();
  }
  return NameCache;
}

void DynamicCallingConv::printName(raw_ostream &OS) const {
  if (auto *BCC = dyn_cast<BareboneCallingConv>(this)) {
    BCC->printName(OS);
  } else {
    llvm_unreachable("Invalid dynamic calling convention");
  }
}

void DynamicCallingConv::printFunctionAfter(raw_ostream &OS) const {
  if (auto *BCC = dyn_cast<BareboneCallingConv>(this)) {
    BCC->printFunctionAfter(OS);
  } else {
    llvm_unreachable("Invalid dynamic calling convention");
  }
}

void BareboneCallingConv::printName(raw_ostream& OS) const {
  OS << "barebone(hwreg=\"";
  OS.write_escaped(HWReg);
  OS << '"';
  if (!NoClobberHWReg.empty()) {
    OS << ",no_clobber_hwreg=\"";
    OS.write_escaped(NoClobberHWReg);
    OS << '"';
  }
  if (LocalAreaSize) {
    OS << ",local_area_size=" << LocalAreaSize;
  }
  OS << ')';
}

void BareboneCallingConv::printFunctionAfter(raw_ostream &OS) const {
  OS << " attribute((";
  printName(OS);
  OS << "))";
}

void BareboneCallingConv::Profile(FoldingSetNodeID &ID,
                                  StringRef HWReg,
                                  StringRef NoClobberHWReg,
                                  unsigned LocalAreaSize) {
  ID.AddString(HWReg);
  ID.AddString(NoClobberHWReg);
  ID.AddInteger(LocalAreaSize);
}

} // namespace clang
