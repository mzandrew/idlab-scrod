#!/bin/bash

#Set binary directory
BINDIR=./

#set data directory
WORKDIR=/home/copper/crt_data/20140708/
DATADIR=/export/home/copper/crt_data/20140708/data/

REG=$1
REGVAL=$2
FIBRE=$3

echo "Sending: scrod-regw.py " ${REG} " " ${REGVAL} " " ${FIBRE}

#Create script to send to COPPER for taking pedestal + hardware triggers
rm copperCommands_regw.sh
echo -e "#/bin/bash" >> copperCommands_regw.sh
echo -e "cd "${WORKDIR} >> copperCommands_regw.sh
echo "scrod-regw.py " ${REG} " " ${REGVAL} " " ${FIBRE} >> copperCommands_regw.sh
echo -e "exit" >> copperCommands_regw.sh

#send command to COPPER to take software + hardware triggers
cat copperCommands_regw.sh | ssh 192.168.1.203
