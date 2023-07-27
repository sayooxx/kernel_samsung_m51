#!/bin/bash
#
#
#
######################################################

echo " "
KERNEL_DIR=$(pwd)
CURRENT_BUILD_USER=$(whoami)

# 
if [[ ${CURRENT_BUILD_USER} == "neel" ]]; then
    export KBUILD_BUILD_USER=Neel0210
    export KBUILD_BUILD_HOST=Hell
else
    export KBUILD_BUILD_USER=BuildBot
    export KBUILD_BUILD_HOST=KangHub
fi

# Colours
GRN='\033[01;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RED='\033[01;31m'
RST='\033[0m'

# Arch and Android Version
export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=s
export PLATFORM_VERSION="12"

# Kernel related Information
ZIMG=out/arch/arm64/boot/Image
KERNEL_CONFIG=M51_defconfig
TC=$KERNEL_DIR/TC

# Compiler
if [[ -d "${TC}" ]]; then
    echo -e "${CYAN}Exporting path"
    export BUILD_CROSS_COMPILE=$TC/gcc49/bin/aarch64-linux-android-
    export KERNEL_LLVM_BIN=$TC/clang/bin/clang
    export CLANG_TRIPLE=aarch64-linux-gnu-
else
    echo -e "${YELLOW}Clonning toolchain"
    rm -rf $TC/*    
    git clone --branch android-9.0.0_r59 --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $TC/gcc49
    git clone --depth=1 https://github.com/proprietary-stuff/llvm-arm-toolchain-ship-10.0 $TC/clang
    clear
    echo -e "${CYAN}Exporting path"
    export BUILD_CROSS_COMPILE=$TC/gcc49/bin/aarch64-linux-android-
    export KERNEL_LLVM_BIN=$TC/clang/bin/clang
    export CLANG_TRIPLE=aarch64-linux-gnu-    
fi

exit_script() {
    kill -INT $$
}

START(){
    # Calculate compilation time
    START=$(date +"%s")
}

END(){
    if [ -f out/arch/arm64/boot/Image ];then
        clear && FLEX
        echo " " && echo " "
        END=$(date +"%s")
        DIFF=$((END - START))
        echo " " && echo -e "${GRN}Kernel has been compiled successfully and it took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)${RST}"
    else
        exit_script
    fi
}

build(){
    make -j$(nproc --all) -C $(pwd) O=out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE $KERNEL_CONFIG
    make -j$(nproc --all) -C $(pwd) O=out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE V=$VERBOSE 2>&1 | tee error.log
}

FLEX(){
echo -e "${YELLOW}                                                     "
echo " _   __ _   ________ _____                 _       _     "
echo "| | / /| | / /| ___ \_   _|  ___  ___ _ __(_)_ __ | |_ "
echo "| |/ / | |/ / | |_/ / | |   / __|/ __| '__| | '_ \| __|"
echo "|    \ |    \ |    /  | |   \__ \ (__| |  | | |_) | |_  "
echo "| |\  \| |\  \| |\ \  | |   |___/\___|_|  |_| .__/ \__|"
echo "\_| \_/\_| \_/\_| \_| \_/                   |_|         "
echo " "
echo -e "${GRN}                coded by Neel0210  ${RST}"
}

# Device database
M51(){
    DEVICE_KERNEL_BOARD='SRPTD22A004'
    DEVICE_KERNEL_BASE=0x00000000
    DEVICE_KERNEL_PAGESIZE=4096
    DEVICE_RAMDISK_OFFSET=0x02000000
    DEVICE_SECOND_OFFSET=0x00000000
    PLATFORM_VERSION="11.0.0"
    PLATFORM_PATCH_LEVEL="2023-01"
    DEVICE_KERNEL_CMDLINE="console=null androidboot.hardware=qcom androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=1 androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image nokaslr printk.devkmsg=on loop.max_part=7" 
    DEVICE_KERNEL_HEADER=2
    DEVICE_DTB_HASHTYPE='sha1'  
    DEVICE_KERNEL_OFFSET=0x00008000 
    DEVICE_TAGS_OFFSET=0x01e00000
    DEVICE_HEADER_SIZE=1660
}

clean(){
    echo " "    
    echo -e "${RED}                     Cleaning${RST}" && echo " "
    make clean
    make mrproper
}

check_build(){
        echo " " && echo " "
        echo -e "${YELLOW}                     x Building Boot.img x"
        M51
        #
        $(pwd)/tools/make/mkbootimg \
                  --kernel $ZIMG \
                  --cmdline " " --board "$DEVICE_KERNEL_BOARD" \
                  --base $DEVICE_KERNEL_BASE --pagesize $DEVICE_KERNEL_PAGESIZE \
                  --kernel_offset $DEVICE_KERNEL_OFFSET --ramdisk_offset $DEVICE_RAMDISK_OFFSET \
                  --second_offset $DEVICE_SECOND_OFFSET --tags_offset $DEVICE_TAGS_OFFSET \
                  --os_version "$PLATFORM_VERSION" --os_patch_level "$PLATFORM_PATCH_LEVEL" \
                  --header_version $DEVICE_KERNEL_HEADER --hashtype $DEVICE_DTB_HASHTYPE \
                  -o $(pwd)/boot.img
                  sleep 2


if [ -f ${KERNEL_DIR}/boot.img ];then
    echo -e "${GRN}Image has been built at $(pwd)/boot.img${RST}"
else
    echo -e "${RED}Check for error"
fi
}

# UPLOAD
upload(){
    if [ -f $(pwd)/boot.img ];then
        for i in boot.img
        do
        curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
        done
    else
        echo -e "${RED}Boot image not found"
    fi
}

#############################
clear
FLEX
clean
clear && FLEX && START
build
END
check_build
upload

################ END OF LIFE ###############