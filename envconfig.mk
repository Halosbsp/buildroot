include $(HALOS_CONFIG)

export TOOLCHAIN_HOST
export COTEXM_TOOLCHAIN
export TARGET_PRODUCT_ID
export UBOOT_PATH
#####################build path##############
ifdef BOARDCHIP_HISI_3519
UBOOT_PATH:=opensource/uboot/hisi_3519
else ifdef BOARDCHIP_HISI_3559
UBOOT_PATH:=opensource/uboot/hisi_3559
else ifdef BOARDCHIP_NOVATEK
UBOOT_PATH:=opensource/uboot/novatek
else ifdef BOARDCHIP_TI
UBOOT_PATH:=opensource/uboot/ti
else ifdef BOARDCHIP_ROCKCHIP
UBOOT_PATH:=opensource/uboot/rockchip
endif
#################toolchain option######################
ifdef BOARDCHIP_HISI_3519
TOOLCHAIN_HOST:=arm-himix200-linux-
else ifdef BOARDCHIP_HISI_3559
TOOLCHAIN_HOST:=aarch64-himix100-linux-
else ifdef BOARDCHIP_NOVATEK
TOOLCHAIN_HOST:=arm-ca53-linux-gnueabihf-
else ifdef BOARDCHIP_TI
TOOLCHAIN_HOST:=xxxxxxxx-
else ifdef BOARDCHIP_ROCKCHIP
TOOLCHAIN_HOST:=gcc-arm-linux-gnueabihf-
endif
COTEXM_TOOLCHAIN:=arm-none-eabi-

#################hisi option######################
ifdef BOARDCHIP_HISI
##################hisi 3519#####################
ifdef BOARDCHIP_HISI_3519
ifdef BOARDCHIP_HISI3519_A3
TARGET_PRODUCT_ID:=A3
else ifdef BOARDCHIP_HISI3519_RV
TARGET_PRODUCT_ID:=RV
else ifdef BOARDCHIP_HISI3519_A4H
TARGET_PRODUCT_ID:=A4H
endif
endif
##################hisi 3559#####################
ifdef BOARDCHIP_HISI_3559
TARGET_PRODUCT_ID:=3559
endif

endif
###################end hisi################