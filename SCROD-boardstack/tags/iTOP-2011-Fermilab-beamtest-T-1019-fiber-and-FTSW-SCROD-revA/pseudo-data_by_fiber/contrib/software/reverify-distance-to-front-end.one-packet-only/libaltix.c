#include <stdlib.h>
#include <stdio.h>
#include "libaltix.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/time.h>
#include <poll.h>

static const int BEAM_TEST_PACKET_SIZE =140*4;
static const int BEAM_TEST_EVENT_SIZE = 140*130*4;

int altix_event_size(){return BEAM_TEST_EVENT_SIZE;}
int altix_packet_size(){return BEAM_TEST_PACKET_SIZE;}

static int num_cards = -1;

static altix_pci_card_info* cards = NULL;
static altix_pci_card_stat * stats = NULL;
static inline int is_initialized()
{
	if(num_cards == -1)
	{
		fprintf(stderr, "libaltix: Run the initialization function first.\n");
		return 0;
	}
	return 1;
}

int altix_initialize(char* dev)
{
	int fd, version;
	#ifdef ALTIX_DEBUG
		if(geteuid() != 0)
		{
			printf("libaltix:  Most setups will require root privileges to access the PCI device\n");
		}
	#endif
	fd = open(dev, O_RDWR);
	if (fd <0)
	{
		fprintf(stderr, "libaltix: could not open device %s, make sure the driver is loaded.\n", dev);
		return ALTIX_NOT_INITIALIZED;
	}
	version = altix_get_kernel_version(fd);
	if(version < 0)
	{
		fprintf(stderr, "libaltix: could not read driver version of %s\n", dev);
		return ALTIX_NOT_INITIALIZED;
	}
	if(version != ALTIX_DRIVER_VERSION)
	{
		fprintf(stderr, "libaltix: Warning driver version missmatch!\n   libalitx version 1.%d\n   driver version: 1.%d\n", ALTIX_DRIVER_VERSION, version);
	}
	if(ioctl(fd, ALTIX_IOCTL_NUM, &num_cards) != 0)
	{
		fprintf(stderr, "libaltix: ioctl ALTIX_IOCTL_NUM failed, make sure the driver is loaded\n");
		num_cards = -1;
		return ALTIX_NOT_INITIALIZED;
	}
	#ifdef ALTIX_DEBUG
		printf("libaltix: %d pci cards\n", num_cards);
	#endif
	cards = malloc(sizeof(altix_pci_card_info)*num_cards);
	memset(cards, 0x00, sizeof(altix_pci_card_info)*num_cards);
	close(fd);
	return num_cards;
}

altix_pci_card_info* altix_get_cards(int fd, int *result)
{
	if(!is_initialized()) return NULL;
	int i;
	if(ioctl(fd, ALTIX_IOCTL_INFO, cards) != 0)
	{
		printf("libaltix: ioctl ALTIX_IOCTL_INFO failed, make sure the driver is loaded\n");
		*result = ALTIX_NOT_INITIALIZED;
		return NULL;
	}
	#ifdef ALTIX_DEBUG
	for(i = 0; i< num_cards;i++)
	{
		printf("Card %d: \n   id %d, \n   memsize %d\n   Master PID: %d\n", i, cards[i].id, cards[i].memlen, cards[i].pid);
	}
	#endif
	*result = ALTIX_OK;
	return cards;
}

 int altix_lock_card(int fd, int id)
{
	int cid = id;
	if(!is_initialized()) return ALTIX_NOT_INITIALIZED;
	if(ioctl(fd, ALTIX_IOCTL_LOCK, &cid) == 0) 
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix: Locked %d \n", id);
		#endif
		return ALTIX_OK;
	}
	if(errno == EBUSY)
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix:Card %d already in use\n", id);
		#endif
		return ALTIX_CARD_BUSY;
	}
	else
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix: Could not find card with id %d\n", id);
		#endif
		return ALTIX_CARD_NOT_VALID;
	}
}

 int altix_release_card(int fd, int id)
 {
	int cid = id;
	if(!is_initialized()) return ALTIX_NOT_INITIALIZED;
	if(ioctl(fd, ALTIX_IOCTL_RELEASE, &cid) == 0)
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix: unocked %d \n", id);
		#endif
		return ALTIX_OK;
	}
	if(errno == EBUSY)
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix:Card %d is not locked by this process\n", id);
		#endif
		return ALTIX_CARD_BUSY;
	}
	else
	{
		#ifdef ALTIX_DEBUG
			printf("libaltix: Could not find card with id %d\n", id);
		#endif
		return ALTIX_CARD_NOT_VALID;
	}
 }

int altix_toggle_dma(int fd)
{
	if(!is_initialized()) return ALTIX_NOT_INITIALIZED;
	if(ioctl(fd, ALTIX_IOCTL_DMA) == 0)
		return ALTIX_OK;
	return ALTIX_CARD_NOT_VALID;
}

 const altix_pci_card_stat* altix_get_stats(int fd, int *result)
 {
	if(!is_initialized()) return NULL;
	int i;
	if(stats == NULL)
		stats = (altix_pci_card_stat*)malloc(sizeof(altix_pci_card_stat)*num_cards);
	if(ioctl(fd, ALTIX_IOCTL_STAT, stats) != 0)
	{
		printf("libaltix: ioctl  ALTIX_IOCTL_STAT failed, make sure the driver is loaded\n");
		*result = ALTIX_NOT_INITIALIZED;
		return NULL;
	}
	#ifdef ALTIX_DEBUG
	printf("libaltix: Card Statistics:\n");
	for(i = 0; i< num_cards;i++)
	{
		printf("Card %d: \n   read: %lluMB\n   written bytes: %lluMB\n   Racces:  %u\n   Wacces:  %u\n", stats[i].id, stats[i].bytes_read/1024/1024, stats[i].bytes_written/1024/1024, stats[i].num_reads, stats[i].num_writes);
	}
	printf("\n");
	#endif
	*result = ALTIX_OK;
	return stats;
 }

