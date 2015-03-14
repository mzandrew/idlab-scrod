echo 'This command will sweep a certain parameter in TX registers'
echo 'Usage: tx_swpParams reg start end'

ASICno=9
REGno=66 
WINs=200
WINe=203
NEVT=10

for REGVAL in {10..20}
do

/usr/bin/python /home/isar/workspace/usbInterface/sigen/use_func.py 2 0 0 400
bin/target6Control_writeDacReg $ASICno $REGno $REGVAL
bin/tx_onboard_pedcalc01 0 $WINs $WINe $ASICno
/usr/bin/python /home/isar/workspace/usbInterface/sigen/use_func.py 2 1 0 400
bin/tx_takedatarecord1 $NEVT 0 $WINs 0 $ASICno 1
bin/tx_parse1 outdir/out_txrec1.dat 1
mv outdir/out_txrec1.dat.txt "outdir/psweep/swp_asic$ASICno wins$WINs regno$REGno regval $REGVAL.txt"


done






