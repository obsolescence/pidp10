// PiDP-10 front panel driver.
//
// 20240302 OV for final PCB layout

#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h> 
#include <time.h>				//Needed for nanosleep
#include <pthread.h>			//Needed for pthread
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include <errno.h>
#include "pinctrl/gpiolib.h"
typedef uint64_t uint64;
#include "pidp10panel.h"

// the interface variables shared with other threads
volatile u_int32_t gpio_switchstatus[5] ; // bitfields: 5 rows of up to 18 switches
volatile u_int32_t gpio_ledstatus[8] ;	// bitfields: 7 ledrows of up to 18 LEDs

// for multiplexing, sleep time between row switches in ns (but excl. overhead!)
long intervl = 50000;	//	300000;		// light each row of leds this long

// GPIO pins: function & definitions
//		GPIO 22 ('xIO') enables either the 74hc138 (when low) or the 74hc238 (when high)
//
//		GPIO 4,17 and 27 are the 'xrows', a 3 bit address fed into both 74hc chips,
//		which then decode that 3 bit address to enable one of their 8 output pins
//
//		7 rows on the 74hc238 each provide power to a block of 18 LEDs
//			(a LED will then light up when its column pin is set to LOW!)
//		5 rows on the 74hc138 each sink the current for a block of 18 switches 
//			(a set switch pulls its column pin to GND, overruling its internal pull-up)
//
//		when xIO is set to output LOW, 
//		- the 74hc238 decodes these 3 address lines into 
//		  one of the 7 blocks of LEDs on the board
//		- to light up a LED, set its column GPIO pin LOW. 
//		  To keep it dark, set that GPIO pin HIGH
//
//		and when xIO is set to output HIGH,
//		- the 74hc138 decodes these 3 address lines into 
//		  one of the 5 blocks of switches on the board 
//		- the column pins needs to be set to input-with-pullup-high to read switches

u_int8_t xrows[3] = { 4, 17, 27 };
u_int8_t xIO = 22;			// GPIO 22: 0=drive LEDs, 1=read switches
u_int8_t cols[18] = { 21,20,16,12,7,8,25,24,23,  18,10,9,11,5,6,13,19,26 };


// helper functions: parallel threads for GPIO mux and LED brightness averaging
//
void *blink(void *ptr); // the real-time GPIO multiplexing process to start up
void *gpiopattern_update_leds(void *ptr); // the averaging thread
void gpio_mux_thread_start(void);

pthread_t blink_thread;
int blink_thread_terminate = 0;

void gpio_mux_thread_start()
{
    int res;
    res = pthread_create(&blink_thread, NULL, blink, &blink_thread_terminate);
    if (res) {
        fprintf(stderr, "Error creating gpio_mux thread, return code %d\n", res);
        exit(EXIT_FAILURE);
    }
    printf("Created blink_thread\n");
    sleep(2); // allow 2 sec for multiplex to start
}



