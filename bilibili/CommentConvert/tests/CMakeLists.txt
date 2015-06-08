cmake_minimum_required(VERSION 2.6)
project(danmaku2ass_native)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")

set(SOURCE_FILES
    danmaku2ass.cpp
    danmaku2ass.h
    rapidxml/rapidxml_iterators.hpp
    rapidxml/rapidxml_print.hpp
    rapidxml/rapidxml_utils.hpp
    rapidxml/rapidxml.hpp
    AssClass.cpp
    AssClass.hpp
	)

add_executable(danmaku2ass_native ${SOURCE_FILES})
add_library(danmaku2ass SHARED ${SOURCE_FILES})