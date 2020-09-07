stubs.a: stubs.o
	emar -sr stubs.a stubs.o

stubs.o: stubs.c
	emcc -c stubs.c

test.wasm: stubs.a test.c
	emcc test.c -s STANDALONE_WASM=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 stubs.a -o test.wasm
