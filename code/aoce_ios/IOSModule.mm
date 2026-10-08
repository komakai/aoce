#include "IOSModule.hpp"

#include <AoceManager.hpp>

#include "IOSVideoManager.hpp"

namespace aoce {
namespace ios {

IOSModule::IOSModule(/* args */) {}

IOSModule::~IOSModule() {}

bool IOSModule::loadModule() {
    AoceManager::Get().addVideoManager(CameraType::ios_avfoundation,
                                       new IOSVideoManager());
    return true;
}

void IOSModule::unloadModule() {
    AoceManager::Get().removeVideoManager(CameraType::ios_avfoundation);
}

ADD_MODULE(IOSModule, aoce_ios)

}  // namespace ios
}  // namespace aoce
