set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -pedantic -fPIC" )


find_package(VTK REQUIRED)
include(${VTK_USE_FILE})

find_package(VES REQUIRED)
include_directories(${VES_INCLUDE_DIRS})

find_package(ZLIB REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

set(sources
  KiwiNative.cpp
)

set(deps
  GLESv2
  log
  ${VES_LIBRARIES}
  ${ZLIB_LIBRARIES}
)

set(kiwi_lib KiwiNative)

add_library(${kiwi_lib} SHARED ${sources})
target_link_libraries(${kiwi_lib} ${deps})
