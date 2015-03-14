#!/bin/bash

COUNTER=2000
while [  $COUNTER -lt 4000 ]; do
	#echo The counter is $COUNTER

	#Threshold Ch. 1(PCLK_1)
	./bin/target6Control_writeDacReg 0 $COUNTER
	let COUNTER=COUNTER+100
done

exit 0

