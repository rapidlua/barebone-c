SRC_ROOT?=./llvmorg
LLVM_SRC_ROOT=${SRC_ROOT}/llvm
BUILD_ROOT?=build
LLVM_ENABLE_PROJECTS?=clang
LLVM_TARGETS_TO_BUILD?=X86
CMAKE_GENERATOR=Ninja
BUILD_COMMAND=ninja

PKG_NAME?=doodad
PKG_VERSION?=1.2.3

LLVM_OPTIONS=-DLLVM_INCLUDE_GO_TESTS=0 -DLLVM_INCLUDE_BENCHMARKS=0
LLVM_OPTIONS+=-DLLVM_ENABLE_BACKTRACES=0 -DLLVM_ENABLE_THREADS=0
LLVM_OPTIONS+=-DLLVM_ENABLE_PLUGINS=0 -DLLVM_ENABLE_ZLIB=0
LLVM_OPTIONS+=-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS}
LLVM_OPTIONS+=-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}

dist: ${BUILD_ROOT}/dist/.dist

${BUILD_ROOT}/dist/.dist: ${BUILD_ROOT}/llvm-wasi/bin/llc.wasm
	mkdir -p ${BUILD_ROOT}/dist
	cp ${BUILD_ROOT}/llvm-wasi/bin/llc.wasm ${BUILD_ROOT}/dist
	sed -e 's/<PKG_VERSION>/${PKG_VERSION}/;s/<PKG_NAME>/${PKG_NAME}/' \
		${SRC_ROOT}/wapm.toml > ${BUILD_ROOT}/wapm.toml
	wapm validate ${BUILD_ROOT}/dist

# stubs
${BUILD_ROOT}/%.o: ${SRC_ROOT}/stubs/%.c ${SRC_ROOT}/stubs/d.h
	mkdir -p ${BUILD_ROOT}
	emcc -c -I $(abspath ${SRC_ROOT})/stubs $< -o $@

${BUILD_ROOT}/libstubs.a: ${BUILD_ROOT}/stubs.o
	emar -sr $@ $<

# llvm-host
${BUILD_ROOT}/llvm-host/.configured:
	mkdir -p ${BUILD_ROOT}/llvm-host
	cd ${BUILD_ROOT}/llvm-host && \
	cmake $(abspath ${LLVM_SRC_ROOT}) -G${CMAKE_GENERATOR} \
		-DCMAKE_BUILD_TYPE=Release ${LLVM_OPTIONS}
	touch $@

${BUILD_ROOT}/llvm-host/bin/llvm-tblgen: ${BUILD_ROOT}/llvm-host/.configured
	cd ${BUILD_ROOT}/llvm-host && ${BUILD_COMMAND} llvm-tblgen

# llvm-wasi
${BUILD_ROOT}/llvm-wasi/rules.ninja:
	mkdir -p ${BUILD_ROOT}/llvm-wasi
	cd ${BUILD_ROOT}/llvm-wasi && \
	emmake cmake $(abspath ${LLVM_SRC_ROOT}) -G${CMAKE_GENERATOR} \
		-DCMAKE_BUILD_TYPE=Release -Wno-dev -DCMAKE_SUPPRESS_REGENERATION=1 \
		${LLVM_OPTIONS} \
		-DLLVM_TABLEGEN=$(abspath ${BUILD_ROOT})/llvm-wasi/bin/llvm-tblgen \
		-DCMAKE_EXECUTABLE_SUFFIX_CXX=.wasm \
		"-DCMAKE_EXE_LINKER_FLAGS=-sSTANDALONE_WASM -sALLOW_MEMORY_GROWTH -sERROR_ON_UNDEFINED_SYMBOLS=0" \
		-DHAVE_DLOPEN=0 -DHAVE_GETRLIMIT=0 -DHAVE_GETRUSAGE=0 \
		-DHAVE_POSIX_SPAWN=0 -DHAVE_SETRLIMIT=0 -DHAVE_SIGALTSTACK=0

${BUILD_ROOT}/llvm-wasi/.configured: ${BUILD_ROOT}/llvm-wasi/rules.ninja
	echo patching generated ninja build system
	sed -ie '/CXX_EXECUTABLE_LINKER__/,/^$$/s|LINK_LIBRARIES|LINK_LIBRARIES $(abspath ${BUILD_ROOT}/libstubs.a) $(abspath ${BUILD_ROOT}/notify_mem_growth.o)|' $<
	touch $@

${BUILD_ROOT}/llvm-wasi/bin/llc.wasm: ${BUILD_ROOT}/llvm-wasi/.configured ${BUILD_ROOT}/llvm-host/bin/llvm-tblgen ${BUILD_ROOT}/libstubs.a ${BUILD_ROOT}/notify_mem_growth.o
	rm -f $@
	cd ${BUILD_ROOT}/llvm-wasi && ${BUILD_COMMAND} $(notdir $@)

# check
${BUILD_ROOT}/llvm-wasi/.test-depends: ${BUILD_ROOT}/llvm-wasi/bin/llc.wasm ${BUILD_ROOT}/llvm-host/.configured
	cd ${BUILD_ROOT}/llvm-host && ${BUILD_COMMAND} llvm-test-depends
	for tool in $$(cd ${BUILD_ROOT}/llvm-host/bin && find . -executable -not -name not -not -name llc -not -name llvm-lit); do \
		ln -fs $$(realpath ${BUILD_ROOT}/llvm-host/bin/$$tool) ${BUILD_ROOT}/llvm-wasi/bin/$$tool || return 1;\
	done
	ln -fs $$(realpath ${BUILD_ROOT}/llvm-host/bin/not) ${BUILD_ROOT}/llvm-wasi/bin/_not
	cp ${SRC_ROOT}/scripts/llc ${SRC_ROOT}/scripts/not ${BUILD_ROOT}/llvm-wasi/bin
	touch $@

check-wasi: ${BUILD_ROOT}/llvm-wasi/.test-depends
	${BUILD_ROOT}/llvm-wasi/bin/llc --version # preheat cache
	cd ${BUILD_ROOT}/llvm-wasi && bin/llvm-lit -v $(abspath ${LLVM_SRC_ROOT})/test

check-host: ${BUILD_ROOT}/llvm-host/.configured
	cd ${BUILD_ROOT}/llvm-host && ${BUILD_COMMAND} check
