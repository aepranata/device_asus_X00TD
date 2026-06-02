#
# Copyright (C) 2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/asus/X00TD

# ============================================================
# PLATFORM
# Qualcomm SDM660 (Snapdragon 636), shipped as sdm636 bootloader
# ============================================================
TARGET_BOARD_PLATFORM := sdm660
TARGET_BOOTLOADER_BOARD_NAME := sdm636
TARGET_ENFORCES_QSSI := true
BOARD_USES_QCOM_HARDWARE := true
BOARD_SHIPPING_API_LEVEL := 33
BOARD_VNDK_VERSION := current

# ============================================================
# ARCHITECTURE
# Primary: ARM64 (Cortex-A73), Secondary: ARM32 (Cortex-A73)
# ============================================================
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a73

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a73

# ============================================================
# KERNEL
# Image format: Image.gz-dtb (gzip-compressed kernel + appended DTB)
# Page size: 4096 bytes, base address: 0x00000000
# ============================================================
BOARD_BOOT_HEADER_VERSION := 1
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_PAGESIZE := 4096

BOARD_KERNEL_CMDLINE := androidboot.android_dt_dir=/non-existent
BOARD_KERNEL_CMDLINE += androidboot.boot_devices=soc/c0c4000.sdhci
BOARD_KERNEL_CMDLINE += androidboot.configfs=true
BOARD_KERNEL_CMDLINE += androidboot.hardware=qcom
# BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive   # for debugging purposes only!
BOARD_KERNEL_CMDLINE += androidboot.usbcontroller=a800000.dwc3
BOARD_KERNEL_CMDLINE += ehci-hcd.park=3
BOARD_KERNEL_CMDLINE += lpm_levels.sleep_disabled=1
BOARD_KERNEL_CMDLINE += msm_rtb.filter=0x37
BOARD_KERNEL_CMDLINE += printk.devkmsg=on
BOARD_KERNEL_CMDLINE += sched_enable_hmp=1
BOARD_KERNEL_CMDLINE += sched_enable_power_aware=1
BOARD_KERNEL_CMDLINE += service_locator.enable=1
BOARD_KERNEL_CMDLINE += usbcore.autosuspend=7
BOARD_KERNEL_CMDLINE += user_debug=31

BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

TARGET_KERNEL_SOURCE := kernel/asus/X00TD
TARGET_KERNEL_CONFIG := vendor/asus/X00TD_defconfig
TARGET_KERNEL_NO_GCC := true

# Custom build identity — adjust to match your build host/user
TARGET_KERNEL_BUILD_HOST := beastmachine
TARGET_KERNEL_BUILD_USER := SonicBSV

# ============================================================
# BOOTLOADER & RECOVERY
# ============================================================
TARGET_NO_BOOTLOADER := true
TARGET_NO_RECOVERY := false

TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_UPDATER_LIBS := librecovery_updater_asus
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

AB_OTA_UPDATER := false

# ============================================================
# PARTITIONS — Static (boot, recovery, cache, userdata)
# Flash block size: 256 KiB (erase block 512 KiB)
# Metadata partition required for dynamic partition tracking
# ============================================================
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_USES_METADATA_PARTITION := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864 # 64 MiB
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864 # 64 MiB
BOARD_CACHEIMAGE_PARTITION_SIZE := 367001600 # 350 MiB
BOARD_USERDATAIMAGE_PARTITION_SIZE := 55490624512 # ~52 GiB

BOARD_SYSTEMIMAGE_JOURNAL_SIZE := 0
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4

# ============================================================
# PARTITIONS — Dynamic (retrofit super partition)
# SSI partitions: product, system, system_ext (inode count: unlimited)
# Treble partitions: odm, vendor (inode count: 4096)
# Super block devices: system (4 GiB) + vendor (800 MiB) physical partitions
# Dynamic group X00TD_dynpart spans all logical partitions, with 4 MiB
# reserved for LpMetadata at the end of the super partition.
# ============================================================
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

# Set ext4 filesystem type and copy-out paths for every logical partition
$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

