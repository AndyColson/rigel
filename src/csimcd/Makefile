
include ../common.mk

CFLAGS := -D_POSIX_C_SOURCE -D_XOPEN_SOURCE -I../libmisc $(CFLAGS)
LIBS=-L$(inst_dir)  -lm -lsqlite3

csimcd: csimcd.o ../libmisc/telenv.o ../libmisc/strops.o ../libmisc/configfile.o ../libmisc/running.o ../libmisc/csimc.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

.PHONY: install
install:
	cp csimcd $(inst_dir)

.PHONY: clean
clean:
	rm -f *.o csimcd

