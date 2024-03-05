void updatePC(int PC);
void updateIR(int IR);
void updateAB(int AB);
void updateMI(uint64 data);
void updateMI_PROG(int data);
void updateMI_MEM(int data);
void updateIOB_PIR(int data);
void updatePIR(int data);
void updatePIP(int data);
void updatePIE(int data);
void updateRUN(int data);
void updatePOWER(int data);
void updatePION(int data);
void updatePSTOP(int data);
void updateMSTOP(int data);
void updateUSER(int data);
void dumpREG();
void injectCMD(char *pidpCMD);
u_int16_t getSWITCH(uint8_t row);
int pidpCONT(void);
//void pidp10_lights_main (uint64 data);  // recycling the panda display


// SwitchRegister ====
uint64 getPIDPSwitchRegister();
uint64 getPIDPAdressSwitches();
// ===================
