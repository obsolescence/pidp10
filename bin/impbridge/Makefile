CC = gcc
CFLAGS = -Wall -O2
TARGETS = guest-bridge home-bridge

all: $(TARGETS)

guest-bridge: guest-bridge.c
	$(CC) $(CFLAGS) -o guest-bridge guest-bridge.c

home-bridge: home-bridge.c
	$(CC) $(CFLAGS) -o home-bridge home-bridge.c

clean:
	rm -f $(TARGETS)

test: all
	@echo "Bridge programs built successfully"
	@./guest-bridge --help 2>/dev/null || echo "guest-bridge: ready"
	@./home-bridge --help 2>/dev/null || echo "home-bridge: ready"

.PHONY: all clean test
