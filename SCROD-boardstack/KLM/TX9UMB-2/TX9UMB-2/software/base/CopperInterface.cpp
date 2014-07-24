#include <stdexcept>
#include <stdio.h>
#include <cstring>

#include "base/CopperInterface.h"

using namespace std;

//
// COPPER device
//

CopperDevice::CopperDevice()
{
}

CopperDevice::~CopperDevice()
{
}

void CopperDevice::close()
{
}

void CopperDevice::send_data(unsigned char* data, int length, unsigned int timeout) const
{
}

int CopperDevice::receive_data(unsigned char* data, int length, unsigned int timeout) const
{
}

//
// COPPER interface
//

CopperInterface::CopperInterface()
{
}

CopperInterface::~CopperInterface()
{
}
