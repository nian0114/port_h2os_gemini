DEVICE=gemini;

CPU=arm64;
FSTABLE=3221225472;

USER=`whoami`

echo "Start to Build H2OS ($DEVICE)"

if [ -d "workspace" ]; then
	echo "Cleaning Up..."
	sudo umount /dev/loop0
	rm -rf workspace $DEVICE-h2os-6.0.zip final/*
else
	rm -rf $DEVICE-h2os-6.0.zip final/*
fi

mkdir -p workspace/output workspace/app

if [ ! -f "stockrom/system.new.dat" ]; then

  if [ ! -f "stockrom/boot.img" ];then
    exit
  else
    cp -rf stockrom/system workspace/
    cp -f stockrom/boot.img workspace/
    cp -rf tools/system.patch.dat stockrom/system.patch.dat
    export IMG=0
  fi

else

  if [ ! -f "stockrom/boot.img" ];then
    exit
  else
    cp -f stockrom/system.transfer.list workspace/
    cp -f stockrom/system.new.dat workspace/
    cp -f stockrom/boot.img workspace/
    export IMG=1
  fi

fi

cd workspace

if [ ${IMG} = 1 ]; then
  echo "Extract System.img ..."
  ./../tools/sdat2img.py system.transfer.list system.new.dat system.img &> /dev/null
  sudo mount -t ext4 -o loop system.img output/
  sudo chown -R $USER:$USER output
else
  echo "Copy System to Output ..."
  cp -rf ../stockrom/system/* output/
fi

VERSION_TMP=`cat output/build.prop |grep "ro.rom.version"`
VERSION=${VERSION_TMP:21}

if [ -d output/framework/$CPU ];then
	echo "Start Odex System ..."
	cp -rf ../tools/odex/* $PWD
	cp -rf output/* superr_miui/system/
	mv superr_miui/system/vendor/app/colorservice superr_miui/system/app/
	mv superr_miui/system/vendor/app/ims superr_miui/system/app/
	mv superr_miui/system/vendor/app/imssettings superr_miui/system/app/

	./superr

	cp -rf output/framework/arm superr_miui/system/framework/
	cp -rf output/framework/arm64 superr_miui/system/framework/

	rm -rf output/vendor/app/colorservice
	rm -rf output/vendor/app/ims
	rm -rf output/vendor/app/imssettings

	rm -rf output/framework
	rm -rf output/priv-app
	rm -rf output/app

	mv superr_miui/system/app output/
	mv superr_miui/system/framework output/
	mv superr_miui/system/priv-app output/

	mv output/app/colorservice output/vendor/app/
	mv output/app/ims output/vendor/app/
	mv output/app/imssettings output/vendor/app/

	rm -rf superr_miui
	rm -rf tools
	rm -rf superr
fi

echo "Disable Recovery Auto Install ..."
rm -rf output/recovery-from-boot.p
rm -rf output/bin/install-recovery.sh

echo "Start Xiaomi Port"
rm -rf output/app/LatinIME  output/app/Nfc*  output/appLiveWallpapers  output/appNoiseField  output/app/OEMLogKit  output/app/OpenWnn
rm -rf output/bin/qfipsverify  output/bin/qfp-daemon  output/bin/secure_camera_sample_client
rm -rf output/etc/acdbdata/Fluid  output/etc/acdbdata/Liquid  output/etc/acdbdata/MTP  output/etc/acdbdata/QRD
rm -rf output/etc/camera/imx179_chromatix.xml output/etc/cne/wqeclient output/etc/stargate
rm -rf output/etc/firmware/mbn_ota output/etc/firmware/tp
rm -rf output/etc/qdcm_calib_data_samsung* policy_nx6p
rm -rf output/lib/libFNVfbEngineHAL.so output/lib/lib_fpc_tac_shared.so output/lib/hw/fingerprint.msm8996.so output/lib/hw/nfc_nci.pn54x.default.so output/lib/hw/sensors.hub.so output/lib/hw/modules/msm-buspm-dev.ko
rm -rf output/lib64/lib_fpc_tac_shared.so output/lib64/hw/fingerprint.msm8996.so output/lib64/hw/sensors.hub.so
rm -rf output/reserve/*
rm -rf output/usr/qfipsverify
rm -rf output/usr/keylayout/fpc1020.kl
rm -rf output/vendor/etc/RIDL/GoldenLogmask.dmc output/vendor/etc/RIDL/OTA-Logs.dmc output/vendor/etc/RIDL/RIDL.db
rm -rf output/vendor/lib/rfsa/adsp/libAMF_hexagon_skel.so output/vendor/lib/rfsa/adsp/libmare_hexagon_skel.so
rm -rf output/vendor/lib/libsensor_thresh.so output/vendor/lib64/libsensor_thresh.so
rm -rf output/vendor/lib64/hw/fingerprint.qcom.so_not_use

cp -rf ../tools/gemini/system/* output/
rm -rf output/app/DiracManager output/app/DiracAudioControlService output/vendor/etc/diracvdd.bin output/vendor/lib/rfsa/adsp/libdirac-appi.so

echo "Hack System Assest"
cd app
cp -rf ../../tools/apktool* $PWD
cp -rf ../../tools/git.apply $PWD
cp -rf ../../tools/rmline.sh $PWD

cp -rf ../output/framework/services.jar services.jar
./apktool d services.jar &> /dev/null
./git.apply  ../../tools/patches/services_assest.patch
./git.apply  ../../tools/patches/fastcharge.patch
./apktool b services.jar.out &> /dev/null
mv services.jar.out/dist/services.jar ../output/framework/

mkdir -p Settings_tmp
mv ../output/priv-app/Settings/Settings.apk Settings.apk
./apktool d Settings.apk &> /dev/null
sed -i "/\s*ic_settings_zenmode.*$/d" `grep ic_settings_zenmode -rl --include="*.xml" Settings/res/xml`
./git.apply  ../../tools/patches/OPIQSettings.patch
./apktool b Settings &> /dev/null
mv Settings.apk Settings_tmp/Settings.zip
cd Settings_tmp
unzip Settings.zip &> /dev/null
rm -rf res/xml
cp -rf ../Settings/build/apk/classes.dex classes.dex
cp -rf ../Settings/build/apk/res/xml res/xml
zip -q -r "../../output/priv-app/Settings/Settings.apk" 'META-INF' 'resources.arsc' 'res' 'AndroidManifest.xml' 'classes.dex' &> /dev/null
cd ..

cd ..
rm -rf app

if [ -d ../tools/third-app ];then
	echo "Add Third App ..."
	cp -rf ../tools/third-app/* output/reserve
fi

#sed -i "/\s*ro.build.product.*$/d" output/build.prop
#sed -i "/\s*ro.build.user.*$/d" output/build.prop
#sed -i "/\s*ro.build.flavor.*$/d" output/build.prop
#sed -i "/\s*ro.build.description.*$/d" output/build.prop
#sed -i "/\s*ro.product.brand.*$/d" output/build.prop
#sed -i "/\s*ro.product.manufacturer.*$/d" output/build.prop
#sed -i "/\s*ro.frp.pst.*$/d" output/build.prop
#sed -i "/\s*persist.radio.multisim.config.*$/d" output/build.prop
#sed -i "/\s*persist.radio.rat_on.*$/d" output/build.prop
#sed -i "/\s*ro.build.host.*$/d" output/build.prop
#sed -i "/\s*ril.subscription.types.*$/d" output/build.prop
#sed -i "/\s*qcom.hw.aac.encoder.*$/d" output/build.prop
#sed -i "/\s*VENDOR_EDIT.*$/d" output/build.prop
#sed -i "/\s*mm.enable.qcom_parser.*$/d" output/build.prop
#sed -i "/\s*ro.qualcomm.foss.*$/d" output/build.prop
#sed -i "/\s*ro.qualcomm.display.paneltype.*$/d" output/build.prop
#sed -i "/\s*config.foss.*$/d" output/build.prop
#sed -i "/\s*persist.radio.sw_mbn_update.*$/d" output/build.prop
#sed -i "/\s*persist.radio.hw_mbn_update.*$/d" output/build.prop
#sed -i "/\s*persist.radio.start_ota_daemon.*$/d" output/build.prop
#sed -i "/\s*ro.bluetooth.wipower.*$/d" output/build.prop
#sed -i "/\s*ro.bluetooth.emb_wp_mode.*$/d" output/build.prop
#sed -i "/\s*audio.offload.pcm.16bit.enable.*$/d" output/build.prop
#sed -i "/\s*ro.am.reschedule_service=.*$/d" output/build.prop
#sed -i "/\s*audio.parser.ip.buffer.size.*$/d" output/build.prop
#sed -i "/\s*ro.dbg.coresight.config.*$/d" output/build.prop
#sed -i "/\s*ro.sys.fw.bg_apps_limit.*$/d" output/build.prop
#sed -i "/\s*audio.offload.min.duration.secs.*$/d" output/build.prop
#sed -i "/\s*persist.dirac.acs.controller.*$/d" output/build.prop
#sed -i "/\s*dalvik.vm.heapstartsize.*$/d" output/build.prop
#sed -i "/\s*drm.service.enabled.*$/d" output/build.prop
#sed -i "/\s*af.fast_track_multiplier.*$/d" output/build.prop
#sed -i "/\s*ro.com.google.clientidbase.*$/d" output/build.prop
#sed -i "/\s*#.*$/d" output/build.prop
#cat ../tools/build.prop.addition >> output/build.prop
sed -i -e "s/ro\.rom\.version=.*/$VERSION_TMP/g" output/build.prop

echo "Build system.new.dat ..."
./../tools/make_ext4fs -T 0 -S ../tools/file_contexts -l $FSTABLE -a system system_new.img output/ &> /dev/null

cd ../

echo "Final Step ..."

cp -rf tools/META-INF final/META-INF
cp -rf tools/gemini/boot.img final/boot.img
cp -rf workspace/system_new.img final/system.img 
cp -rf tools/root final/

cd final
zip -q -r "../$DEVICE-h2os-$VERSION-6.0.zip" 'boot.img' 'META-INF' 'system.img' 'root'
cd ..

sudo umount /dev/loop0
rm -rf workspace final/*
cd
