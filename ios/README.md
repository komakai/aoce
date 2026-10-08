# iOS

iOS versions of the Android demos, using Vulkan through [MoltenVK](https://github.com/KhronosGroup/MoltenVK):

- `aoceswigtest`: the GPUImage filter catalogue (android/aoceswigtest) on the back camera.
- `aocencnntest`: ncnn face detection and face keypoints (android/aocencnntest) on the front camera.

Camera input is in [code/aoce_ios](../code/aoce_ios) (AVFoundation). Output is shown through `IOutputLayer::outMetalGpuTex`, the Metal counterpart of Android's `outGLGpuTex`. All modules are linked statically on iOS.

## Build

Requires Xcode, CMake and an arm64 device running iOS 15 or later.

```sh
ios/build_thirdparty.sh          # MoltenVK and ncnn for iOS -> thirdparty/
ios/build_ios.sh <TEAM_ID>       # generates ios/build/aoce.xcodeproj
```

Open `ios/build/aoce.xcodeproj` and run the `aoceswigtest` or `aocencnntest` scheme.

Shaders modified for iOS (mainly `readonly`/`writeonly` image qualifiers and smaller shared memory, which older Apple GPUs need) are in `glsl/ios`; the app bundle uses them in place of the same-named files in `glsl/target`. Rebuild them with `python3 glsl/ios/compileglsl_ios.py`.

If you change a parameter struct in `Aoce.h`/`AoceVkExtra.h`, rerun `python3 ios/tools/gen_param_fields.py`.

`aoceswigtest -AoceAutoTest YES` steps through every filter on a test image and saves screenshots to `Documents/autotest` (see `AutoTestRunner.h` for options).

## Known issues

- The back camera orientation hasn't been checked with a live camera yet.
- The emboss filter (压纹效果) renders black on all platforms (bug in `emboss.comp`).
- Simulator builds are not supported.
