# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/vabarca/data/git/personal/xiao-remote-button/micro")
  file(MAKE_DIRECTORY "/home/vabarca/data/git/personal/xiao-remote-button/micro")
endif()
file(MAKE_DIRECTORY
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/micro"
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix"
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/tmp"
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/src/micro-stamp"
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/src"
  "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/src/micro-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/src/micro-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/vabarca/data/git/personal/xiao-remote-button/micro/build/_sysbuild/sysbuild/images/micro-prefix/src/micro-stamp${cfgdir}") # cfgdir has leading slash
endif()
