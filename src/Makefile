
# libastro libfits libfs libwcs rund
SECTIONS =  csimc csimcd

.PHONY: $(SECTIONS) all clean install

include common.mk

all: $(SECTIONS)


$(SECTIONS):
	$(MAKE) -C $@

clean:
	@for dir in $(SECTIONS); do \
	  $(MAKE) -C $$dir clean; \
	done

install:
	@for dir in $(SECTIONS); do \
	  $(MAKE) -C $$dir install; \
	done