// A - the multiplexing thread 'blink'
//
void *blink(void *ptr)
{
	int	*terminate = (int *)ptr;
	int	col, row, i, k, switchscan, tmp;
    	int num_gpios, ret;
	volatile u_int32_t gpio_ledbuffer[8];	// bitfields: 7 ledrows of up to 18 LEDs

	// set thread to real time priority -----------------
	struct sched_param sp;
	sp.sched_priority = 98; // maybe 99, 32, 31?
	if (pthread_setschedparam(pthread_self(), SCHED_FIFO, &sp))
		fprintf(stderr, "warning: failed to set RT priority\n");

	// init GPIO ----------
	ret = gpiolib_init();
	if (ret < 0)
	{	printf("Failed to initialise gpiolib - %d\n", ret);
		return (void *)-1;
	}

	num_gpios = ret;
	if (!num_gpios)
	{	printf("No GPIO chips found\n");
		return (void *)-1;
	}

	uint32_t gpiomask[(MAX_GPIO_PINS + 31)/32] = { 0 };
	#define ARRAY_SIZE(_a) (sizeof(_a)/sizeof(_a[0]))
	for (i = ARRAY_SIZE(gpiomask) - 1; i >= 0; i--)
	{	if (gpiomask[i])
			break;
	}
	if (i < 0)
		memset(gpiomask, 0xff, sizeof(gpiomask));

	ret = gpiolib_mmap();
	if (ret)
	{	if (ret == EACCES && geteuid())
			printf("Must be root\n");
		else
			printf("Failed to mmap gpiolib - %s\n", strerror(ret));
		return (void *)-1;
	}

	// initialise GPIO pins
	// - xIO pin
	gpio_set_fsel(xIO, GPIO_FSEL_OUTPUT);
	gpio_set_dir(xIO, DIR_OUTPUT);
	gpio_set_drive(xIO, DRIVE_HIGH);
	
	// - row address pins
	for (row = 0; row < 3; row++) {
		gpio_set_fsel(xrows[row], GPIO_FSEL_OUTPUT);
		gpio_set_dir(xrows[row], DIR_OUTPUT);
		gpio_set_drive(xrows[row], DRIVE_HIGH);

	}
	// - columns
	for (col = 0; col < 18; col++) { // Define ledrows as input
		gpio_set_fsel(cols[col], GPIO_FSEL_INPUT);
		gpio_set_pull(cols[col], PULL_UP);
	}
	printf("\nPiDP-10 FP on\n");
	
	// start the actual multiplexing
		
	while (*terminate == 0)
	{
		// LIGHT THE LEDS	
		// ---- set cols to 18 bits of output -----
		for (i = 0; i < 18; i++) 
			gpio_set_dir(cols[i], DIR_OUTPUT);

		// ---- now, 7 rows of LEDS get lit sequentially
		for (row=0; row<7; row++)	
		{
			// stub for possible lamp glow emulation (7 rows each with 32 phases)
			gpio_ledbuffer[row]=gpio_ledstatus[row];

			// Toggle 18 columns for this ledrow, and in this phase
			for (k = 0; k < 18; k++) 
			{	if ((gpio_ledbuffer[row] & (1 << k)) == 0)
					gpio_set_drive(cols[k], DRIVE_HIGH);
				else
					gpio_set_drive(cols[k], DRIVE_LOW);
			}

			// ----- select row from address
			for(i=0; i<3;i++)
			{	if((row & (1<<i)) == 0)
					gpio_set_drive(xrows[i], DRIVE_LOW);
				else	
					gpio_set_drive(xrows[i], DRIVE_HIGH);
			}

			// ----- now let the LEDs burn for a while -----
			gpio_set_drive(xIO, DRIVE_LOW);
			nanosleep((struct timespec[]) {	{	0, intervl}}, NULL);
			gpio_set_drive(xIO, DRIVE_HIGH);
			nanosleep((struct timespec[]) {	{	0, intervl/2}}, NULL);
			// the nanosleep above is crucial to avoid ghosting and occasional flickering
			// of LEDs. Ghosting or occasional flickering? Longer interval than intervl/2.
		}		

		// READ THE SWITCHES
		//	
		// message to others: debouncing the switches in software is nonsense in this circuit
		// it will only waste CPU cycles. Don't add it. I know you want to. Don't.

		// ---- set cols to 18 bits of input -----
		for (i = 0; i < 18; i++) 
			gpio_set_dir(cols[i], DIR_INPUT);

		for (row=0; row<5; row++)		// there are 5 rows of 18 switches each
		{
			// ----- select row from address
			for(i=0; i<3;i++)
			{	if((row & (1<<i)) == 0)
					gpio_set_drive(xrows[i], DRIVE_LOW);
				else	
					gpio_set_drive(xrows[i], DRIVE_HIGH);
			}

			nanosleep((struct timespec[]) { { 0, intervl / 10}}, NULL); 

			// ----- read switches 		
			switchscan = 0;
			for (i = 0; i < 18; i++) // 18 switches in each row
			{	tmp = gpio_get_level(cols[i]);
				if (tmp != 0)
					switchscan += 1 << i;
			}
			gpio_switchstatus[row] = switchscan;

		}
	}
	
	// received terminate signal, 
	// close down and set GPIO so no LEDs are lit, no switch row is activated
	gpio_set_drive(xIO, DRIVE_HIGH);
	for (i = 0; i < 18; i++) 
		gpio_set_dir(cols[i], DIR_INPUT);
	for (row = 0; row < 3; row++) 
		gpio_set_drive(xrows[row], DRIVE_HIGH);

	return (void *)NULL;
}

