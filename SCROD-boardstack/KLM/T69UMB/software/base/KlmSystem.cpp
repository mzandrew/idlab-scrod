#include <stdexcept>
#include <stdio.h>
#include <algorithm>

#include "base/KlmSystem.h"
#include "base/tinyxml2.h"

using namespace std;
using namespace tinyxml2;

KlmSystem* KlmSystem::_singleton = NULL;

KlmSystem& KlmSystem::KLM()
{
	if(_singleton == NULL)
		_singleton = new KlmSystem();
	return *_singleton;
}

void KlmSystem::Cleanup()
{	
	// remove singleton
	if(_singleton)
		delete _singleton;
	_singleton = NULL;
}

KlmSystem::KlmSystem()
{
}

KlmSystem::~KlmSystem()
{
	uninitialize();
}

void KlmSystem::initialize(std::ostream& output, char* configuration)
{
	bool use_usb = false;
	XMLDocument conf;
	const XMLElement* nKLM;
	const char* tmp;
	string value;
	
	if(configuration)
	{
		
		int res = conf.LoadFile(configuration);
		if(res == XML_NO_ERROR)
		{
			nKLM = conf.RootElement();
			tmp = nKLM->Attribute("usb");
			if(tmp != NULL)
			{
				value = tmp;
				std::transform(value.begin(), value.end(), value.begin(), ::tolower);
				if(value == "yes")
				{
					output << "USB connections will be used." << endl;
					use_usb = true;
				}
				else
				{
					output << "USB connections will be ignored." << endl;
					use_usb = false;
				}
			}
			else
			{
				output << "No 'usb' attribute found, presumming no USB connections." << endl;
				use_usb = false;
			}
		}
		else
		{
			output << "ERROR: Config file " << configuration << " could not be loaded." << endl;
			use_usb = false;
			return;
		}
	}
	else
	{
		use_usb = true;
	}

	if(use_usb)
	{
		// 
		// connect all USB devices
		//
		
		// bring up all USB devices
		UsbInterface::USB().open_all_devices(output, 0x04b4, 0x1004);
		
		// convert all USB devices to KLM modules
		std::vector<module_id> ids;
		ids = UsbInterface::USB().getListOfModules();
		
		UsbDevice* dev;
		std::vector<module_id>::iterator x;
		for(x = ids.begin(); x != ids.end(); x++)
		{
			dev = UsbInterface::USB().getDevice(*x);
			if(!dev)
			{
				// this id could not be found among usb devices
				continue;
			}
			
			// ask the module for the true ID
			KlmModule* mod = new KlmModule(dev);
			scrod_word mod_id;
			mod_id = mod->read_register(SCROD_REGISTER_ID);
			//cout << "Module identified with ID=" << mod_id << endl;
			
			// insert
			std::pair<KlmModuleMap::iterator,bool> ret;
			ret = _modules.insert(std::pair<module_id, KlmModule*>(mod_id, mod));
			if(ret.second == false)
			{
				// not inserted, because this id alread exists
				continue;
			}
		}
	}
	
	//
	// Configure
	//
	if(configuration)
	{
		const XMLElement* tmpNode;
		output << "Configuring the modules..." << endl;
		
		// loop through all the modules	
		const XMLElement* kModule = nKLM->FirstChildElement("module");
		while(kModule)
		{
			// get module number
			tmp = kModule->Attribute("id");
			if(tmp != NULL)
			{
				int module_id = atoi(tmp);
				KlmModule* conf_module = this->operator[](module_id);
				if(!conf_module)
				{
					output << "\t( WARNING: module ID=" << module_id <<" not found in the system. Configuration skipped for this module. )" << endl;
					// next one
					kModule = kModule->NextSiblingElement("module");
					continue;
				}
				output << "\tConfiguring module ID=" << module_id << "." << endl;
				
				// get the module with this id
				
				// do all the registers --> pre-asic 
				output << "\t\tSetting SCROD registers (pre-ASIC stage)..." << endl;
				tmpNode = kModule->FirstChildElement("registers");
				if(tmpNode)
				{
					unsigned int reg_addr, reg_value;
					//
					const XMLElement* kRegister = tmpNode->FirstChildElement("register");
					while(kRegister)
					{
						// is it pre-ASIC register
						tmp = kRegister->Attribute("stage");
						if(string(tmp) != "pre")
						{
							// next register
							kRegister = kRegister->NextSiblingElement("register");
							continue;
						}
						
						// get address and value					
						if(kRegister->QueryUnsignedAttribute ("address", &reg_addr) == XML_NO_ERROR && kRegister->QueryUnsignedAttribute ("value", &reg_value) == XML_NO_ERROR)
						{
							// set the register
							output << "\t\t\tSetting register " << reg_addr << " with value " << reg_value << "..." << endl;
							conf_module->write_register(reg_addr, reg_value, true);
						}
						else
						{
							output << "\t\t ERROR: Register setting malformatted." << endl;
						}

						// next register
						kRegister = kRegister->NextSiblingElement("register");
					}
				}
				
				// do all the ASIC registers
				output << "\t\tSetting ASIC registers..." << endl;
				tmpNode = kModule->FirstChildElement("asics");
				if(tmpNode)
				{
					const XMLElement* kAsic = tmpNode->FirstChildElement("asic");
					while(kAsic)
					{
						unsigned int asic_addr;
						if(kAsic->QueryUnsignedAttribute ("slot", &asic_addr) == XML_NO_ERROR)
						{
							output << "\t\t\tSetting registers on ASIC " << asic_addr << endl;
							
							unsigned int reg_addr, reg_value;
							//
							const XMLElement* kRegister = kAsic->FirstChildElement("register");
							while(kRegister)
							{
								// get address and value					
								if(kRegister->QueryUnsignedAttribute ("address", &reg_addr) == XML_NO_ERROR && kRegister->QueryUnsignedAttribute ("value", &reg_value) == XML_NO_ERROR)
								{
									// set the register
									output << "\t\t\t\tSetting register " << reg_addr << " with value " << reg_value << "..." << endl;
									conf_module->write_ASIC_register(asic_addr, reg_addr, reg_value);
								}
								else
								{
									output << "\t\t\t ERROR: Register setting malformatted." << endl;
								}

								// next register
								kRegister = kRegister->NextSiblingElement("register");
							}
									
						}
						else
						{
							output << "\t\t ERROR: ASIC address not specified." << endl;
						}

						// next register
						kAsic = kAsic->NextSiblingElement("asic");
					}
				}

				// do all the registers --> post-asic 
				output << "\t\tSetting SCROD registers (post-ASIC stage)..." << endl;
				tmpNode = kModule->FirstChildElement("registers");
				if(tmpNode)
				{
					unsigned int reg_addr, reg_value;
					//
					const XMLElement* kRegister = tmpNode->FirstChildElement("register");
					while(kRegister)
					{
						// is it pre-ASIC register
						tmp = kRegister->Attribute("stage");
						if(string(tmp) != "post")
						{
							// next register
							kRegister = kRegister->NextSiblingElement("register");
							continue;
						}
						
						// get address and value					
						if(kRegister->QueryUnsignedAttribute ("address", &reg_addr) == XML_NO_ERROR && kRegister->QueryUnsignedAttribute ("value", &reg_value) == XML_NO_ERROR)
						{
							// set the register
							output << "\t\t\tSetting register " << reg_addr << " with value " << reg_value << "..." << endl;
							conf_module->write_register(reg_addr, reg_value, true);
						}
						else
						{
							output << "\t\t ERROR: Register setting malformatted." << endl;
						}

						// next register
						kRegister = kRegister->NextSiblingElement("register");
					}
				}
			}
			else
			{
				output << "No 'id' attribute found, so shipping this part." << endl;
			}
			
			// next one
			kModule = kModule->NextSiblingElement("module");
		}
	}
}

void KlmSystem::uninitialize()
{
	// remove all modules
	KlmModuleMap::iterator x;
	for(x = _modules.begin(); x != _modules.end(); x++)
		delete x->second;
	_modules.clear();
	
	// cleanup USB
	UsbInterface::USB().close_all_devices();
	UsbInterface::Cleanup();
}

KlmModule* KlmSystem::operator[](module_id id)
{
	KlmModuleMap::iterator it = _modules.find(id);
	if(it == _modules.end())
		return NULL;
	else
		return it->second;
}

void KlmSystem::start()
{
	KlmModuleMap::iterator x;
	for(x = _modules.begin(); x != _modules.end(); x++)
		x->second->start();
}

void KlmSystem::stop()
{
	KlmModuleMap::iterator x;
	for(x = _modules.begin(); x != _modules.end(); x++)
		x->second->stop();
}
