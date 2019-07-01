.PHONY: all

# debug -g -ggdb
CFLAGS = -O2 -ffast-math -fPIC -Wall -std=c11 -D_DEFAULT_SOURCE

all: ../bin/csimc ../bin/csimcd ../bin/libsqlitefunctions.so

../bin/libsqlitefunctions.so: extension-functions.c
	gcc -fPIC -lm -shared extension-functions.c -o ../bin/libsqlitefunctions.so

../bin/csimc: csimc/csimc.o csimc/boot.o csimc/eintrio.o csimc/el.o csimc/csiutil.o  csimc/strops.o csimc/configfile.o csimc/telenv.o
	$(CC) $(CFLAGS) -o $@ $^ -lm -lsqlite3

../bin/csimcd: csimc/csimcd.o csimc/telenv.o csimc/strops.o csimc/configfile.o csimc/csiutil.o
	$(CC) $(CFLAGS) -D_POSIX_C_SOURCE -D_XOPEN_SOURCE -o $@ $^ -lm -lsqlite3

