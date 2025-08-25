/*
 * SPDX-FileCopyrightText: 2025 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "TouchscreenGestureService"

#include "TouchscreenGesture.h"
#include <android-base/logging.h>
#include <fstream>
#include <unordered_map>

namespace {

typedef struct {
	int32_t keycode;
	const char* name;
} GestureInfo;

const std::unordered_map<int32_t, GestureInfo> kGestureInfoMap = {
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

} // anonymous namespace

namespace aidl {
namespace vendor {
namespace lineage {
namespace touch {

static constexpr const char* kGestureNodePath =
    "/sys/kernel/touchpanel/gesture_node";

ndk::ScopedAStatus TouchscreenGesture::getSupportedGestures(std::vector<Gesture>* _aidl_return) {
    std::vector<Gesture> gestures;

    for (const auto& entry : kGestureInfoMap) {
	gestures.push_back({entry.first, entry.second.name, entry.second.keycode});
    }

    *_aidl_return = gestures;
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus TouchscreenGesture::setGestureEnabled(const Gesture& gesture, bool enabled) {
    const auto entry = kGestureInfoMap.find(gesture.id);
    if (entry == kGestureInfoMap.end()) {
        return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }

    std::ofstream file(kGestureNodePath);
    file << (enabled ? "1" : "0");
    LOG(DEBUG) << "Wrote file " << kGestureNodePath << " fail " << file.fail();

    return ndk::ScopedAStatus::ok();
}

}  // namespace touch
}  // namespace lineage
}  // namespace vendor
}  // namespace aidl
