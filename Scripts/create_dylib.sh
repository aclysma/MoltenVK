#!/bin/bash

set -e

export MVK_BUILT_PROD_DIR="${BUILT_PRODUCTS_DIR}"
export MVK_DYLIB_NAME="lib${PRODUCT_NAME}.dylib"
export MVK_SYS_FWK_DIR="${SDK_DIR}/System/Library/Frameworks"
export MVK_USR_LIB_DIR="${SDK_DIR}/usr/lib"

mkdir -p "${MVK_BUILT_PROD_DIR}/dynamic"

if test x"${ENABLE_BITCODE}" = xYES; then
	MVK_EMBED_BITCODE="-fembed-bitcode"
fi

if test x"${ENABLE_THREAD_SANITIZER}" = xYES; then
	MVK_SAN="-fsanitize=thread"
elif test x"${ENABLE_ADDRESS_SANITIZER}" = xYES; then
	MVK_SAN="-fsanitize=address"
fi

# Suppress visibility warning spam when linking in Release or Debug mode
# and external libraries built in the other mode.
MVK_LINK_WARN="-Xlinker -w"

clang++ \
-stdlib=${CLANG_CXX_LIBRARY} \
-dynamiclib \
$(printf -- "-arch %s " ${ARCHS}) \
-m${MVK_OS_CLANG}-version-min=${MVK_MIN_OS_VERSION} \
-compatibility_version 1.0.0 -current_version 1.0.0  \
-install_name "@rpath/${MVK_DYLIB_NAME}"  \
-Wno-incompatible-sysroot \
${MVK_EMBED_BITCODE} \
${MVK_SAN} \
${MVK_LINK_WARN} \
-isysroot ${SDK_DIR} \
-iframework ${MVK_SYS_FWK_DIR}  \
-framework Metal ${MVK_IOSURFACE_FWK} -framework ${MVK_UX_FWK} -framework QuartzCore -framework CoreGraphics ${MVK_IOKIT_FWK} -framework Foundation \
--library-directory ${MVK_USR_LIB_DIR} \
-o "${MVK_BUILT_PROD_DIR}/dynamic/${MVK_DYLIB_NAME}" \
-force_load "${MVK_BUILT_PROD_DIR}/lib${PRODUCT_NAME}.a"

if test "$CONFIGURATION" = Debug; then
	mkdir -p "${MVK_BUILT_PROD_DIR}/dynamic"
	dsymutil "${MVK_BUILT_PROD_DIR}/dynamic/${MVK_DYLIB_NAME}" \
	-o "${MVK_BUILT_PROD_DIR}/dynamic/${MVK_DYLIB_NAME}.dSYM"
fi
