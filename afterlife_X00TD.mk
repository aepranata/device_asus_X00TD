#
# Copyright (C) 2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from X00TD device
$(call inherit-product, $(LOCAL_PATH)/full_X00TD.mk)

# Inherit some common Afterlife stuff
$(call inherit-product, vendor/afterlife/config/common_full_phone.mk)

AFTERLIFE_MAINTAINER := aepranata
DEVICE_PACKAGE_OVERLAYS+= $(LOCAL_PATH)/overlay-afterlife

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := afterlife_X00TD
