#!/bin/bash
for row in 0 1 2 3
do
	for col in 0 1 2 3
	do
		for ch in 0 1 2 3 4 5 6 7
		do
			./bin/irs3BControl_measureTriggerThresholds $row $col $ch
		done
	done
done
