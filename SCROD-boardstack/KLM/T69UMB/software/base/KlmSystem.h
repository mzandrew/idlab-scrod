#ifndef INCLUDE_KLMSYSTEM
#define INCLUDE_KLMSYSTEM

#include "base/UsbInterface.h"	
#include "base/KlmModule.h"

#define SCROD_REGISTER_ID	276

class KlmSystem
	/// Class encapsulating the entire KLM system readout.
{
public:

	~KlmSystem();
		/// Destructor.
		
	void initialize(std::ostream& output, char* configuration = NULL);
		/// Initialize the detector system.
		/// 'configuration' should hold the file name of
		/// the config XML file, or NULL if configuration
		/// should be skipped.
		
	void uninitialize();
		/// Uninitialize the detector system.
		
	KlmModule* operator[](module_id id);
		/// Returns KlmModule or NULL if it is not found.

	// static function
	static KlmSystem& KLM();
		/// Return singelton handle.
	
	static void Cleanup();
		/// Cleans up.
	
protected:
	
private:

	KlmSystem();
		/// Unreachable constructor.

private:

	typedef std::map<module_id, KlmModule*> KlmModuleMap;
	
	KlmModuleMap _modules;

	static KlmSystem* _singleton;
};

#endif
