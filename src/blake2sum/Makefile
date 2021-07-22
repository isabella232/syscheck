all: blake2sum
H_FILE_LIST       = $(sort $(wildcard *.[h]))
C_FILE_LIST       = $(sort $(wildcard *.c))
OBJS = $(C_FILE_LIST:.c=.o)
CFLAGS += -ggdb -O2  -fstack-protector-all -D_FORTIFY_SOURCE=2 -fPIE -pie -Wformat -Wformat-security
LDFLAGS += -pie -Wl,-z,relro -Wl,-z,now -lpthread

%.o : %.c $(H_FILE_LIST)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) $(INCLUDE) -c $< -o $@

blake2sum: $(OBJS)
	$(CC) -static $(LDFLAGS) -o $@ $(OBJS) $(EXTRA_LDFLAGS)

clean:; rm -f *.o blake2sum *.gcov *.gcda *.gcno

distclean: clean

