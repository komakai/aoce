# Android

## 配置

用Android Studio直接打开android目录即可编译运行aoceswigtest/aocencnntest,不需要手动步骤.

唯一的前提是安装[swig](http://www.swig.org/download.html)(macOS可用`brew install swig`),并加入PATH.
如果不想加入PATH,可以在android/local.properties里指定:

```
swig.executable=C:/tools/swigwin-4.3.1/swig.exe
```

编译时会自动完成以下工作:

1. aoce模块的generateSwigJava任务调用swig,把swig/aocewrapper.i转换生成java文件(aoce/build/generated/swig/java,包名aoce.android.library.xswig)与C++包装文件.只有swig/*.i或code下的头文件改变时才会重新生成.
2. CMake编译生成的C++包装文件得到libaoce_swig_java.so.
3. 如果thirdparty/ncnn/android不存在,第一次同步时会自动下载ncnn官方发布包[ncnn-20260113-android-vulkan-shared](https://github.com/Tencent/ncnn/releases/tag/20260113),并把头文件里的NCNN_SIMPLEVK改为0(与aoce使用的vulkan头文件兼容).libncnn.so会自动打包进aoce.

### 选项

在android/local.properties或android/gradle.properties里设置(也可以用命令行-P):

| 选项 | 默认 | 说明 |
| --- | --- | --- |
| `aoce.ncnn` | `true` | 是否编译aoce_ncnn模块.会改变swig生成的java文件,aocencnntest需要开启.只看aoceswigtest里的滤镜可以关闭,减小apk大小. |
| `swig.executable` | PATH里的swig | swig可执行文件路径,也可以用环境变量`SWIG_EXECUTABLE`. |

ncnn必须是官方android-vulkan-shared发布包(`android/{abi}/include/ncnn`, `android/{abi}/lib/libncnn.so`).aoce_thirdparty里的老版本ncnn直接链接libvulkan.so,会与aoce_vulkan导出的vkXXX函数指针冲突导致启动崩溃,如果检测到会自动移到`android.old`并重新下载.

## demo

04_vulkantest一个简单的vulkan API测试程序,其窗口使用了native窗口.

aoce包含了swig转换的C++到java接口以及一些针对JNI操作和一些公共方法.

aoceswigtest就是GPUIMage里一百多种滤镜演示demo.

aocencnntest 是联合深度神经网络推理框架ncnn的一些demo测试.

## 注意

如果你要运行04_vulkantest/05_livetest/06_mediaplayer/07_androidtest/vulkanextratest这几个项目,需要在settings.gradle.kts里include对应项目,这些项目设置了AOCE_ENABLE_SAMPLES=ON,不需要swig.
