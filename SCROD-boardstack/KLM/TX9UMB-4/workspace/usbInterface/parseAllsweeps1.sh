FILES='/home/isar/workspace/usbInterface/outdir/sweeps/*.dat' 

for f in $FILES
do 

bin/tx_parse1 $f 1

done

