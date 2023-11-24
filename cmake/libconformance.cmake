# CMake definitions for libconformance (the p rotobuf compiler library).

add_custom_command(
  OUTPUT
    ${protobuf_SOURCE_DIR}/conformance/conformance.pb.h
    ${protobuf_SOURCE_DIR}/conformance/conformance.pb.cc
  DEPENDS ${protobuf_PROTOC_EXE} ${protobuf_SOURCE_DIR}/conformance/conformance.proto
  COMMAND ${protobuf_PROTOC_EXE} ${protobuf_SOURCE_DIR}/conformance/conformance.proto
      --proto_path=${protobuf_SOURCE_DIR}/conformance
      --cpp_out=${protoc_cpp_args}${protobuf_SOURCE_DIR}/conformance
)

add_custom_command(
  OUTPUT
    ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.pb.h
    ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.pb.cc
    ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.pb.h
    ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.pb.cc
    ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.pb.h
    ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.pb.cc
    ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.pb.h
    ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.pb.cc
  DEPENDS ${protobuf_PROTOC_EXE}
          ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.proto
          ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.proto
          ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.proto
          ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.proto
  COMMAND ${protobuf_PROTOC_EXE}
              ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.proto
              ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.proto
              ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.proto
              ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.proto
            --proto_path=${protobuf_SOURCE_DIR}/src
            --cpp_out=${protoc_cpp_args}${protobuf_SOURCE_DIR}/src
)

set(libconformance_srcs
  ${protobuf_SOURCE_DIR}/conformance/conformance.pb.h
  ${protobuf_SOURCE_DIR}/conformance/conformance.pb.cc
  ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.pb.h
  ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto2.pb.cc
  ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.pb.h
  ${protobuf_SOURCE_DIR}/src/google/protobuf/test_messages_proto3.pb.cc
  ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.pb.h
  ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto3_editions.pb.cc
  ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.pb.h
  ${protobuf_SOURCE_DIR}/src/google/protobuf/editions/golden/test_messages_proto2_editions.pb.cc
  ${protobuf_SOURCE_DIR}/conformance/binary_json_conformance_suite.cc
  ${protobuf_SOURCE_DIR}/conformance/binary_json_conformance_suite.h
  ${protobuf_SOURCE_DIR}/conformance/text_format_conformance_suite.cc
  ${protobuf_SOURCE_DIR}/conformance/text_format_conformance_suite.h
  ${protobuf_SOURCE_DIR}/src/google/protobuf/json/json.h
)

if (protobuf_JSONCPP_PROVIDER STREQUAL "module")
  if (NOT EXISTS "${protobuf_SOURCE_DIR}/third_party/jsoncpp/CMakeLists.txt")
    message(FATAL_ERROR
            "Cannot find third_party/jsoncpp directory that's needed to "
            "build conformance tests. If you use git, make sure you have cloned "
            "submodules:\n"
            "  git submodule update --init --recursive\n"
            "If instead you want to skip them, run cmake with:\n"
            "  cmake -Dprotobuf_BUILD_CONFORMANCE=OFF\n")
  endif()
elseif(protobuf_JSONCPP_PROVIDER STREQUAL "package")
  find_package(jsoncpp REQUIRED)
endif()

add_library(libconformance ${protobuf_SHARED_OR_STATIC}
  ${libconformance_srcs}
  ${protobuf_version_rc_file})
if(protobuf_HAVE_LD_VERSION_SCRIPT)
  if(${CMAKE_VERSION} VERSION_GREATER 3.13 OR ${CMAKE_VERSION} VERSION_EQUAL 3.13)
    target_link_options(libconformance PRIVATE -Wl,--version-script=${protobuf_SOURCE_DIR}/conformance/libconformance.map)
  elseif(protobuf_BUILD_SHARED_LIBS)
    target_link_libraries(libconformance PRIVATE -Wl,--version-script=${protobuf_SOURCE_DIR}/conformance/libconformance.map)
  endif()
  set_target_properties(libconformance PROPERTIES
    LINK_DEPENDS ${protobuf_SOURCE_DIR}/conformance/libconformance.map)
endif()
target_link_libraries(libconformance libprotobuf)
target_link_libraries(libconformance ${protobuf_ABSL_USED_TARGETS})

set(JSONCPP_WITH_TESTS OFF CACHE BOOL "Disable tests")
if(protobuf_JSONCPP_PROVIDER STREQUAL "module")
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/third_party/jsoncpp third_party/jsoncpp)
  target_include_directories(libconformance PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/third_party/jsoncpp/include)
  if(BUILD_SHARED_LIBS)
    target_link_libraries(libconformance jsoncpp_lib)
  else()
    target_link_libraries(libconformance jsoncpp_static)
  endif()
else()
  target_link_libraries(libconformance jsoncpp)
endif()


protobuf_configure_target(libconformance)
if(protobuf_BUILD_SHARED_LIBS)
  target_compile_definitions(libconformance
    PUBLIC  PROTOBUF_USE_DLLS
    PRIVATE libconformance_EXPORTS)
endif()
set_target_properties(libconformance PROPERTIES
    COMPILE_DEFINITIONS libconformance_EXPORTS
    VERSION ${protobuf_VERSION}
    OUTPUT_NAME ${LIB_PREFIX}conformance
    DEBUG_POSTFIX "${protobuf_DEBUG_POSTFIX}"
    # For -fvisibility=hidden and -fvisibility-inlines-hidden
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)
add_library(protobuf::libconformance ALIAS libconformance)

