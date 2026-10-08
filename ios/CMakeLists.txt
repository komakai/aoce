# iOS demo app,对应android目录下的aoceswigtest/aocencnntest
# 由根目录CMakeLists.txt在IOS下加入,生成方式见ios/README.md

set(AOCE_IOS_BUNDLE_PREFIX "aoce.samples" CACHE STRING "bundle identifier prefix of the iOS demo apps")
set(AOCE_IOS_TEAM_ID "" CACHE STRING "Apple development team id used for code signing")

set(AOCE_IOS_COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/common)
file(GLOB AOCE_IOS_COMMON_SOURCE "${AOCE_IOS_COMMON_DIR}/*.mm" "${AOCE_IOS_COMMON_DIR}/*.h")
# vulkan compute shader(SPIR-V),MoltenVK运行时转换成Metal
# glsl/ios/target里为iOS修改过的shader替换glsl/target里同名的shader
file(GLOB AOCE_IOS_GLSL_OVERRIDE "${CMAKE_SOURCE_DIR}/glsl/ios/target/*.spv")
file(GLOB AOCE_GLSL_TARGET "${CMAKE_SOURCE_DIR}/glsl/target/*.spv")
set(AOCE_IOS_GLSL ${AOCE_IOS_GLSL_OVERRIDE})
foreach(spv ${AOCE_GLSL_TARGET})
    get_filename_component(spvName ${spv} NAME)
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/glsl/ios/target/${spvName}")
        list(APPEND AOCE_IOS_GLSL ${spv})
    endif()
endforeach()
set_source_files_properties(${AOCE_IOS_GLSL} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/glsl)

find_library(UIKIT_LIB UIKit)
find_library(METALKIT_LIB MetalKit)
find_library(METAL_LIB Metal)
find_library(AVFOUNDATION_LIB AVFoundation)

function(aoce_ios_app target display_name)
    file(GLOB APP_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/${target}/*.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/${target}/*.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/${target}/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/${target}/*.h")
    add_executable(${target} MACOSX_BUNDLE ${APP_SOURCE} ${AOCE_IOS_COMMON_SOURCE}
        ${AOCE_IOS_GLSL} ${ARGN})
    set_target_properties(${target} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${AOCE_IOS_COMMON_DIR}/Info.plist.in
        MACOSX_BUNDLE_BUNDLE_NAME ${display_name}
        MACOSX_BUNDLE_GUI_IDENTIFIER ${AOCE_IOS_BUNDLE_PREFIX}.${target}
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${AOCE_IOS_BUNDLE_PREFIX}.${target}
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${AOCE_IOS_TEAM_ID}"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
        XCODE_ATTRIBUTE_GCC_ENABLE_CPP_RTTI YES
        XCODE_ATTRIBUTE_ENABLE_BITCODE NO
        XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_APPS_DIR)"
        XCODE_ATTRIBUTE_SKIP_INSTALL NO
    )
    target_compile_options(${target} PRIVATE -fobjc-arc)
    target_include_directories(${target} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/${target}
        ${AOCE_IOS_COMMON_DIR}
        ${CMAKE_SOURCE_DIR}/code
        ${AOCE_HEADER_DIR})
    target_link_libraries(${target} aoce aoce_vulkan aoce_vulkan_extra aoce_ios
        ${UIKIT_LIB} ${METALKIT_LIB} ${METAL_LIB} ${AVFOUNDATION_LIB})
endfunction()

# GPUImage滤镜演示(android/aoceswigtest)
file(GLOB SWIGTEST_ASSETS "${CMAKE_SOURCE_DIR}/android/aoceswigtest/assets/*.png")
set_source_files_properties(${SWIGTEST_ASSETS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
aoce_ios_app(aoceswigtest "aoceswigtest" ${SWIGTEST_ASSETS})

# ncnn人脸检测/关键点演示(android/aocencnntest)
if(AOCE_INSTALL_NCNN AND TARGET aoce_ncnn)
    set(NCNNTEST_NETS
        ${CMAKE_SOURCE_DIR}/assets/net/slim_320.param
        ${CMAKE_SOURCE_DIR}/assets/net/slim_320.bin
        ${CMAKE_SOURCE_DIR}/assets/net/face.param
        ${CMAKE_SOURCE_DIR}/assets/net/face.bin
        ${CMAKE_SOURCE_DIR}/assets/net/pfld-sim.param
        ${CMAKE_SOURCE_DIR}/assets/net/pfld-sim.bin)
    set_source_files_properties(${NCNNTEST_NETS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/net)
    aoce_ios_app(aocencnntest "aocencnntest" ${NCNNTEST_NETS})
    target_compile_definitions(aocencnntest PRIVATE AOCE_IOS_NCNN=1)
    target_link_libraries(aocencnntest aoce_ncnn)
endif()
