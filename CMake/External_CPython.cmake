# --------------------------- PYTHON INTERPRETER -------------------------------

if( WIN32 )
  set( CPYTHON_BUILD_ARGS -e )

  if( CMAKE_SIZEOF_VOID_P GREATER_EQUAL 8 )
    set( CPYTHON_BUILD_ARGS ${CPYTHON_BUILD_ARGS} -p x64 )
  endif()

  if( CMAKE_BUILD_TYPE STREQUAL "Debug" )
    set( CPYTHON_BUILD_ARGS ${CPYTHON_BUILD_ARGS} -c Debug )
  else()
    set( CPYTHON_BUILD_ARGS ${CPYTHON_BUILD_ARGS} -c Release )
  endif()

  ExternalProject_Add( CPython
    URL ${CPython_url}
    URL_MD5 ${CPython_md5}
    ${COMMON_EP_ARGS}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND 
    BUILD_COMMAND PCBuild\build.bat ${CPYTHON_BUILD_ARGS}
    INSTALL_COMMAND ""
  )
else()

  set( CPYTHON_BUILD_ARGS
    --prefix=${fletch_BUILD_INSTALL_PREFIX}
    --enable-shared
  )

  if( CMAKE_BUILD_TYPE STREQUAL "Debug" )
    set( CPYTHON_BUILD_ARGS ${CPYTHON_BUILD_ARGS} --with-pydebug )
  endif()

  Fletch_Require_Make()
  ExternalProject_Add( CPython
    URL ${CPython_url}
    URL_MD5 ${CPython_md5}
    ${COMMON_EP_ARGS}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ./configure ${CPYTHON_BUILD_ARGS}
    BUILD_COMMAND ${MAKE_EXECUTABLE}
    INSTALL_COMMAND ${MAKE_EXECUTABLE} install
  )
  ExternalProject_Add_Step( CPython add-extra-symlinks
    COMMAND ${CMAKE_COMMAND} -E env
      ln -sfn python3 ${fletch_BUILD_INSTALL_PREFIX}/bin/python &&
      ln -sfn pip3 ${fletch_BUILD_INSTALL_PREFIX}/bin/pip
    DEPENDEES install
  )

  set( BUILT_PYTHON_EXE ${fletch_BUILD_INSTALL_PREFIX}/bin/python )
  set( BUILT_PYTHON_INCLUDE ${fletch_BUILD_INSTALL_PREFIX}/include )
  set( BUILT_PYTHON_LIBRARY ${fletch_BUILD_INSTALL_PREFIX}/lib/libpython3.6m.so )
endif()

set( CPython_ROOT "${fletch_BUILD_INSTALL_PREFIX}" CACHE PATH "" FORCE )
file( APPEND ${fletch_CONFIG_INPUT} "
################################
# CPython
################################
set( CPython_ROOT \${fletch_ROOT} )
set( fletch_ENABLED_CPython TRUE)
")

set( PYTHON_EXECUTABLE ${BUILT_PYTHON_EXE} CACHE PATH "Internal Python" )
set( PYTHON_INCLUDE_DIR ${BUILT_PYTHON_INCLUDE} CACHE PATH "Internal Python" )
set( PYTHON_LIBRARY ${BUILT_PYTHON_LIBRARY} CACHE PATH "Internal Python" )
set( PYTHON_LIBRARY_DEBUG ${BUILT_PYTHON_LIBRARY} CACHE PATH "Internal Python" )

# --------------------- ADD ANY EXTRA PYTHON LIBS HERE -------------------------

set( fletch_PYTHON_LIBS numpy matplotlib )
set( fletch_PYTHON_LIB_CMDS "numpy" "matplotlib" )

# ------------------------- LOOP OVER THE ABOVE --------------------------------

set( PYTHON_BASEPATH
  ${fletch_BUILD_INSTALL_PREFIX}/lib/python${PYTHON_VERSION} )

if( WIN32 )
  set( CUSTOM_PYTHONPATH
    ${PYTHON_BASEPATH}/site-packages;${PYTHON_BASEPATH}/dist-packages )
  set( CUSTOM_PATH
    ${fletch_BUILD_INSTALL_PREFIX}/bin;$ENV{PATH} )

  string( REPLACE ";" "----" CUSTOM_PYTHONPATH "${CUSTOM_PYTHONPATH}" )
  string( REPLACE ";" "----" CUSTOM_PATH "${CUSTOM_PATH}" )
else()
  set( CUSTOM_PYTHONPATH
    ${PYTHON_BASEPATH}/site-packages:${PYTHON_BASEPATH}/dist-packages )
  set( CUSTOM_PATH
    ${fletch_BUILD_INSTALL_PREFIX}/bin:$ENV{PATH} )
endif()

set( fletch_PYTHON_LIBS_DEPS CPython )

list( LENGTH fletch_PYTHON_LIBS DEP_COUNT )
math( EXPR DEP_COUNT "${DEP_COUNT} - 1" )

foreach( ID RANGE ${DEP_COUNT} )

  list( GET fletch_PYTHON_LIBS ${ID} DEP )
  list( GET fletch_PYTHON_LIB_CMDS ${ID} CMD )

  set( fletch_PROJECT_LIST ${fletch_PROJECT_LIST} ${DEP} )

  set( PYTHON_DEP_PIP_CMD pip install --user ${CMD} )
  string( REPLACE " " ";" PYTHON_DEP_PIP_CMD "${PYTHON_DEP_PIP_CMD}" )

  set( PYTHON_DEP_INSTALL
    ${CMAKE_COMMAND} -E env "PYTHONPATH=${CUSTOM_PYTHONPATH}"
                            "PATH=${CUSTOM_PATH}"
                            "PYTHONUSERBASE=${fletch_BUILD_INSTALL_PREFIX}"
      ${PYTHON_EXECUTABLE} -m ${PYTHON_DEP_PIP_CMD}
    )

  ExternalProject_Add( ${DEP}
    DEPENDS ${fletch_PYTHON_LIBS_DEPS}
    PREFIX ${fletch_BUILD_PREFIX}
    SOURCE_DIR ${fletch_CMAKE_DIR}
    USES_TERMINAL_BUILD 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${PYTHON_DEP_INSTALL}
    INSTALL_COMMAND ""
    INSTALL_DIR ${fletch_BUILD_INSTALL_PREFIX}
    LIST_SEPARATOR "----"
    )
endforeach()
