setlocal EnableDelayedExpansion

mkdir build
cd build
if errorlevel 1 exit 1

:: Use threads on Windows instead of OpenMP because Kokkos requires
:: OpenMP>=3.0, but MSVC only implements OpenMP=2.0 as of 09/2022
:: https://github.com/kokkos/kokkos/issues/5482

cmake ^
-GNinja ^
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
-DKokkos_ENABLE_HWLOC:BOOL=ON ^
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

:: Replace the build-time compiler path with the bare name, so that the compiler
:: from the downstream environment's activation is used
sd "set\(Kokkos_CXX_COMPILER \x22[A-Za-z]:/[^\x22]*/cl\.exe\x22\)" "find_program(Kokkos_CXX_COMPILER NAMES cl.exe)" "%LIBRARY_PREFIX%\lib\cmake\Kokkos\KokkosConfigCommon.cmake"
if errorlevel 1 exit 1
sd "[A-Za-z]:/[^\x22]*/cl\.exe" "cl.exe" "%LIBRARY_PREFIX%\bin\kokkos_launch_compiler"
if errorlevel 1 exit 1
:: sd succeeds even without a match, so fail if a path is left (findstr errorlevel
:: 1 means none; ver clears it so the script does not end with a failure code)
findstr /R /C:"[A-Za-z]:/.*cl\.exe" "%LIBRARY_PREFIX%\lib\cmake\Kokkos\KokkosConfigCommon.cmake" "%LIBRARY_PREFIX%\bin\kokkos_launch_compiler" && exit 1
ver >nul
