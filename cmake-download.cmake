cmake_minimum_required(VERSION 3.8)

include(ExternalProject)

function(find_or_download) 
 cmake_parse_arguments(
  fol
  ""
  "PACKAGE_NAME;VERSION;GIT_REPO;GIT_TAG;STATUS_VAR;DEPS_DIR;DOWNLOAD_OVERRIDE"
  ""
  ${ARGN}
 )

 #Ensure function was invoked correctly
 if(NOT DEFINED fol_PACKAGE_NAME OR NOT DEFINED fol_GIT_REPO)
  message(
   FATAL_ERROR 
   "'find_or_download' accepts the following named arguments:\ 
   \n(REQUIRED) 'PACKAGE_NAME' - The name of the package to find\
   \n(OPTIONAL) 'VERSION' - The version of the package to find\
   \n(REQUIRED) 'GIT_REPO' - The repository to download if the package is not found\
   \n(OPTIONAL) 'GIT_TAG' - A branch, tag or commit hash, defaults to 'master'\
   \n(OPTIONAL) 'STATUS_VAR' - The variable to store the download status in, set to 'TRUE' if downloaded\
   \n(OPTIONAL) 'DEPS_DIR' - Download destination, defaults to '\${CMAKE_SOURCE_DIR}/dependencies'\
   \n(OPTIONAL) 'DOWNLOAD_OVERRIDE' - Force downloading of sources\
  ")
 endif()

 #Set defualt download destination if not present
 if(NOT DEFINED fol_DEPS_DIR)
  set(fol_DEPS_DIR "${CMAKE_SOURCE_DIR}/dependencies")
 endif()

 #Set default tag if not present
 if(NOT DEFINED fol_GIT_TAG)
  set(fol_GIT_TAG "master")
 endif()

 #Set download override to false if not defined
 if(NOT DEFINED fol_DOWNLOAD_OVERRIDE)
  set(fol_DOWNLOAD_OVERRIDE FALSE)
 endif()

 #For convenience
 function(set_status_var download_status)
  if(DEFINED fol_STATUS_VAR)
   set(download_status ${download_status} PARENT_SCOPE)
  endif()
 endfunction()

 #Search for package
 if(NOT DEFINED fol_DOWNLOAD_OVERRIDE)
  if(${fol_VERSION})
   find_package("${fol_PACKAGE_NAME}" "${fol_VERSION}" QUIET)
  else()
   find_package("${fol_PACkAGE_NAME}" QUIET)
  endif()
 else()
  set("${fol_PACKAGE_NAME}_FOUND" TRUE)
 endif()

 #Download if package not found 
 if("${fol_PACKAGE_NAME}_FOUND" AND NOT ${fol_DOWNLOAD_OVERRIDE})
  message(STATUS "Found '${fol_PACKAGE_NAME}', not downloading")
  set_status_var(FALSE)
 else()
  message(STATUS "Could not find '${fol_PACKAGE_NAME}'")
  set_status_var(TRUE)
  if(NOT EXISTS "${fol_DEPS_DIR}/${fol_PACKAGE_NAME}" OR ${fol_DOWNLOAD_OVERRIDE})
   message(STATUS "Downloading sources for '${fol_PACKAGE_NAME}'")
   ExternalProject_Add("${fol_PACKAGE_NAME}"
    SOURCE_DIR "${fol_DEPS_DIR}/${fol_PACKAGE_NAME}"
    EXCLUDE_FROM_ALL TRUE
    STEP_TARGETS download
    GIT_REPOSITORY "${fol_GIT_REPO}"
    GIT_TAG "${fol_GIT_TAG}"
   )

   add_custom_target("download_${fol_PACKAGE_NAME}" ALL DEPENDS "${fol_PACKAGE_NAME}-download") 
  else()
   message(STATUS "Found existing sources, not downloading")
  endif()
 endif()

 #Propogate status out of the scope of this function
 if(DEFINED fol_STATUS_VAR)
  set("${fol_STATUS_VAR}" ${download_status} PARENT_SCOPE)
 endif()
endfunction()
