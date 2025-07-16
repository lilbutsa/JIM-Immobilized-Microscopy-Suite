cmake_minimum_required(VERSION 3.10)
project(JIM)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable -O2 optimization
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# Set the path to the shared header files
include_directories(${CMAKE_SOURCE_DIR}/Header_Libraries)

# Get all subdirectories (except Header_Libraries)
file(GLOB CHILD_DIRECTORIES RELATIVE ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/*)
list(REMOVE_ITEM CHILD_DIRECTORIES "Header_Libraries")

# Add an executable for each subdirectory
foreach(dir ${CHILD_DIRECTORIES})
    file(GLOB SOURCE_FILES ${CMAKE_SOURCE_DIR}/${dir}/*.cpp)
    if(SOURCE_FILES)
        add_executable(${dir} ${SOURCE_FILES})
        target_include_directories(${dir} PRIVATE ${CMAKE_SOURCE_DIR}/Header_Libraries)
    endif()
endforeach()
