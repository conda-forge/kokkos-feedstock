setlocal EnableDelayedExpansion

mkdir build
cd build
if errorlevel 1 exit 1

:: Use threads on Windows instead of OpenMP because Kokkos requires
:: OpenMP>=3.0, but MSVC only implements OpenMP=2.0 as of 09/2022
:: https://github.com/kokkos/kokkos/issues/5482

:: Use CXX_STANDARD 20 to avoid syntax errors - @carterbox Jan 2025

cmake ^
-GNinja ^
-DCMAKE_CXX_STANDARD=20 ^
-DCMAKE_BUILD_TYPE=Release ^
-DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
-DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
-DBUILD_SHARED_LIBS=ON ^
%CMAKE_ARGS% ^
-DKokkos_ENABLE_OPENMP=OFF ^
-DKokkos_ENABLE_THREADS=ON ^
-DKokkos_ENABLE_EXAMPLES=OFF ^
-DKokkos_ENABLE_SERIAL=ON ^
-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON ^
%Kokkos_OPT_ARGS% ^
%Kokkos_CUDA_ARGS% ^
%Kokkos_TEST_ARGS% ^
-DKokkos_ENABLE_COMPILE_AS_CMAKE_LANGUAGE=ON ^
-S %SRC_DIR%
if errorlevel 1 exit 1

cmake --build . -j %CPU_COUNT%
if errorlevel 1 exit 1

:: Tests will take approximately 8 minutes
ctest --output-on-failure
if errorlevel 1 exit 1

cmake --install .
if errorlevel 1 exit 1
