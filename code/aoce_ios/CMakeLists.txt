# iOS平台模块: AVFoundation摄像头以及给app使用的辅助接口
include(AoceHelper)

file(GLOB AOCE_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/*.mm" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")
file(GLOB AOCE_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.h")

include_directories(${AOCE_HEADER_DIR})

find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
find_library(COREMEDIA_FRAMEWORK CoreMedia)
find_library(COREVIDEO_FRAMEWORK CoreVideo)
find_library(IMAGEIO_FRAMEWORK ImageIO)
find_library(COREGRAPHICS_LIB CoreGraphics)
find_library(FOUNDATION_LIB Foundation)

add_library(aoce_ios ${AOCE_LIB_TYPE} ${AOCE_SOURCE} ${AOCE_HEADER})
set_target_properties(aoce_ios PROPERTIES XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
target_compile_options(aoce_ios PRIVATE -fobjc-arc)
target_link_libraries(aoce_ios aoce ${AVFOUNDATION_FRAMEWORK} ${COREMEDIA_FRAMEWORK}
    ${COREVIDEO_FRAMEWORK} ${IMAGEIO_FRAMEWORK} ${COREGRAPHICS_LIB} ${FOUNDATION_LIB})

aoce_output(aoce_ios)
install_aoce_module(aoce_ios FLASE)
