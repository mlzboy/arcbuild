include(CMakeParseArguments)

option(ARCBUILD_VERBOSE ${ARCBUILD_VERBOSE} "Verbose output of arcbuild")

function(arcbuild_echo)
  if(ARCBUILD_VERBOSE)
    message(STATUS "ARCBUILD: [I] ${ARGN}")
  endif()
endfunction()

function(arcbuild_warn)
  message(STATUS "ARCBUILD: [W] " ${ARGN})
endfunction()

function(arcbuild_error)
  message(FATAL_ERROR "ARCBUILD: [E] " ${ARGN})
endfunction()

macro(arcbuild_append_c_flags)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGN}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGN}")
endmacro()

macro(arcbuild_append_cxx_flags)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGN}")
endmacro()

macro(arcbuild_append_link_flags)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ARGN}")
  set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    ${ARGN}")
endmacro()

macro(arcbuild_enable_cxx11)
  if(MSVC)
    if(MSVC_VERSION VERSION_LESS 1700)
      arcbuild_warn("No C++11 is supported before VS2012")
    endif()
  elseif(CMAKE_COMPILER_IS_GNUCXX AND CMAKE_C_COMPILER_VERSION VERSION_LESS "4.7")
    arcbuild_append_cxx_flags("-std=gnu++11")
  else()
    arcbuild_append_cxx_flags("-std=c++11")
  endif()
endmacro()

macro(arcbuild_enable_neon)
  if(SDK_ARCH MATCHES "armv7")
    arcbuild_append_c_flags("-mfloat-abi=softfp -mfpu=neon -ftree-vectorize -ffast-math")
  else()
    arcbuild_warn("Disable neon")
  endif()
endmacro()

macro(arcbuild_enable_sse)
  if(MSVC)
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
      if(NOT ARGN)
        arcbuild_append_c_flags("/arch:SSE")
      elseif(ARGN MATCHES "(2|3|4)")
        arcbuild_append_c_flags("/arch:SSE2")
      else()
        arcbuild_error("Unknown SSE version: ${ARGN}")
      endif()
    endif()
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "(X86|ARM64|X64)")
    if(NOT ARGN)
      arcbuild_append_c_flags("-msse")
    elseif(ARGN LESS 4)
      arcbuild_append_c_flags("-msse${ARGN}")
    elseif(ARGN EQUAL 4)
      arcbuild_append_c_flags("-msse4 -msse4.1 -msse4.2")
    else()
      arcbuild_error("Unknown SSE version: ${ARGN}")
    endif()
  else()
    arcbuild_warn("Disable sse${ARGN}")
  endif()
endmacro()

macro(arcbuild_enable_hidden)
  if(CMAKE_COMPILER_IS_GNUC)
    arcbuild_append_c_flags("-fvisibility=hidden -fdata-sections -ffunction-sections")
    arcbuild_append_cxx_flags("-fvisibility-inlines-hidden")
    arcbuild_append_link_flags("-Wl,--gc-sections -Wl,--as-needed -Wl,--strip-all")
  elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    arcbuild_append_c_flags("-fvisibility=hidden -fdata-sections -ffunction-sections")
    arcbuild_append_cxx_flags("-fvisibility-inlines-hidden")
    arcbuild_append_link_flags("-Wl,-dead_strip")
  endif()
endmacro()

macro(arcbuild_enable_features)
  # message(${ARGN})
  # message(${CMAKE_C_COMPILER_VERSION})
  # message(${CMAKE_CXX_COMPILER_VERSION})
  set(features ${ARGN})
  list(REMOVE_DUPLICATES features)
  foreach(feat ${features})
    arcbuild_echo("Try enable feature: ${feat}")
    if(feat STREQUAL "cxx11")
      arcbuild_enable_cxx11()
    elseif(feat STREQUAL "neon")
      arcbuild_enable_neon()
    elseif(feat STREQUAL "sse")
      arcbuild_enable_sse()
    elseif(feat STREQUAL "sse2")
      arcbuild_enable_sse(2)
    elseif(feat STREQUAL "sse3")
      arcbuild_enable_sse(3)
    elseif(feat STREQUAL "sse4")
      arcbuild_enable_sse(4)
    elseif(feat STREQUAL "hidden")
      arcbuild_enable_hidden()
    endif()
  endforeach()
  unset(features)
  unset(feat)
endmacro()

function(arcbuild_check_cmake_version)
  set(required_cmake_version "2.8.12")
  if(NOT ARCBUILD_CMAKE_VERSION_CHECKED AND CMAKE_VERSION VERSION_LESS ${required_cmake_version})
    arcbuild_error("Required CMake version >= ${required_cmake_version}")
    set(ARCBUILD_CMAKE_VERSION_CHECKED ON PARENT_SCOPE)
  endif()
endfunction()

set(ARCBUILD_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")
arcbuild_check_cmake_version()
