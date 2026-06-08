/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "fingerprint-X00TD"

#include "BiometricsFingerprint.h"

#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>
#include <hidl/HidlTransportSupport.h>

using ::aidl::android::hardware::biometrics::fingerprint::BiometricsFingerprint;

int main() {
    LOG(INFO) << "Fingerprint AIDL HAL service (X00TD) starting";

    // Инициализируем HIDL hwbinder thread pool ДО загрузки блоба
    // fingerprint.sdm660.so при open() вызывает
    // vendor.goodix registerAsService() через hwbinder
    android::hardware::configureRpcThreadpool(2, false);

    // AIDL binder
    ABinderProcess_setThreadPoolMaxThreadCount(1);
    ABinderProcess_startThreadPool();

    auto service = BiometricsFingerprint::create();
    if (!service) {
        LOG(ERROR) << "Failed to create BiometricsFingerprint";
        return EXIT_FAILURE;
    }

    const std::string instance =
        std::string(BiometricsFingerprint::descriptor) + "/default";

    binder_status_t status = AServiceManager_addService(
        service->asBinder().get(), instance.c_str());

    if (status != STATUS_OK) {
        LOG(ERROR) << "Failed to register AIDL service: " << status;
        return EXIT_FAILURE;
    }

    LOG(INFO) << "Service registered as: " << instance;

    ABinderProcess_joinThreadPool();

    return EXIT_FAILURE;
}
