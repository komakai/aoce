include(AoceHelper)

start_android_find_host()

set(NCNN_PREFIX_PATH ${AOCE_THIRDPARTY_PATH}/ncnn)

create_search_paths(NCNN)
if(ANDROID)
    # 支持两种目录结构:
    # aoce_thirdparty: android/include/ncnn, android/{abi}/libncnn.so
    # ncnn官方android发布包: android/{abi}/include/ncnn, android/{abi}/lib/libncnn.so
    foreach(dir ${NCNN_PREFIX_PATH})
        set(NCNN_INC_SEARCH_PATH ${NCNN_INC_SEARCH_PATH}
            ${dir}/android/include/ncnn ${dir}/android/${ANDROID_ABI}/include/ncnn)
        set(NCNN_LIB_SEARCH_PATH ${NCNN_LIB_SEARCH_PATH}
            ${dir}/android/${ANDROID_ABI} ${dir}/android/${ANDROID_ABI}/lib)
    endforeach()
endif()

# thirdparty/ncnn被替换后,丢弃CMakeCache里已经不存在的路径
if(NCNN_INCLUDE_DIR AND NOT EXISTS "${NCNN_INCLUDE_DIR}/net.h")
    unset(NCNN_INCLUDE_DIR CACHE)
endif()
if(NCNN_LIBRARYS AND NOT EXISTS "${NCNN_LIBRARYS}")
    unset(NCNN_LIBRARYS CACHE)
endif()

find_path(NCNN_INCLUDE_DIR NAME net.h HINTS ${NCNN_INC_SEARCH_PATH} PATH_SUFFIXES)
message(STATUS "ncnn include:" ${NCNN_INCLUDE_DIR})

if(WIN32)    
    if (AOCE_DEBUG_TYPE)         
        find_library(NCNN_LIBRARYS NAME ncnnd HINTS ${NCNN_LIB_SEARCH_PATH} PATH_SUFFIXES)
        find_file(NCNN_BINARYS NAME "ncnnd.dll" HINTS ${NCNN_BIN_SEARCH_PATH} PATH_SUFFIXES)
    endif()
    # release与debug没找到ncnnd,进入此条件
    if(NOT NCNN_BINARYS)
        find_library(NCNN_LIBRARYS NAME ncnn HINTS ${NCNN_LIB_SEARCH_PATH} PATH_SUFFIXES)
        find_file(NCNN_BINARYS NAME "ncnn.dll" HINTS ${NCNN_BIN_SEARCH_PATH} PATH_SUFFIXES)
    endif()    
elseif(ANDROID)
    find_library(NCNN_LIBRARYS NAME ncnn HINTS ${NCNN_LIB_SEARCH_PATH} PATH_SUFFIXES ${ANDROID_ABI})
endif()

if(NCNN_INCLUDE_DIR AND NCNN_LIBRARYS)
    set(NCNN_FOUND TRUE)
    set(NCNN_INCLUDE_DIRS ${NCNN_INCLUDE_DIR})
endif()

end_android_find_host()