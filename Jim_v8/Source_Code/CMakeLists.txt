cmake_minimum_required(VERSION 3.10)
project(JIM)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable -O2 optimization
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Ob2 -Oi -Ot -GL")

# Path to shared headers
include_directories(${CMAKE_SOURCE_DIR}/Header_Libraries)

# Get all top-level subdirectories
file(GLOB CHILD_DIRECTORIES RELATIVE ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/*)

# Remove header directory
list(REMOVE_ITEM CHILD_DIRECTORIES "Header_Libraries")

foreach(dir ${CHILD_DIRECTORIES})

    # 1) Collect all .cpp files in the main directory
    file(GLOB MAIN_SOURCES ${CMAKE_SOURCE_DIR}/${dir}/*.cpp)

    # 1b) Collect all .hpp files in the main directory
    file(GLOB MAIN_HPP_SOURCES ${CMAKE_SOURCE_DIR}/${dir}/*.hpp)

    # 2) Collect the command-line main.cpp file if it exists
    file(GLOB CMDLINE_SOURCES ${CMAKE_SOURCE_DIR}/${dir}/Command_Line/main.cpp)

    # Combine them
    set(SOURCE_FILES ${MAIN_SOURCES} ${MAIN_HPP_SOURCES} ${CMDLINE_SOURCES})

    # Only create an executable if we actually found source files
    if(SOURCE_FILES)
        add_executable(${dir} ${SOURCE_FILES})
        target_include_directories(${dir} PRIVATE ${CMAKE_SOURCE_DIR}/Header_Libraries)
    endif()

endforeach()
