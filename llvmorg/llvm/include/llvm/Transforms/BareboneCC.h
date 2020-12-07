#ifndef LLVM_TRANSFORMS_BAREBONECC_H
#define LLVM_TRANSFORMS_BAREBONECC_H

namespace llvm {

class Pass;
class PassManagerBuilder;

void addBareboneCCPassesToExtensionPoints(PassManagerBuilder &Builder);

Pass *createBareboneCCLegalizeLegacyPass();

}

#endif
