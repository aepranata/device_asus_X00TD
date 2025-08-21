/*
 * SPDX-FileCopyrightText: 2025 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

#include <map>

#include "TouchscreenGesture.h"

namespace aidl {
namespace vendor {
namespace lineage {
namespace touch {

const std::map<int32_t, TouchscreenGesture::GestureInfo> kGestureInfoMap = {
    {0, {748, "Gesture C"}},
    {1, {749, "Gesture e"}},
    {2, {750, "Gesture M"}},
    {3, {751, "Gesture O"}},
    {4, {752, "Gesture S"}},
    {5, {753, "Gesture V"}},
    {6, {754, "Gesture W"}},
    {7, {755, "Gesture Z"}},
    {8, {756, "Gesture Swipe Up"}},
    {9, {757, "Gesture Swipe Down"}},
    {10, {758, "Gesture Swipe Left"}},
    {11, {759, "Gesture Swipe Right"}},
};

}  // namespace touch
}  // namespace lineage
}  // namespace vendor
}  // namespace aidl
