set -ex

mkdir build
cd build

cmake \
-GNinja \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INSTALL_PREFIX=$PREFIX \
-DCMAKE_INSTALL_LIBDIR=lib \
-DBUILD_SHARED_LIBS=ON \
${CMAKE_ARGS} \
-DKokkos_ENABLE_OPENMP=ON \
-DKokkos_ENABLE_EXAMPLES=OFF \
-DKokkos_ENABLE_SERIAL=ON \
-DKokkos_ENABLE_LIBDL:BOOL=OFF \
${Kokkos_OPT_ARGS} \
${Kokkos_CUDA_ARGS} \
${Kokkos_TEST_ARGS} \
-S ${SRC_DIR}

cmake --build . -j $CPU_COUNT --verbose

# Tests will take approximately 8 minutes
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
ctest --output-on-failure
fi

cmake --install .

# Remove build-prefix paths

sed -i.bak -e s,"/home/conda/feedstock_root/build_artifacts/kokkos_[0-9]*/_build_env/bin/","",g $PREFIX/bin/kokkos_launch_compiler
rm $PREFIX/bin/*.bak

if [ ! -z ${cuda_compiler_version+x} ]; then
sed -i.bak '/INCLUDE(CMakeFindDependencyMacro)/a\
\
\IF(NOT TARGET CUDA::cudart)\
\  MESSAGE(SEND_ERROR "The CUDA::cudart target was not found; use find_package(CUDAToolkit REQUIRED) before find_package(Kokkos).")\
\ENDIF()\
\IF(NOT TARGET CUDA::cuda_driver)\
\  MESSAGE(SEND_ERROR "The CUDA::cuda_driver target was not found; use find_package(CUDAToolkit REQUIRED) before find_package(Kokkos).")\
\ENDIF()' $PREFIX/lib/cmake/Kokkos/KokkosConfig.cmake
fi

if [[ "$cuda_compiler_version" == "11."* ]]; then
sed -i.bak -e s,"/home/conda/feedstock_root/build_artifacts/kokkos_[0-9]*/_build_env/x86_64-conda-linux-gnu/sysroot/lib/libcuda.so","/usr/lib64/libcuda.so",g $PREFIX/lib/cmake/Kokkos/KokkosConfig.cmake
fi

if [[ "$cuda_compiler_version" == "12."* ]]; then
sed -i.bak -e s,"/home/conda/feedstock_root/build_artifacts/kokkos_[0-9]*/_build_env/x86_64-conda-linux-gnu/sysroot/lib/libcuda.so","\$ENV{PREFIX}/lib/stubs/libcuda.so",g $PREFIX/lib/cmake/Kokkos/KokkosConfig.cmake
fi

sed -i.bak -e s,"/home/conda/feedstock_root/build_artifacts/kokkos_[0-9]*/_build_env/bin/","",g $PREFIX/lib/cmake/Kokkos/KokkosConfigCommon.cmake
sed -i.bak -e s,'\"/home/conda/feedstock_root/build_artifacts/kokkos_[0-9]*/_h_env_[placehold_]*\"','"\$ENV{BUILD_PREFIX}"\ "\$ENV{PREFIX}"\ "\$ENV{CONDA_PREFIX}"',g $PREFIX/lib/cmake/Kokkos/KokkosConfigCommon.cmake
rm $PREFIX/lib/cmake/Kokkos/*.bak
