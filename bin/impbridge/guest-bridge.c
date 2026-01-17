/*
 * guest-bridge.c - UDP bridge for guest IMP to VPS (3-socket design)
 *
 * Socket 1 (IMP): Bind to 11199
 *   - Receives from IMP (IMP sends to 11199)
 *   - Sends to IMP at 11198 (source port = 11199 automatically)
 * Socket 2 (VPS): Unbound
 *   - Sends to VPS:6001
 * Socket 3 (FRPC): Bind to 31162
 *   - Receives from frpc
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/select.h>

#define BUFFER_SIZE 16384

#define IMP_RECV_PORT 11198
#define IMP_SEND_PORT 11199

//3 1 62 was 31 1 41
#define FRPC_RECV_PORT 31162
#define VPS_IP "50.6.201.221"
#define VPS_PORT 6001

// Statistics
static unsigned long packets_to_vps = 0;
static unsigned long packets_to_imp = 0;
static unsigned long bytes_to_vps = 0;
static unsigned long bytes_to_imp = 0;
static int verbose = 0;
static volatile int running = 1;

void signal_handler(int signum) {
    running = 0;
}

void print_stats(void) {
    printf("\n=== Guest Bridge Statistics ===\n");
    printf("To VPS:   %lu packets (%lu bytes)\n", packets_to_vps, bytes_to_vps);
    printf("To IMP:   %lu packets (%lu bytes)\n", packets_to_imp, bytes_to_imp);
    printf("===============================\n");
}

int main(int argc, char *argv[]) {
    unsigned char buffer[BUFFER_SIZE];
    int sock_imp, sock_vps, sock_frpc;
    struct sockaddr_in addr, vps_addr, imp_addr;
    fd_set readfds;
    int maxfd;
    ssize_t len;

    // Parse arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--verbose") == 0 || strcmp(argv[i], "-v") == 0) {
            verbose = 1;
        }
    }

    printf("=== Guest Bridge Starting ===\n");
    printf("IMP receive: 127.0.0.1:%d\n", IMP_RECV_PORT);
    printf("IMP send:    127.0.0.1:%d\n", IMP_SEND_PORT);
    printf("VPS:         %s:%d\n", VPS_IP, VPS_PORT);
    printf("frpc→bridge: 127.0.0.1:%d\n", FRPC_RECV_PORT);
    printf("Verbose:     %s\n", verbose ? "yes" : "no");
    printf("=============================\n\n");

    // Setup signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Socket 1: IMP socket (bound to 11199)
    // Receives from IMP, sends to IMP with source port 11199
    sock_imp = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock_imp < 0) {
        perror("socket IMP");
        exit(1);
    }
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    addr.sin_port = htons(IMP_SEND_PORT);
    if (bind(sock_imp, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind IMP socket");
        exit(1);
    }
    printf("[INIT] IMP socket bound to 127.0.0.1:%d\n", IMP_SEND_PORT);

    // Socket 2: VPS socket (unbound, just for sending)
    sock_vps = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock_vps < 0) {
        perror("socket VPS");
        exit(1);
    }
    printf("[INIT] VPS socket created\n");

    // Socket 3: FRPC socket (bound to 31162)
    sock_frpc = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock_frpc < 0) {
        perror("socket FRPC");
        exit(1);
    }
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    addr.sin_port = htons(FRPC_RECV_PORT);
    if (bind(sock_frpc, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind FRPC socket");
        exit(1);
    }
    printf("[INIT] FRPC socket bound to 127.0.0.1:%d\n", FRPC_RECV_PORT);

    // Prepare VPS address
    memset(&vps_addr, 0, sizeof(vps_addr));
    vps_addr.sin_family = AF_INET;
    vps_addr.sin_addr.s_addr = inet_addr(VPS_IP);
    vps_addr.sin_port = htons(VPS_PORT);

    // Prepare IMP address
    memset(&imp_addr, 0, sizeof(imp_addr));
    imp_addr.sin_family = AF_INET;
    imp_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    imp_addr.sin_port = htons(IMP_RECV_PORT);

    maxfd = (sock_imp > sock_frpc ? sock_imp : sock_frpc) + 1;

    printf("\n[READY] Bridge running, press Ctrl+C to stop\n\n");

    // Main loop
    while (running) {
        FD_ZERO(&readfds);
        FD_SET(sock_imp, &readfds);
        FD_SET(sock_frpc, &readfds);

        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 100000;  // 100ms timeout

        int ret = select(maxfd, &readfds, NULL, NULL, &tv);
        if (ret < 0) {
            if (errno == EINTR) continue;
            perror("select");
            break;
        }

        if (ret == 0) continue;  // Timeout

        // Socket 1: Data from IMP → forward to VPS via socket 2
        if (FD_ISSET(sock_imp, &readfds)) {
            len = recvfrom(sock_imp, buffer, BUFFER_SIZE, 0, NULL, NULL);
            if (len > 0) {
                ssize_t sent = sendto(sock_vps, buffer, len, 0,
                                     (struct sockaddr*)&vps_addr, sizeof(vps_addr));
                if (sent > 0) {
                    packets_to_vps++;
                    bytes_to_vps += sent;
                    if (verbose) {
                        printf("[IMP→VPS] %zd bytes\n", sent);
                    }
                } else {
                    perror("sendto VPS");
                }
            }
        }

        // Socket 3: Data from FRPC → forward to IMP via socket 1
        if (FD_ISSET(sock_frpc, &readfds)) {
            len = recvfrom(sock_frpc, buffer, BUFFER_SIZE, 0, NULL, NULL);
            if (len > 0) {
                // Send to IMP using sock_imp (which is bound to 11199)
                // This automatically sets source port to 11199!
                ssize_t sent = sendto(sock_imp, buffer, len, 0,
                                     (struct sockaddr*)&imp_addr, sizeof(imp_addr));
                if (sent > 0) {
                    packets_to_imp++;
                    bytes_to_imp += sent;
                    if (verbose) {
                        printf("[VPS→IMP] %zd bytes (sourceport=%d)\n", sent, IMP_SEND_PORT);
                    }
                } else {
                    perror("sendto IMP");
                }
            }
        }
    }

    // Cleanup
    printf("\n[SHUTDOWN] Closing sockets...\n");
    close(sock_imp);
    close(sock_vps);
    close(sock_frpc);

    print_stats();
    return 0;
}
