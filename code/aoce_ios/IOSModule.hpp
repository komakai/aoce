#pragma once

#include <module/IModule.hpp>

namespace aoce {
namespace ios {

class IOSModule : public IModule {
   private:
    /* data */
   public:
    IOSModule(/* args */);
    ~IOSModule();

   public:
    virtual bool loadModule() override;
    virtual void unloadModule() override;
};

}  // namespace ios
}  // namespace aoce
