cmake_minimum_required(VERSION 3.19)

include(FetchContent)

function(add_latent_dependency)
 #Parse and check arguments
 cmake_parse_arguments(
  adl
  ""
  "NAME;SCOPE_ID"
  "TARGET_NAMES"
  ${ARGN}
 )
 if(NOT DEFINED adl_NAME OR NOT DEFINED adl_TARGET_NAMES)
  message(
   FATAL_ERROR
   "'add_latent_dependency' accepts the following named arguments:\
   \n(REQUIRED) 'NAME' - The designated name of the dependency to download\
   \n(REQUIRED) 'TARGET_NAMES' - The names of the targets defined by the dependency, for linking later\
   \n(OPTIONAL) 'SCOPE_ID' - A unique scope prefix to destinguish invocations to all 'X_latent_dependency' functions\
   \nThis function also accepts any arguments that FetchContent_Declare supports\
  ")
 endif()
 
 #Set up deps and targets variable names for global scope
 if(DEFINED adl_SCOPE_ID)
  set(deps_var "${SCOPE_ID}_latent_dependencies")
  set(targets_var "${SCOPE_ID}_latent_targets")
 else()
  set(deps_var "adl_latent_dependencies")
  set(targets_var "adl_latent_targets")
 endif()

 #Add name to latent dependency list
 list(APPEND "${deps_var}" "${adl_NAME}")
 set("${deps_var}" "${${deps_var}}" PARENT_SCOPE)

 #Add target to latent target list
 list(APPEND "${targets_var}" ${adl_TARGET_NAMES})
 set("${targets_var}" "${${targets_var}}" PARENT_SCOPE)

 #Remove 'NAME' and 'TARGET_NAMES' named arguments from 'ARGV' so the rest
 #of the arguments can be propagated to 'FetchContent_Declare'
 list(FIND ARGV NAME index)
 list(REMOVE_AT ARGV ${index})
 list(REMOVE_AT ARGV ${index})
 list(FIND ARGV TARGET_NAMES index)
 list(REMOVE_AT ARGV ${index})
 list(REMOVE_AT ARGV ${index})

 #Invoke 'FetchContent_Declare', forwarding all 'ARGV' arguments
 FetchContent_Declare(
  ${adl_NAME}
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/dependencies/${adl_NAME}"
  BINARY_DIR "${CMAKE_BINARY_DIR}/dependencies/${adl_NAME}"
  GIT_SHALLOW TRUE
  GIT_PROGRESS TRUE
  USES_TERMINAL_DOWNLOAD TRUE
  USES_TERMINAL_UPDATE TRUE
  ${ARGV}
 )
endfunction()

function(fetch_latent_dependencies)
 #Parse arguments
 cmake_parse_arguments(
  fld
  ""
  "SCOPE_ID;TARGETS_VAR"
  ""
  ${ARGN}
 )

 #Set up deps and targets name variables
 if(DEFINED fld_SCOPE_ID)
  message(STATUS "Fetching latent dependnecies for scope: ${fld_SCOPE_ID}")
  set(deps_var "${fld_SCOPE_ID}_latent_dependencies")
  set(targets_var "${fld_SCOPE_ID}_latent_targets")
 else()
  set(deps_var "adl_latent_dependencies")
  set(targets_var "adl_latent_targets")
 endif()

 #Check that both the deps and targets variables are defined
 if(NOT DEFINED "${deps_var}" OR NOT DEFINED "${targets_var}")
  message(
   FATAL_ERROR 
   "'fetch_latent_dependencies' invoked but either '${deps_var}' or '${targets_var}' is not defined!\
   \nIf you're using the 'SCOPE_ID' parameter when invoking 'add_latent_dependency', you must also specify it here.\
   \n\n'fetch_latent_dependencies' accepts the following named arguments:\
   \n(OPTIONAL) 'SCOPE_ID' - The same scope prefix used when invoking 'add_latent_dependency', if specified\
   \n(OPTIONAL) 'TARGETS_VAR' - The result variable for all targets\
  ")
 endif()

 #Set the 'TARGETS_VAR' if it was specified
 if(DEFINED fld_TARGETS_VAR)
  set("${fld_TARGETS_VAR}" "${${targets_var}}" PARENT_SCOPE)
 endif()

 #Populate dependency and add it to the build
 foreach(dep_to_pop ${${deps_var}})
  FetchContent_Populate(${dep_to_pop})
  add_subdirectory(${${dep_to_pop}_SOURCE_DIR} ${${dep_to_pop}_BINARY_DIR})
 endforeach()
endfunction()
