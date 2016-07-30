SELIB = libselinux
ZLLIB = zlib/src
SPLIB = core/libsparse
COLIB = core
MALIB = extras/ext4_utils
MKLIB = mkbootimg

all:
	$(MAKE) -C $(SELIB)/src all
	$(MAKE) -C $(ZLLIB) all
	$(MAKE) -C $(SPLIB) all
	$(MAKE) -C $(MALIB) all
	$(MAKE) -C $(MKLIB) all

clean:
	$(MAKE) -C $(SELIB)/src clean
	$(MAKE) -C $(ZLLIB) clean
	$(MAKE) -C $(SPLIB) clean
	$(MAKE) -C $(MALIB) clean
	$(MAKE) -C $(MKLIB) clean

