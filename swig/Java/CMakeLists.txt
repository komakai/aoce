include(AoceHelper)

include_directories("../../code")
include_directories(${ANDROID_NDK}/sources/android/native_app_glue)

set(SWIG_LIBS aoce)
list(APPEND SWIG_LIBS android aoce_vulkan_extra)

if(AOCE_INSTALL_AGORA)
    list(APPEND SWIG_LIBS aoce_talkto)
endif()

if(AOCE_INSTALL_NCNN)
    list(APPEND SWIG_LIBS aoce_ncnn)
endif()

if(AOCE_SWIG_JAVA_WRAPPER)
    # android/aoce/build.gradle里的generateSwigJava任务已经调用swig生成了java与C++文件,
    # java文件直接作为aoce模块的生成源码,这里只编译C++包装文件.
    # 标记GENERATED,Android Studio同步时文件还不存在也能正常配置
    message(STATUS "android swig wrapper: ${AOCE_SWIG_JAVA_WRAPPER}")
    set_source_files_properties(${AOCE_SWIG_JAVA_WRAPPER} PROPERTIES GENERATED TRUE)
    add_library(aoce_swig_java SHARED ${AOCE_SWIG_JAVA_WRAPPER})
    target_link_libraries(aoce_swig_java ${SWIG_LIBS})
else()
    # 不通过gradle时(直接用CMake编译android),由CMake调用swig,
    # 生成的java文件在${CMAKE_CURRENT_BINARY_DIR}/swig下
    include(${SWIG_USE_FILE})
    start_android_find_host()

    set(WRAPPERLIST ../aocewrapper.i)
    SET_SOURCE_FILES_PROPERTIES(${WRAPPERLIST} PROPERTIES CPLUSPLUS ON)
    # 指定包名
    set(CMAKE_SWIG_FLAGS -c++ -package aoce.android.library.xswig -O ${SWIG_DEFINITIONS})
    SET(CMAKE_SWIG_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/swig)
    SWIG_ADD_LIBRARY(aoce_swig_java LANGUAGE java SOURCES ${WRAPPERLIST})
    swig_link_libraries(aoce_swig_java ${SWIG_LIBS})
    message(STATUS "android swig java dir: ${CMAKE_SWIG_OUTDIR}")

    end_android_find_host()
endif()
