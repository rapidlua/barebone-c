#include "llvm/Pass.h"
#include "llvm/Analysis/CallGraphSCCPass.h"
#include "llvm/InitializePasses.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Transforms/BareboneCC.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"

namespace llvm {
void initializeBareboneCCLegalizeLegacyPass(PassRegistry &);
}

using namespace llvm;

void llvm::initializeBareboneCC(PassRegistry &Registry) {
  initializeBareboneCCLegalizeLegacyPass(Registry);
}

static void addBareboneCCPass(const PassManagerBuilder &Builder,
                              legacy::PassManagerBase &PM) {
  PM.add(createBareboneCCLegalizeLegacyPass());
}

void llvm::addBareboneCCPassesToExtensionPoints(PassManagerBuilder &Builder) {
  Builder.addExtension(PassManagerBuilder::EP_EnabledOnOptLevel0,
                       addBareboneCCPass);
  Builder.addExtension(PassManagerBuilder::EP_CGSCCOptimizerLate,
                       addBareboneCCPass);
}

namespace {

bool isInTailCallPosition(const CallInst &CI) {
  // See Verifier::verifyMustTailCall; assuming that barebonecc
  // calling convention requires void return types
  const auto *Ret = dyn_cast_or_null<ReturnInst>(CI.getNextNode());
  return Ret && !Ret->getReturnValue();
}

// Inliner pass is a call-graph pass.  In order to enable efficient
// composition, we implement the barebonecc legalizer as a call-graph
// pass as well.
// Note: inliner doesn't remove dead functions until the finalisation.
// Therefore we have to postpone validation.
struct BareboneCCLegalizeLegacy : public CallGraphSCCPass {
  static char ID; // Pass identification, replacement for typeid.
  BareboneCCLegalizeLegacy() : CallGraphSCCPass(ID) {}
  bool runOnSCC(CallGraphSCC &SCC) override {
    // Promote eligible barebonecc calls to musttail.
    bool DidChangeIR = false;
    for (CallGraphNode *Node : SCC) {
      Function *F = Node->getFunction();
      if (!F || F->isDeclaration() ||
          F->getCallingConv() != CallingConv::Barebone)
        continue;
      for (BasicBlock &BB : *F)
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (!CI || CI->getCallingConv() != CallingConv::Barebone ||
              !isInTailCallPosition(*CI))
            continue;
          CI->setTailCallKind(CallInst::TCK_MustTail);
          DidChangeIR = true;
        }
    }
    return DidChangeIR;
  }
  bool doFinalization(CallGraph &CG) override {
    // Check constraints:
    //  * barebonecc calls are only allowed in barebonecc functions and
    //    only in tail call position;
    //  * barebonecc must terminate by tail-calling another barebonecc
    //    function.
    bool DidChangeIR = false;
    for (auto &F: CG.getModule()) {
      bool IsOK = true;
      if (F.isDeclaration()) continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          if (auto *CI = dyn_cast<CallInst>(&I)) {
            if (CI->getCallingConv() == CallingConv::Barebone) {
              if (F.getCallingConv() == CallingConv::Barebone) {
                if (isInTailCallPosition(*CI)) break;
                F.getContext().diagnose(
                  DiagnosticInfoBareboneCC::notInTailCallPosition(
                    DS_Error, F, CI));
              } else {
                F.getContext().diagnose(
                  DiagnosticInfoBareboneCC::inNonBareboneFunction(
                    DS_Error, F, CI));
              }
              IsOK = false;
            }
          }
          if (auto *Ret = dyn_cast<ReturnInst>(&I)) {
            if (F.getCallingConv() == CallingConv::Barebone) {
              F.getContext().diagnose(
                DiagnosticInfoBareboneCC::returnNotAllowed(DS_Error, F, &I));
              IsOK = false;
            }
          }
        }
      }
      if (IsOK) continue;
      // Fix by altering calling convention to avoid further errors down
      // the pipeline.
      if (F.getCallingConv() == CallingConv::Barebone)
        F.setCallingConv(CallingConv::C);
      for (BasicBlock &BB : F)
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (CI && CI->getCallingConv() == CallingConv::Barebone)
            CI->setCallingConv(CallingConv::C);
        }
      DidChangeIR = true;
    }
    return DidChangeIR;
  }
  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
  }
  StringRef getPassName() const override {
    return "Barebonecc legalize";
  }
};
}

char BareboneCCLegalizeLegacy::ID = 0;
INITIALIZE_PASS(BareboneCCLegalizeLegacy, "barebonecc-legalize",
                "Promote barebonecc calls to musttail and check constraints",
                false, false)

Pass *llvm::createBareboneCCLegalizeLegacyPass() {
  return new BareboneCCLegalizeLegacy();
}
