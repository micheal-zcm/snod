# Android makefile for the WLAN Module

# Assume no targets will be supported
WLAN_CHIPSET :=

# Build/Package options for 8916, 8974, 8226, 8610, 8909, 8952, 8937, 8953 targets
ifneq (,$(filter msm8916 msm8974 msm8226 msm8610 msm8909 msm8952 msm8937 msm8953 msm8953,$(TARGET_BOARD_PLATFORM)))
WLAN_CHIPSET := qcacld-2.0
WLAN_SELECT := CONFIG_QCA_CLD_WLAN=m
endif

# Build/Package only in case of supported target
ifneq ($(WLAN_CHIPSET),)
LOCAL_PATH := $(call my-dir)

# This makefile is only for DLKM
ifneq ($(findstring vendor,$(LOCAL_PATH)),)

# Determine if we are Proprietary or Open Source
ifneq ($(findstring opensource,$(LOCAL_PATH)),)
    WLAN_PROPRIETARY := 0
    WLAN_OPEN_SOURCE := 1
else
    WLAN_PROPRIETARY := 1
    WLAN_OPEN_SOURCE := 0
endif

ifeq ($(WLAN_PROPRIETARY),1)
    WLAN_BLD_DIR := vendor/qcom/proprietary/wlan-noship
else
    WLAN_BLD_DIR := vendor/qcom/opensource/wlan
endif

# DLKM_DIR was moved for JELLY_BEAN (PLATFORM_SDK 16)
ifeq ($(call is-platform-sdk-version-at-least,16),true)
       DLKM_DIR := $(TOP)/device/qcom/common/dlkm
else
       DLKM_DIR := build/dlkm
endif

# Copy WCNSS_cfg.dat file from firmware_bin/ folder to target out directory.
ifeq ($(WLAN_PROPRIETARY),0)

$(shell mkdir -p $(TARGET_OUT_ETC)/firmware/wlan/qcacld)
$(shell rm -f $(TARGET_OUT_ETC)/firmware/wlan/qcacld/WCNSS_cfg.dat)
$(shell cp $(LOCAL_PATH)/firmware_bin/WCNSS_cfg.dat $(TARGET_OUT_ETC)/firmware/wlan/qcacld)
else
include $(CLEAR_VARS)
LOCAL_MODULE       := WCNSS_cfg.dat
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan/qcacld
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := WCNSS_qcom_cfg.ini
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan/qcacld
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

endif

include $(CLEAR_VARS)
LOCAL_MODULE       := otp.bin
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := fakeboar.bin
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := athwlan.bin
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := utf.bin
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH  := $(TARGET_OUT_ETC)/firmware/wlan
LOCAL_SRC_FILES    := firmware_bin/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

ifeq ($(TARGET_KERNEL_VERSION),)
$(info "WLAN: TARGET_KERNEL_VERSION is not defined, assuming default")
TARGET_KERNEL_SOURCE := kernel
KERNEL_TO_BUILD_ROOT_OFFSET := ../
endif

ifeq ($(KERNEL_TO_BUILD_ROOT_OFFSET),)
$(info "WLAN: KERNEL_TO_BUILD_ROOT_OFFSET is not defined, assuming default")
KERNEL_TO_BUILD_ROOT_OFFSET := ../
endif

# Build wlan.ko as either qcacld_wlan.ko
###########################################################

# This is set once per LOCAL_PATH, not per (kernel) module
KBUILD_OPTIONS := WLAN_ROOT=$(KERNEL_TO_BUILD_ROOT_OFFSET)$(WLAN_BLD_DIR)/qcacld
# We are actually building wlan.ko here, as per the
# requirement we are specifying <chipset>_wlan.ko as LOCAL_MODULE.
# This means we need to rename the module to <chipset>_wlan.ko
# after wlan.ko is built.
KBUILD_OPTIONS += MODNAME=wlan
KBUILD_OPTIONS += BOARD_PLATFORM=$(TARGET_BOARD_PLATFORM)
KBUILD_OPTIONS += $(WLAN_SELECT)


VERSION=$(shell grep -w "VERSION =" $(TOP)/kernel/Makefile | sed 's/^VERSION = //' )
PATCHLEVEL=$(shell grep -w "PATCHLEVEL =" $(TOP)/kernel/Makefile | sed 's/^PATCHLEVEL = //' )

include $(CLEAR_VARS)
LOCAL_MODULE              := $(WLAN_CHIPSET)_wlan.ko
LOCAL_MODULE_KBUILD_NAME  := wlan.ko
LOCAL_MODULE_TAGS         := debug
LOCAL_MODULE_DEBUG_ENABLE := true
ifeq ($(PRODUCT_VENDOR_MOVE_ENABLED), true)
LOCAL_MODULE_PATH         := $(TARGET_OUT_VENDOR)/lib/modules/$(WLAN_CHIPSET)
else
LOCAL_MODULE_PATH         := $(TARGET_OUT)/lib/modules/$(WLAN_CHIPSET)
endif # PRODUCT_VENDOR_MOVE_ENABLED
include $(DLKM_DIR)/AndroidKernelModule.mk
###########################################################

#Create symbolic link
ifeq ($(PRODUCT_VENDOR_MOVE_ENABLED), true)
$(shell mkdir -p $(TARGET_OUT_VENDOR)/lib/modules; \
    ln -sf /$(TARGET_COPY_OUT_VENDOR)/lib/modules/$(WLAN_CHIPSET)/$(WLAN_CHIPSET)_wlan.ko \
           $(TARGET_OUT_VENDOR)/lib/modules/wlan.ko)
else
$(shell mkdir -p $(TARGET_OUT)/lib/modules; \
    ln -sf /system/lib/modules/$(WLAN_CHIPSET)/$(WLAN_CHIPSET)_wlan.ko \
           $(TARGET_OUT)/lib/modules/wlan.ko)
endif # PRODUCT_VENDOR_MOVE_ENABLED
endif # DLKM check

endif # supported target check