/*
// test main function for debugging standalone
int main(void)
{
	time_t start, end;
	double elapsed;  // seconds
	int i,print=0;
	int terminate = 1;
	u_int32_t last_switchstatus[5] ; // bitfields: 5 rows of up to 18 switches
	//int cycles = 60;
	
	printf("\nPiDP-10 tester program\n");
	printf("MUST BE RUN WITH SUDO!\n\n");
	printf("\nAfter 2 seconds,\nyou should see all the LEDs light up with a binary counter,\n");
	printf("and every switch you toggle must give a response in the printed output.\n");
	printf("\nThe printed output should show 5 groups of octal numbers,\neach octal number represents 3 switches. 0 indicates all switches off.\n"); 

	printf("\nTest that all lamps light up, and all switches generate a response.\n");
	printf("The program runs for 60 seconds, or ^C to abort\n\n");
	
	// start up multiplexing thread
	gpio_mux_thread_start();

	printf("***Run for %d seconds\n", 60);
	start = time(NULL);
	while (terminate)	//(cycles--)>0)	//(terminate) 
	{
		for (i=0; i<7; i++)
		{
			gpio_ledstatus[i] = (u_int32_t) rand();
			//gpio_ledstatus[i] = (u_int32_t) democounter++;
		}
		
		for (i=0; i<5; i++)
		{
			if (gpio_switchstatus[i]!=last_switchstatus[i])		//	262143)
			{
				last_switchstatus[i]=gpio_switchstatus[i];
				print=1;
			}
		}

		if (print)
		{
			//printf("... %d ...", cycles);
			for (i=0; i<5 ; i++)
				printf("%o-%o | ", i, 0777777-gpio_switchstatus[i]);
			printf("\n");
			print=0;
			//sleep(1);
		}

		usleep(900000);
		end = time(NULL);

		elapsed = difftime(end, start);
		if (elapsed >= 60.0 ) // 60 seconds
			terminate = 0;
	}
	

	printf("***Terminate threads\n");
	blink_thread_terminate=1;
	
	sleep (2);	// allow threads to close down
	printf("***Done\n");
	return 0;
}
*/

// should include kx10defs.h, but for overview temporarily here:
typedef u_int64_t uint64;
typedef u_int64_t t_addr;

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

// global variables in kx10cpu.c, snooped at here
extern t_addr  PC;                                   // Program counter
extern uint32_t  IR;                                   // Instruction register
extern uint32_t  AC;                                   // Operand accumulator
extern t_addr  AB;                                   // Memory address buffer
extern uint64  AR;                                   // Primary work register
//extern uint64	MB;					// Memory buffer *** maybe unnecessary ***


// ==== functions to read out address and data switches
extern uint64  SW;                                   // Switch register
uint64 getPIDPSwitchRegister()
{
	// NOTE! production PCB switches switchstatus 0 and 1 around vs prototype!
	uint64 x = ~gpio_switchstatus[1] & 0777777;
	return (x << 18) | (~gpio_switchstatus[0] & 0777777);
}

uint64 getPIDPAdressSwitches()
{
	return ~gpio_switchstatus[2] & 0777777;
}
// ===================



//void printBits(size_t const size, void const * const ptr);
u_int16_t getSWITCH(uint8_t row);
void injectCMD(char *pidpCMD);
void pidpCMD(char *cptr);

