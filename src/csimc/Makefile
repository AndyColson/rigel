#gcc csimc.c -I../libwcs -I../libfs -I../libastro -I../libfits -I../libmisc  -MM -MT csimc.o
#csimc.o: csimc.c ../libmisc/strops.h ../libmisc/telenv.h \
# ../libmisc/csimc.h ../libmisc/configfile.h el.h mc.h

include ../common.mk
# -I../libwcs -I../libfs -I../libastro -I../libfits
CFLAGS :=  -I../libmisc $(CFLAGS)
#LDFLAGS=  -L$(inst_dir)
LIBS = -lm -lsqlite3

src = $(wildcard *.c) ../libmisc/csimc.c ../libmisc/strops.c ../libmisc/configfile.c ../libmisc/telenv.c
obj = $(src:.c=.o)
dep = $(obj:.o=.d)

.PHONY: all
all: csimc

-include $(dep)

csimc: csimc.o boot.o eintrio.o el.o ../libmisc/csimc.o  ../libmisc/strops.o ../libmisc/configfile.o ../libmisc/telenv.o
	@echo top_dir = $(top_dir)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)


.PHONY: clean
clean:
	rm -f *.o *.d csimc csimcio eltest

.PHONY: install
install:
	cp csimc $(inst_dir)