# SSI partitions: no fixed inode limit (dynamic content, e.g. APEXes)
$(foreach p, $(call to-upper, $(SSI_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_EXTFS_INODE_COUNT := -1))
# Treble partitions: fixed inode count to cap vendor/odm image size
$(foreach p, $(call to-upper, $(TREBLE_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_EXTFS_INODE_COUNT := 4096))

# Reserved space for OTA incremental patches (SSI: 200 MiB, Treble: 40 MiB)
$(foreach p, $(call to-upper, $(SSI_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 209715200)) # 200 MiB
$(foreach p, $(call to-upper, $(TREBLE_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 41943040)) # 40 MiB

BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 838860800

# Super partition: retrofit mode using existing system + vendor block devices
BOARD_SUPER_PARTITION_BLOCK_DEVICES := vendor system
BOARD_SUPER_PARTITION_METADATA_DEVICE := system
BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE := 838860800 # 800 MiB
BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := 4294967296 # 4 GiB
BOARD_SUPER_PARTITION_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE) + $(BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE))

# Single dynamic partition group covering all logical partitions
BOARD_SUPER_PARTITION_GROUPS := X00TD_dynpart
BOARD_X00TD_DYNPART_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304)
BOARD_X00TD_DYNPART_PARTITION_LIST := $(ALL_PARTITIONS)

# Vendor partition copy-out path (also set by foreach above, kept explicit)
TARGET_COPY_OUT_VENDOR := vendor

# Symlink /persist into vendor mount namespace
BOARD_ROOT_EXTRA_SYMLINKS := \
 /mnt/vendor/persist:/persist

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# ============================================================
# DISPLAY
# HWC2 + Gralloc4, ION allocator, screen density 440 dpi
# ============================================================
TARGET_SCREEN_DENSITY := 440
TARGET_USES_GRALLOC1 := true
TARGET_USES_GRALLOC4 := true
TARGET_USES_HWC2 := true
TARGET_USES_ION := true
TARGET_USES_QTI_MAPPER_2_0 := true
TARGET_USES_QTI_MAPPER_EXTENSIONS_1_1 := true

HWUI_COMPILE_FOR_PERF := true

# ============================================================
# AUDIO
# QTI audio HAL with ALSA backend, TFA98XX amplifier enabled
# ============================================================

# Hardware / board audio capabilities
AUDIO_FEATURE_ENABLED_EXT_AMPLIFIER := false
AUDIO_FEATURE_ENABLED_TFA98XX_AMPLIFIER := true

BOARD_USES_ALSA_AUDIO := true
BOARD_SUPPORTS_SOUND_TRIGGER := true
BOARD_SUPPORTS_OPENSOURCE_STHAL := true

AUDIO_USE_DEEP_AS_PRIMARY_OUTPUT := false

# Common audio features (always enabled regardless of AOSP audio flag)
AUDIO_FEATURE_ENABLED_ACDB_LICENSE := true
AUDIO_FEATURE_ENABLED_ANC_HEADSET := true
AUDIO_FEATURE_ENABLED_CUSTOMSTEREO := true
AUDIO_FEATURE_ENABLED_DISPLAY_PORT := true
AUDIO_FEATURE_ENABLED_DS2_DOLBY_DAP := false
AUDIO_FEATURE_ENABLED_DYNAMIC_LOG := false
AUDIO_FEATURE_ENABLED_FLUENCE := true
AUDIO_FEATURE_ENABLED_GEF_SUPPORT := true
AUDIO_FEATURE_ENABLED_HDMI_EDID := true
AUDIO_FEATURE_ENABLED_HDMI_PASSTHROUGH := true
AUDIO_FEATURE_ENABLED_HFP := true
AUDIO_FEATURE_ENABLED_HIFI_AUDIO := true
AUDIO_FEATURE_ENABLED_INCALL_MUSIC := true
# AUDIO_FEATURE_ENABLED_KEEP_ALIVE := true
AUDIO_FEATURE_ENABLED_KPI_OPTIMIZE := true
AUDIO_FEATURE_ENABLED_MULTI_VOICE_SESSIONS := true
AUDIO_FEATURE_ENABLED_NT_PAUSE_TIMEOUT := true
AUDIO_FEATURE_ENABLED_RAS := true
AUDIO_FEATURE_ENABLED_SND_MONITOR := true
AUDIO_FEATURE_ENABLED_SOURCE_TRACKING := true
AUDIO_FEATURE_ENABLED_SPKR_PROTECTION := true
AUDIO_FEATURE_ENABLED_VBAT_MONITOR := true

# Extended audio features (only when not using AOSP audio policy)
ifneq ($(TARGET_USES_AOSP_FOR_AUDIO), true)
USE_CUSTOM_AUDIO_POLICY := 1
AUDIO_FEATURE_QSSI_COMPLIANCE := true
AUDIO_FEATURE_ENABLED_AHAL_EXT := false
AUDIO_FEATURE_ENABLED_A2DP_OFFLOAD := true
AUDIO_FEATURE_ENABLED_AAC_ADTS_OFFLOAD := true
AUDIO_FEATURE_ENABLED_ALAC_OFFLOAD := true
AUDIO_FEATURE_ENABLED_APE_OFFLOAD := true
AUDIO_FEATURE_ENABLED_AUDIOSPHERE := true
AUDIO_FEATURE_ENABLED_COMPRESS_CAPTURE := false
AUDIO_FEATURE_ENABLED_COMPRESS_VOIP := false
AUDIO_FEATURE_ENABLED_DEV_ARBI := false
AUDIO_FEATURE_ENABLED_DTS_EAGLE := false
AUDIO_FEATURE_ENABLED_EXTENDED_COMPRESS_FORMAT := true
AUDIO_FEATURE_ENABLED_EXTN_FLAC_DECODER := true
AUDIO_FEATURE_ENABLED_EXTN_FORMATS := true
AUDIO_FEATURE_ENABLED_EXTN_RESAMPLER := true
AUDIO_FEATURE_ENABLED_FLAC_OFFLOAD := true
AUDIO_FEATURE_ENABLED_FM_POWER_OPT := true
AUDIO_FEATURE_ENABLED_HDMI_SPK := true
AUDIO_FEATURE_ENABLED_HW_ACCELERATED_EFFECTS := false
AUDIO_FEATURE_ENABLED_PCM_OFFLOAD := true
AUDIO_FEATURE_ENABLED_PCM_OFFLOAD_24 := true
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
AUDIO_FEATURE_ENABLED_SSR := true
AUDIO_FEATURE_ENABLED_USB_TUNNEL := true
AUDIO_FEATURE_ENABLED_VORBIS_OFFLOAD := true
AUDIO_FEATURE_ENABLED_VOICE_PRINT := false
AUDIO_FEATURE_ENABLED_3D_AUDIO := false
AUDIO_FEATURE_ENABLED_WMA_OFFLOAD := true
BOARD_USES_SRS_TRUEMEDIA := false
DOLBY_ENABLE := false
DTS_CODEC_M_ := false
USE_LEGACY_AUDIO_DAEMON := false
USE_LEGACY_AUDIO_MEASUREMENT := false
endif

USE_XML_AUDIO_POLICY_CONF := 1

# ============================================================
# CAMERA
# Force 32-bit camera HAL (QTI legacy requirement for SDM660)
# ============================================================
BOARD_QTI_CAMERA_32BIT_ONLY := true

# ============================================================
# FM RADIO
# QCA Cherokee FM SoC integrated in SDM660
# ============================================================
BOARD_HAS_QCA_FM_SOC := cherokee
BOARD_HAVE_QCOM_FM := true

# ============================================================
# GPS / GNSS
# GNSS HIDL 2.1, LOC HIDL 4.0 (QTI location stack)
# ============================================================
BOARD_VENDOR_QCOM_GPS_LOC_API_HARDWARE := default
GNSS_HIDL_VERSION := 2.1
LOC_HIDL_VERSION := 4.0

# ============================================================
# WIFI
# QCA CLD3 driver, dual-interface HIDL, nl80211 supplicant
# ============================================================
BOARD_HAS_QCOM_WLAN := true
BOARD_WLAN_DEVICE := qcwcn
WIFI_DRIVER_DEFAULT := qca_cld3

WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_DRIVER_STATE_OFF := "OFF"

BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WPA_SUPPLICANT_VERSION := VER_0_8_X

BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)

WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

CONFIG_ACS := true
CONFIG_IEEE80211AC := true

# ============================================================
# HIDL / VINTF MANIFESTS
# Device manifest, compatibility matrix, and ODM NFC overlay
# ============================================================
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/vintf/manifest.xml
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest_android.hardware.drm@1.3-service.widevine.xml \
    $(DEVICE_PATH)/vintf/vendor.qti.gnss@4.0-service.xml

DEVICE_MATRIX_FILE := $(DEVICE_PATH)/vintf/compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := $(DEVICE_PATH)/vintf/framework_compatibility_matrix.xml

# ODM manifest overlay for NFC SKU variant
ODM_MANIFEST_SKUS += NFC
ODM_MANIFEST_NFC_FILES := $(DEVICE_PATH)/vintf/manifest_nfc.xml

# ============================================================
# SEPOLICY
# Extends QTI legacy-um SEPolicy with device-specific rules
# ============================================================
include device/qcom/sepolicy-legacy-um/SEPolicy.mk

BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private

# ============================================================
# PROPERTIES
# Split into product / system / vendor prop files
# ============================================================
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/properties/product.prop
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/properties/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/properties/vendor.prop

# ============================================================
# MEMORY
# Svelte malloc reduces memory footprint; also applied to 32-bit libc
# ============================================================
MALLOC_SVELTE := true
MALLOC_SVELTE_FOR_LIBC32 := true

# ============================================================
# DRM / MEDIA
# Enable 64-bit MediaDRM for Widevine L1
# ============================================================
TARGET_ENABLE_MEDIADRM_64 := true

# ============================================================
# HEALTH / CHARGING CONTROL
# Path used by lineage_health HAL to enable/disable charging
# ============================================================
$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/power_supply/battery/charging_enabled)

# ============================================================
# MISC
# ============================================================

# Filesystem config generator (uid/gid/capability assignments)
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs

# Low-memory killer daemon stats logging
TARGET_LMKD_STATS_LOG := true

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# USB audio accessory support
TARGET_QTI_USB_SUPPORTS_AUDIO_ACCESSORY := true

# Vendor init library (Soong namespace injection)
$(call soong_config_set,libinit,vendor_init_lib,//$(DEVICE_PATH):libinit_sdm660)

# Soong namespace for this device tree
PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)

# Security patch date reported by the vendor partition
VENDOR_SECURITY_PATCH := 2025-01-05

# OTA / build identity
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_OTA_ASSERT_DEVICE := ASUS_X00TD,X00TD,X00T

# ============================================================
# VENDOR BOARD CONFIG
# ============================================================
include vendor/asus/X00TD/BoardConfigVendor.mk
