#ifndef INCLUDE_SCROD_PACKET
#define INCLUDE_SCROD_PACKET

#include <vector>
#include <stdint.h>

#include "base/defines.h"

class ScrodPacket
	/// Class for building command/data packets
{
	friend class DetectorInterface;

public:
	ScrodPacket();
		/// Constructor.
		
	virtual ~ScrodPacket();
		/// Destructor.

	void create_command_ping(scrod_word cmd_id, bool silent = true);
		/// Creates a 'ping' command.
		
	void create_command_read(scrod_address reg_addr, scrod_word cmd_id, bool silent = true);
		/// Creates a 'read' command.
		
	void create_command_write(scrod_address reg_addr, scrod_register value, scrod_word cmd_id, bool silent = true);
		/// Creates a 'write' command.
		
	bool is_okay() const;
		/// Returns true if this is ackn. packet.
	
	scrod_word get_command_id() const;
		/// Returns the command ID
		
	scrod_word get_command_type() const;
		/// Returns the type of the command.
		
	scrod_word get_register_value() const;
		/// Returns the value of the register within the reply packet.
	

protected:

	void create_command(const scrod_word command, scrod_word cmd_id, bool silent = true);
		/// Creates a command packet.
	
	unsigned char* get_raw_data();
		/// Returns a pointer to the raw data.
		
	int get_raw_data_length();
		/// returns the length of raw data.
		
	// for reading
	void prepare_size(int size, bool resize = false);
		/// Prepares vector to have at least this size.
		/// It also defines the size of the vector if 'resize' option is given.
	
	const scrod_word get_payload_length() const;
		/// Return the length of the payload.
	
	
private:

	void reset_content();
	
	void finalize_packet();
	
private:

	std::vector<scrod_word>	_data;
	scrod_word				_checksum; // sum of everything, except [1] = length field
};

inline void ScrodPacket::reset_content()
{
	_data.clear();
	_checksum = 0;
}

inline void ScrodPacket::finalize_packet()
{
	_data[1] = _data.size()+1-2;
	_data.push_back(_data[1]+_checksum);
}

inline unsigned char* ScrodPacket::get_raw_data()
{
	return (unsigned char*)_data.data();
}

inline int ScrodPacket::get_raw_data_length()
{
	return _data.size()*sizeof(scrod_word);
}

inline void ScrodPacket::prepare_size(int size, bool resize)
{
	_data.reserve(size);
	if(resize)
		_data.resize(size);
}

inline const scrod_word ScrodPacket::get_payload_length() const
{
	return _data[1];
}

inline bool ScrodPacket::is_okay() const
{
	return _data[2] == PACKET_TYPE_ACKNOWLEDGE;
}

inline scrod_word ScrodPacket::get_command_id() const
{
	return _data[4];
}

inline scrod_word ScrodPacket::get_command_type() const
{
	return _data[5];
}

inline scrod_word ScrodPacket::get_register_value() const
{
	return (_data[6] >> 16) & 0x0000FFFF;
}

#endif
