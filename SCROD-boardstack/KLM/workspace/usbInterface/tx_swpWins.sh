echo 'This command will sweep a certain parameter in TX registers'
echo 'Usage: tx_swpParams reg start end'

ASICno=9
NEVT=50

for WINn in {0..127}
do
WINs=$((0+4*WINn))
WINe=$((3+4*WINn))

bin/tx_takedatarecord1 $NEVT 0 $WINs $WINe $ASICno 1
bin/tx_parse1 outdir/out_txrec1.dat 1
mv outdir/out_txrec1.dat.txt "outdir/psweep/swp_asic$ASICno wins$WINs.txt"

done






