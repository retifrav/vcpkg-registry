vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:opencv/opencv.git
    REF fe38fc608f6acb8b68953438a62305d8318f4fcd
    PATCHES
        001-dependencies-and-installation.patch
)

# do not vendor 3rd-party dependencies
file(REMOVE_RECURSE
    "${SOURCE_PATH}/3rdparty"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" OPENCV_BUILD_DYNAMIC)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" OPENCV_CRT_STATIC)

set(OPENCV_PACKAGE_NAME "OpenCV")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        # these should probably set depending on enabled modules (which should be features instead)
        with-eigen WITH_EIGEN
        with-jpeg WITH_JPEG
        with-png WITH_PNG
        with-tiff WITH_TIFF
        with-webp WITH_WEBP
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        #
        -DBUILD_LIST="core" # should probably compose this list from features
        #
        -DBUILD_SHARED_LIBS=${OPENCV_BUILD_DYNAMIC}
        -DBUILD_WITH_STATIC_CRT=${OPENCV_CRT_STATIC}
        -DOPENCV_OTHER_INSTALL_PATH="share/${OPENCV_PACKAGE_NAME}"
        #
        -DBUILD_ANDROID_EXAMPLES=0
        -DBUILD_ANDROID_PROJECTS=0
        -DBUILD_CUDA_STUBS=0
        -DBUILD_DOCS=0
        -DBUILD_EXAMPLES=0
        -DBUILD_ITT=0
        -DBUILD_JASPER=0
        -DBUILD_JAVA=0
        -DBUILD_JPEG=0
        -DBUILD_KOTLIN_EXTENSIONS=0
        -DBUILD_OBJC=0
        -DBUILD_opencv_apps=0
        -DBUILD_OPENEXR=0
        -DBUILD_OPENJPEG=0
        -DBUILD_PACKAGE=0
        -DBUILD_PERF_TESTS=0
        -DBUILD_PNG=0
        -DBUILD_TBB=0
        -DBUILD_TESTS=0
        -DBUILD_TIFF=0
        -DBUILD_WEBP=0
        -DBUILD_ZLIB=0
        -DCV_TRACE=0
        -DENABLE_PIC=0
        -DINSTALL_BIN_EXAMPLES=0
        -DINSTALL_TO_MANGLED_PATHS=0
        -DOPENCV_GENERATE_PKGCONFIG=0
        -DOPENCV_GENERATE_SETUPVARS=0
        -DWITH_1394=0
        -DWITH_ADE=0
        -DWITH_ARAVIS=0
        -DWITH_ARITH_DEC=0
        -DWITH_ARITH_ENC=0
        -DWITH_AVFOUNDATION=0
        -DWITH_AVIF=0
        -DWITH_CANN=0
        -DWITH_CAROTENE=0
        -DWITH_CLP=0
        -DWITH_CUDA=0
        -DWITH_FFMPEG=0
        -DWITH_FLATBUFFERS=0
        -DWITH_FRAMEBUFFER=0
        -DWITH_FRAMEBUFFER_XVFB=0
        -DWITH_GDAL=0
        -DWITH_GDCM=0
        -DWITH_GPHOTO2=0
        -DWITH_GSTREAMER=0
        -DWITH_GTK=0
        -DWITH_GTK_2_X=0
        -DWITH_HALIDE=0
        -DWITH_HPX=0
        -DWITH_IMGCODEC_GIF=0
        -DWITH_IMGCODEC_HDR=0
        -DWITH_IMGCODEC_PFM=0
        -DWITH_IMGCODEC_PXM=0
        -DWITH_IMGCODEC_SUNRASTER=0
        -DWITH_IPP=0
        -DWITH_ITT=0
        -DWITH_JASPER=0
        -DWITH_JPEGXL=0
        -DWITH_KLEIDICV=0
        -DWITH_LAPACK=0
        -DWITH_LIBREALSENSE=0
        -DWITH_MFX=0
        -DWITH_OBSENSOR=0
        -DWITH_ONNX=0
        -DWITH_OPENCL=0
        -DWITH_OPENCL_SVM=0
        -DWITH_OPENCLAMDBLAS=0
        -DWITH_OPENCLAMDFFT=0
        -DWITH_OPENEXR=0
        -DWITH_OPENGL=0
        -DWITH_OPENJPEG=0
        -DWITH_OPENMP=0
        -DWITH_OPENNI2=0
        -DWITH_OPENNI=0
        -DWITH_OPENVINO=0
        -DWITH_OPENVX=0
        -DWITH_PROTOBUF=0
        -DWITH_PTHREADS_PF=0
        -DWITH_PVAPI=0
        -DWITH_PYTHON=0
        -DWITH_QT=0
        -DWITH_QUIRC=0
        -DWITH_SPNG=0
        -DWITH_TBB=0
        -DWITH_TIMVX=0
        -DWITH_UEYE=0
        -DWITH_V4L=0
        -DWITH_VA=0
        -DWITH_VA_INTEL=0
        -DWITH_VTK=0
        -DWITH_VULKAN=0
        -DWITH_WAYLAND=0
        -DWITH_WEBNN=0
        -DWITH_XIMEA=0
        -DWITH_XINE=0
        -DWITH_ZLIB_NG=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "${OPENCV_PACKAGE_NAME}"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
file(REMOVE
    "${CURRENT_PACKAGES_DIR}/debug/LICENSE"
    "${CURRENT_PACKAGES_DIR}/LICENSE"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
