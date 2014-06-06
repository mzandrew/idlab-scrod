#!/bin/bash
for row in 0 1 2 3
do
	for col in 0 1 2 3
	do
		for ch in 0 1 2 3 4 5 6 7
		do
			./bin/irs3BControl_takeForcedTriggers $row $col $ch 0 1000
		done
	done
done
