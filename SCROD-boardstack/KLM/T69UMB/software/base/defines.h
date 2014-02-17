#ifndef INCLUDE_DEFINES
#define INCLUDE_DEFINES

#define SCROD_REGISTER_T6_ADDRESS	2
#define SCROD_REGISTER_T6_DATA		3
#define SCROD_REGISTER_T6_STROBE	1
#define SCROD_REGISTER_T6_SPEED_1 	5
#define SCROD_REGISTER_T6_SPEED_2 	6

#define T6_SPEED_1_DEFAULT 128
#define T6_SPEED_2_DEFAULT 320

#define START_PACKET_SIZE	256

typedef uint32_t scrod_word;
typedef scrod_word    module_id;
typedef uint16_t scrod_register;
typedef uint16_t scrod_address;

#define PACKET_HEADER           (0x00BE11E2) /* hex:BELLE2   */
#define PACKET_TYPE_COMMAND     (0x646f6974) /* ascii:"doit" */
#define PACKET_TYPE_ACKNOWLEDGE (0x6f6b6179) /* ascii:"okay" */
#define PACKET_TYPE_ERROR       (0x7768613f) /* ascii:"wha?" */
#define COMMAND_TYPE_PING       (0x70696e67) /* ascii:"ping" */
#define COMMAND_TYPE_READ       (0x72656164) /* ascii:"read" */
#define COMMAND_TYPE_WRITE      (0x72697465) /* ascii:"rite" */

#define DESTINATION_BROADCAST   (0x00000000) /* broadcast destination */
#define FLAG_RESPONSE_NO		(0x80000000) /* request response*/

#define USB_IN__ENDPOINT (0x86)
#define USB_OUT_ENDPOINT (0x02)

#endif
