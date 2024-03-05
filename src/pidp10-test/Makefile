CC = gcc
CFLAGS = -pthread -Wall -Wextra -g
SRC = pidp10panel.c pinctrl/gpiochip_bcm2712.c  pinctrl/gpiochip_bcm2835.c  pinctrl/gpiochip_rp1.c  pinctrl/gpiolib.c  pinctrl/pinctrl.c  pinctrl/util.c


OBJ = $(SRC:.c=.o)
EXECUTABLE = pidp10-test

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@

%o: %c
	$(CC) $(CFLAGS) -c $< -o $@

pinctrl/%.o: pinctrl/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(EXECUTABLE)

