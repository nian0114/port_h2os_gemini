hwversion=`getprop ro.boot.hwversion`

bus_name="/dev/i2c-9"

case $hwversion in
    1*) firmware_name="/etc/firmware/tfa98xx.cnt" ;;
    2*) firmware_name="/etc/firmware/tfa98xx.cnt" ;;
    4*) firmware_name="/etc/firmware/tfa9891.cnt" ;;
    7*) firmware_name="/etc/firmware/tfa9891.cnt" ;;
    8*) firmware_name="/etc/firmware/tfa9891.cnt"
        bus_name="/dev/i2c-3"
        ;;
    *)  firmware_name="/etc/firmware/tfa9891.cnt" ;;
esac

climax_hostSW  -d $bus_name --slave=0x34 --xmem=0x1027f -w0x400001 2>&1 >> /data/cit.audio.cal.txt
sleep 2
climax_hostSW  -d $bus_name --slave=0x34 --xmem=0x1027f -w0x66666 2>&1 >> /data/cit.audio.cal.txt
sleep 2
climax_hostSW -d $bus_name -l $firmware_name --count=20 --dumpmodel=z --cit 2>&1 >> /data/audio.cit.cal.txt
