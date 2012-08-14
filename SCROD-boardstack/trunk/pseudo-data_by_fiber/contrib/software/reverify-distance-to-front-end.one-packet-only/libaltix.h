#ifndef  LIB_ALTIX_HEADER
#define LIB_ALTIX_HEADER
#include <stdint.h>
#include "altix_userland.h"


#define ALTIX_OK 0
#define ALTIX_NOT_INITIALIZED -1
#define ALTIX_CARD_BUSY -2
#define ALTIX_CARD_NOT_VALID -3

/**
 * Initialization routine. Run this function before any other library function
 */
int altix_initialize(char* dev);

/**
 * Returns an array of altix_pci_card_info
 */
altix_pci_card_info* altix_get_cards(int fd, int *result);

/**
 * Selects a card to be used by a file desctiptor.
 */
 int altix_lock_card(int fd, int id);
 
/**
 * Release a card from file descriptor control.
 */ 
 int altix_release_card(int fd, int id);

/**
 * Gather performance info from the card.
 */
 const altix_pci_card_stat* altix_get_stats(int fd, int *result);

/**
 * Enable DMA
 */ 
 int altix_toggle_dma(int fd);

/**
 * Switch between channels
 */
 int altix_switch_channel(int fd, int channel);

/**
 * Read an event in beam test format
 */
 void* altix_read_event(int fd, void* buff);
 
 /**
  * Write command in beam test format
 */
 int altix_send_command(int fd, void* buff);

/**
 * Poll current card and channel for read
 */
int altix_poll_read(int fd);

/**
 * Poll current card and channel for write
 */
int altix_poll_write(int fd);

/**
 * Reset the current channel
 */
int altix_enable_chan(int fd, int on);

/**
 * Get channel Aurora link status mask. Lower 4 bits represent the status
 */
int altix_chan_status(int fd, int* stat);


/**
 * Get event size in bytes. this value is fixed
 */
int altix_event_size(void);

/**
 * Get command packet size in bytes. this value is fixed
 */
int altix_packet_size(void);



/**
 * Get the Kernel Version
 */
int altix_get_kernel_version(int fd);
 
 
 
#endif