// string that contains a simh command to be injected into simh command line
char cmdBuffer[255];
// can be called to inject a command in simh command line.
// it will be picked up in scp.c's read_line() function, see code there
void injectCMD(char *pidpCMD)
{
	strcpy(cmdBuffer, pidpCMD);
	//printf("injected %s\r\n", cmdBuffer);
}
// used after command injection to forget command (and not inject it again)
void pidpCMD(char *cptr)
{
	strcpy (cptr, cmdBuffer);
	cmdBuffer[0]='\0';	// cmd is now sent to simh, done
	//printf("cptr is now %s\r\n", cptr);
}

// ====================================================================================
// functions to deal with reading the switches on the PIDP 
// ====================================================================================
// let simh access one of the 5 rows (of 16 switches each) on PIDP panel:
u_int16_t getSWITCH(uint8_t row)
{
	return ~gpio_switchstatus[row];
}

void dumpREG(void)
{
	printf("PC %llo   IR %llo   AC %llo  AB %llo   AR %llo \r\n", PC, IR, AC, AB, AR);
}



// ====================================================================================
// functions to update all the LEDs on the front panel from CPU registers in kx10_cpu.c
// ====================================================================================
// to avoid interference with multiplexing thread, update LEDs in temp buffer first
static u_int16_t temp_ledstatus[8] = { 0x00 };

void updatePC(int PC)
{
	PC &= 0777777;
	gpio_ledstatus[4] = PC;
}

void updateIR(int IR)
{
	IR &= 0777777;
	gpio_ledstatus[3] = IR;
}

void updateAB(int AB)
{
	AB &= 0777777;
	gpio_ledstatus[2] = AB;
}

void updateMI(uint64 data)
{
	data &= 0777777777777ULL;
	gpio_ledstatus[0] = data & 0777777;
	gpio_ledstatus[1] = data >> 18;
}

void updateMI_PROG(int data)
{
	data &= 1;
        gpio_ledstatus[6] &= ~(1 << 16);
	gpio_ledstatus[6] |= data << 16;
}

void updateMI_MEM(int data)
{
	data &= 1;
        gpio_ledstatus[6] &= ~(1 << 17);
	gpio_ledstatus[6] |= data << 17;
}

void updateIOB_PIR(int data)
{
	data &= 0177;
	gpio_ledstatus[5] &= ~(0177 << 7);
	gpio_ledstatus[5] |= data << 7;
}

void updatePIP(int data)
{
	data &= 0177;
	gpio_ledstatus[6] &= ~(0177 << 7);
	gpio_ledstatus[6] |= data << 7;
}

void updatePIR(int data)
{
	data &= 0177;
	gpio_ledstatus[6] &= ~(0177);
	gpio_ledstatus[6] |= data;
}

void updatePIE(int data)
{
	data &= 0177;
	gpio_ledstatus[5] &= ~(0177);
	gpio_ledstatus[5] |= data;
}

void updateRUN(int data)
{
	data &= 1;
	gpio_ledstatus[6] &= ~(1 << 14);
	gpio_ledstatus[6] |= data << 14;
}

void updatePION(int data)
{
	data &= 1;
	gpio_ledstatus[6] &= ~(1 << 15);
	gpio_ledstatus[6] |= data << 15;
}

void updatePOWER(int data)
{
	data &= 1;
	gpio_ledstatus[5] &= ~(1 << 17);
	gpio_ledstatus[5] |= data << 17;
}

void updatePSTOP(int data)
{
	data &= 1;
	gpio_ledstatus[5] &= ~(1 << 14);
	gpio_ledstatus[5] |= data << 14;
}

void updateUSER(int data)
{
	data &= 1;
	gpio_ledstatus[5] &= ~(1 << 15);
	gpio_ledstatus[5] |= data << 15;
}

void updateMSTOP(int data)
{
	data &= 1;
	gpio_ledstatus[5] &= ~(1 << 16);
	gpio_ledstatus[5] |= data << 16;
}

