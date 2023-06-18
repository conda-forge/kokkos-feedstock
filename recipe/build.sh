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