int altix_switch_channel(int fd, int channel)
{
	if(!is_initialized()) return 0;
	if ((channel < 0) | (channel > 3))
	{
		printf("Channel is out of range %d\n", channel);
	}
	if(ioctl(fd, ALTIX_IOCTL_CHAN, channel) == 0)
		return ALTIX_OK;
	if(errno == EBUSY)
		return ALTIX_CARD_BUSY;
	return ALTIX_CARD_NOT_VALID;
}

int altix_enable_chan(int fd, int on)
{
	if(!is_initialized()) return 0;
	if(ioctl(fd, ALTIX_IOCTL_CHAN_ENABLE, on) == 0)
		return ALTIX_OK;
	if(errno == EBUSY)
		return ALTIX_CARD_BUSY;
	return ALTIX_CARD_NOT_VALID;	
}

int altix_chan_status(int fd, int* stat)
{
    if(!is_initialized()) return 0;
    if(ioctl(fd, ALTIX_IOCTL_CHAN_STATUS, stat) == 0)
		return ALTIX_OK;
	if(errno == EBUSY)
		return ALTIX_CARD_BUSY;
	return ALTIX_CARD_NOT_VALID;
}

void* altix_read_event(int fd, void* buff)
{
	int error;
	int allocated = 0;
	int size = BEAM_TEST_EVENT_SIZE;
	if(!is_initialized()) return 0;
	if(buff == NULL)
	{
		allocated = 1;
		buff = malloc(BEAM_TEST_EVENT_SIZE);
	}
	while(size > 0)
	{
		error = read(fd, (char*)buff + BEAM_TEST_EVENT_SIZE - size, size);
		if(error <0)
		{
			#ifdef ALTIX_DEBUG
				printf("Packet read failed with error %d. Is the card locked and DMA enabled?\n", error);
			#endif
			if(allocated)
				free(buff);
			return NULL;
		}
		size -=error;
	}
	return buff;
}

int altix_send_command(int fd, void* buff)
{
	int error;
	int size = BEAM_TEST_PACKET_SIZE;
	if(!is_initialized()) return 0;
	while(size > 0)
	{
		error = write(fd, (char*)buff + BEAM_TEST_PACKET_SIZE - size, size);
		if(error <0)
		{
			#ifdef ALTIX_DEBUG
				printf("Packet write failed with error %d. Is the card locked and DMA enabled?\n", error);
			#endif
			return ALTIX_CARD_NOT_VALID;
		}
		size -=error;
	}
	return BEAM_TEST_PACKET_SIZE;
}

int altix_poll_read(int fd)
{
	int ret;
    struct pollfd fds;
    if(!is_initialized()) return 0;
    fds.fd = fd;
    fds.events = POLLIN;
    ret = poll(&fds, 1, 100);
    if (fds.revents & POLLIN)
    {
		#ifdef ALTIX_DEBUG
			printf("Read poll: even data is available\n");
		#endif		
        return 1;
    }
    #ifdef ALTIX_DEBUG
		printf("Read poll: even data is unavailable\n");
	#endif		
    return 0;
}

int altix_poll_write(int fd)
{
	int ret;
    struct pollfd fds;
    if(!is_initialized()) return 0;
    fds.fd = fd;
    fds.events = POLLOUT;
    ret = poll(&fds, 1, 100);
    if (fds.revents & POLLOUT)
    {
		#ifdef ALTIX_DEBUG
			printf("Write poll: command data can be send\n");
		#endif		
        return 1;
    }
    #ifdef ALTIX_DEBUG
		printf("Write poll: command data can't be sent, fifo is full\n" );
	#endif		
    return 0;
}

int altix_get_kernel_version(int fd)
{
	int version;
	ioctl(fd, ALTIX_IOCTL_VERSION, &version);
	#ifdef ALTIX_DEBUG
		printf("Kernel Driver version: 1.%d Library version: 1.%d\n", version, ALTIX_DRIVER_VERSION);
	#endif
	if (version > 0)
		return version;	
	else 
		return ALTIX_CARD_NOT_VALID; 
}



#ifdef ALTIX_LIB_MAIN
int main(int argc, char** argv)
{
	if(argc != 2)
		return 0;
	int count = 0;
	char temp;
	char* data;
	int res;
	int fd = open("/dev/altixpci0", O_RDWR);
	int input = open(argv[1], O_RDONLY);
	if(input < 0)
	{
		printf("Bad File\n");
		return 0;
	}
	while(read(input, &temp, 1))
	{
		count++;
	}
	printf("Sending %d bytes\n", count);
	lseek(input, 0,SEEK_SET);
	data = (char*)malloc(count);
	read(input, data, count);
	altix_initialize("/dev/altixpci0");
	altix_get_cards(fd, &res);
	altix_lock_card(fd, 8);
	altix_toggle_dma(fd);
	altix_switch_channel(fd, 1);
	write(fd, data, altix_packet_size());
	close(input);
	close(fd);
	return 0;
}
#endif
