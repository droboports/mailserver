## ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### ICU ###
_build_icu() {
local VERSION="55.1"
local FOLDER="icu"
local FILE="icu4c-${VERSION/./_}-src.tgz"
local URL="http://download.icu-project.org/files/icu4c/${VERSION}/${FILE}"
local ICU="${PWD}/target/${FOLDER}"
local ICU_NATIVE="${PWD}/target/${FOLDER}-native"
local ICU_HOST="${PWD}/target/${FOLDER}-host"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
rm -fr "${ICU_NATIVE}"
mkdir -p "${ICU_NATIVE}"
( . uncrosscompile.sh
  pushd "${ICU_NATIVE}"
  "${ICU}/source/configure"
  make )
rm -fr "${ICU_HOST}"
mkdir -p "${ICU_HOST}"
pushd "${ICU_HOST}"
"${ICU}/source/configure" --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --disable-extras --disable-samples --disable-tests --with-cross-build="${ICU_NATIVE}" --enable-rpath
make -j1
make install
popd
}

### PCRE ###
_build_pcre() {
local VERSION="8.37"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/pcre/files/pcre/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-unicode-properties
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfaR "${DEPS}/lib"/* "${DEST}/lib/"
rm -vfr "${DEPS}/lib"
rm -vf "${DEST}/lib/libcrypto.a" "${DEST}/lib/libssl.a"
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}/lib/pkgconfig/openssl.pc"
popd
}

### SQLITE ###
_build_sqlite() {
local VERSION="3081101"
local FOLDER="sqlite-autoconf-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sqlite.org/2015/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
cp -vfa "${DEPS}/bin/sqlite3" "${DEST}/libexec/"
popd
}

### BDB ###
_build_bdb() {
local VERSION="5.3.28"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://download.oracle.com/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-compat185 --enable-dbm
make
make install
popd
}

### MYSQL-CONNECTOR ###
_build_mysqlc() {
local VERSION="6.1.6"
local FOLDER="mysql-connector-c-${VERSION}-src"
local FILE="${FOLDER}.tar.gz"
local URL="http://cdn.mysql.com/Downloads/Connector-C/${FILE}"
export FOLDER_NATIVE="${PWD}/target/${FOLDER}-native"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
[   -d "${FOLDER_NATIVE}" ] && rm -fr "${FOLDER_NATIVE}"
[ ! -d "${FOLDER_NATIVE}" ] && cp -faR "target/${FOLDER}" "${FOLDER_NATIVE}"

# native compilation of comp_err
( source uncrosscompile.sh
  pushd "${FOLDER_NATIVE}"
  cmake .
  make comp_err )

pushd "target/${FOLDER}"
cat > "cmake_toolchain_file.${ARCH}" << EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR ${ARCH})
SET(CMAKE_C_COMPILER ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_AR ${AR})
SET(CMAKE_RANLIB ${RANLIB})
SET(CMAKE_STRIP ${STRIP})
SET(CMAKE_CROSSCOMPILING TRUE)
SET(STACK_DIRECTION 1)
SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN}/${HOST}/libc)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

# Use existing zlib
# ln -vfs libz.so "${DEST}/lib/libzlib.so"
# mv -v zlib/CMakeLists.txt{,.orig}
# touch zlib/CMakeLists.txt

# Fix regex to find openssl 1.0.2 version
sed -i -e "s/\^#define/^#[\t ]*define/g" -e "s/\+0x/*0x/g" cmake/ssl.cmake

LDFLAGS="${LDFLAGS} -lz" cmake . -DCMAKE_TOOLCHAIN_FILE="./cmake_toolchain_file.${ARCH}" \
  -DCMAKE_AR="${AR}" \
  -DCMAKE_STRIP="${STRIP}" \
  -DCMAKE_INSTALL_PREFIX="${DEPS}" \
  -DWITH_SSL="${DEPS}" \
  -DOPENSSL_ROOT_DIR="${DEST}" \
  -DOPENSSL_INCLUDE_DIR="${DEPS}/include" \
  -DOPENSSL_LIBRARY="${DEST}/lib/libssl.so" \
  -DCRYPTO_LIBRARY="${DEST}/lib/libcrypto.so" \
  -DENABLED_PROFILING=OFF \
  -DENABLE_DEBUG_SYNC=OFF \
  -DWITH_PIC=ON \
  -DHAVE_LLVM_LIBCPP_EXITCODE=1 \
  -DHAVE_GCC_ATOMIC_BUILTINS=1

if ! make -j1; then
  sed -i -e "s|\&\& comp_err|\&\& ./comp_err|g" extra/CMakeFiles/GenError.dir/build.make
  cp -vf "${FOLDER_NATIVE}/extra/comp_err" extra/
  make -j1
fi
make install
cp -vfaR "${DEPS}/lib"/libmysql*.so* "${DEST}/lib/"
cp -vfaR include/*.h "${DEPS}/include/"
rm -vf "${DEPS}/lib/libmysqlclient.a" "${DEPS}/lib/libmysqlclient_r.a"
popd
}

### POSTFIX ###
_build_postfix() {
local VERSION="2.10.1"
local FOLDER="postfix-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.swissrave.ch/mirror/postfix-source/official/${FILE}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"

# avoid broken ICU detection # postfix 3.0.2
#sed -e "s/CCARGS=\"\$CCARGS -DNO_EAI\"/CCARGS=\"\$CCARGS\"/g" -i makedefs
# prevent broken BDB detection # postfix 2.10.1
sed -e "352i\                 *-DHAS_DB*) ;;" -i makedefs
# prevent warnings about HAS_DB
sed -e "755d" -i src/util/sys_defs.h # postfix 2.10.1
#sed -e "771d" -i src/util/sys_defs.h # postfix 3.0.2

CCARGS="${CFLAGS} ${CPPFLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE=1 \
  -DDEF_CONFIG_DIR=\\\"${DEST}/etc/postfix\\\" -I${DEPS}/include -I${DEST}/include \
  -DUSE_TLS -DHAS_MYSQL -DHAS_DB -DHAS_SQLITE -DHAS_PCRE -DUSE_SASL_AUTH -DNO_KQUEUE -DNO_NIS"
AUXLIBS="${LDFLAGS} -licuuc -lmysqlclient -lsqlite3 -ldb -lssl -lcrypto -lpcre -lz \
  -lstdc++ -lpthread -lrt -lm -ldl"
make makefiles shared=yes CCARGS="${CCARGS}" AUXLIBS="${AUXLIBS}" OPT="-Os" \
  DEBUG="" SHLIB_DIR="${DEST}/lib/postfix"
make SHLIB_DIR="${DEST}/lib/postfix"
make non-interactive-package \
  install_root="/." \
  tempdir="${PWD}" \
  config_directory="${DEST}/etc/postfix" \
  command_directory="${DEST}/sbin" \
  daemon_directory="${DEST}/libexec/postfix" \
  data_directory="${DEST}/var/run/postfix" \
  html_directory="no" \
  mailq_path="${DEST}/bin/mailq" \
  manpage_directory="${DEST}/man" \
  meta_directory="${DEST}/etc/postfix" \
  newaliases_path="${DEST}/bin/newaliases" \
  queue_directory="${DEST}/var/spool/postfix" \
  readme_directory="no" \
  sendmail_path="${DEST}/sbin/sendmail" \
  shlib_directory="${DEST}/lib/postfix" \
  mail_owner="postfix" \
  setgid_group="postdrop" \
  SHLIB_DIR="${DEST}/lib/postfix"
#rm -vf "${DEST}/libexec/postfix/main.cf"
#rm -vf "${DEST}/libexec/postfix/master.cf"
ln -vfsT "../../etc/postfix/main.cf" "${DEST}/libexec/postfix/main.cf"
ln -vfsT "../../etc/postfix/master.cf" "${DEST}/libexec/postfix/master.cf"
mv -vf "${DEST}/etc/postfix/main.cf" "${DEST}/etc/postfix/main.cf.orig"
mv -vf "${DEST}/etc/postfix/main.cf.default" "${DEST}/etc/postfix/main.cf.default_values"
mv -vf "${DEST}/etc/postfix/master.cf" "${DEST}/etc/postfix/master.cf.orig"
popd
}

### DOVECOT ###
_build_dovecot() {
local VERSION="2.2.5"
local FOLDER="dovecot-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.dovecot.org/releases/2.2/${FILE}"
export KERNEL="${KERNEL_SOURCE:-${HOME}/build/kernel-drobo5n/kernel}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"

PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" \
  --includedir="${DEPS}/include" --mandir="${DEST}/man" \
  --enable-shared --disable-static --with-shared-libs \
  --with-zlib --with-icu \
  --with-ssl=openssl --with-ssldir="${DEST}/etc/ssl" \
  --with-sql --with-sqlite --with-mysql \
  --with-shadow --with-notify=inotify \
  CPPFLAGS="${CPPFLAGS:-} -I${KERNEL}/include" \
  i_cv_epoll_works=yes i_cv_inotify_works=yes i_cv_posix_fallocate_works=yes i_cv_signed_size_t=no i_cv_gmtime_max_time_t=32 i_cv_signed_time_t=yes i_cv_mmap_plays_with_write=yes i_cv_fd_passing=yes i_cv_c99_vsnprintf=yes lib_cv_va_copy=yes lib_cv___va_copy=yes lib_cv_va_val_copy=yes
make
make install
popd
}

### PYCRYPTO ###
_build_pycrypto() {
local VERSION="2.6.1"
local FILE="pycrypto-${VERSION}-py2.7-linux-armv7l.egg"
local URL="https://github.com/droboports/python-pycrypto/releases/download/v${VERSION}/${FILE}"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_file "${FILE}" "${URL}"
mkdir -p "${DEST}/lib/python2.7/site-packages"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
  "${XPYTHON}/bin/easy_install" --prefix="${DEST}" \
  --always-unzip --always-copy "download/${FILE}"
}

### LXML ###
_build_lxml() {
local VERSION="3.4.4"
local FILE="lxml-${VERSION}-py2.7-linux-armv7l.egg"
local URL="https://github.com/droboports/python-lxml/releases/download/v${VERSION}/${FILE}"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_file "${FILE}" "${URL}"
mkdir -p "${DEST}/lib/python2.7/site-packages"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
  "${XPYTHON}/bin/easy_install" --prefix="${DEST}" \
  --always-unzip --always-copy "download/${FILE}"
}

### MYSQL-PYTHON ###
_build_mysql_python() {
local VERSION="1.2.4b4"
local FILE="MySQL_python-${VERSION}-py2.7-linux-armv7l.egg"
local URL="https://github.com/droboports/python-MySQLdb/releases/download/v${VERSION}/${FILE}"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_file "${FILE}" "${URL}"
mkdir -p "${DEST}/lib/python2.7/site-packages"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
  "${XPYTHON}/bin/easy_install" --prefix="${DEST}" \
  --always-unzip --always-copy "download/${FILE}"
}

### python2 module ###
# Build a python2 module from source
__build_module() {
local VERSION="${2}"
local FOLDER="${1}-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://pypi.python.org/packages/source/$(echo ${1} | cut -c 1)/${1}/${FILE}"
local HPYTHON="${DROBOAPPS}/python2"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
sed -e "s/from distutils.core import setup/from setuptools import setup/g" \
    -i setup.py
PKG_CONFIG_PATH="${XPYTHON}/lib/pkgconfig" \
  LDFLAGS="${LDFLAGS} -Wl,-rpath,${HPYTHON}/lib -L${XPYTHON}/lib" \
  "${XPYTHON}/bin/python" setup.py \
    build_ext --include-dirs="${XPYTHON}/include" --library-dirs="${XPYTHON}/lib" --force \
    build --force \
    build_scripts --executable="${HPYTHON}/bin/python" --force \
    bdist_egg --dist-dir "${PWD}"

mkdir -p "${DEST}/lib/python2.7/site-packages"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
  "${XPYTHON}/bin/easy_install" --prefix="${DEST}" ${3:-} --always-copy *.egg
popd
}

### MODOBOA ###
_build_modoboa() {
local VERSION="1.0.1"
local FOLDER="modoboa-${VERSION}"
local FILE="${VERSION}.tar.gz"
local URL="https://github.com/tonioo/modoboa/archive/${FILE}"
local HPYTHON="${DROBOAPPS}/python2"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
sed -e "s/from distutils.core import setup/from setuptools import setup/g" \
    -i setup.py
PKG_CONFIG_PATH="${XPYTHON}/lib/pkgconfig" \
  LDFLAGS="${LDFLAGS} -Wl,-rpath,${HPYTHON}/lib -L${XPYTHON}/lib" \
  "${XPYTHON}/bin/python" setup.py \
    build_ext --include-dirs="${XPYTHON}/include" --library-dirs="${XPYTHON}/lib" --force \
    build --force \
    build_scripts --executable="${HPYTHON}/bin/python" --force \
    bdist_egg --dist-dir "${PWD}"

mkdir -p "${DEST}/lib/python2.7/site-packages"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
  "${XPYTHON}/bin/easy_install" --prefix="${DEST}" ${3:-} --always-copy *.egg
popd
}

### WEBUI ###
_build_webui() {
local HPYTHON="${DROBOAPPS}/python2/bin/python"

  _build_pycrypto # 2.6.1
  _build_lxml # 3.4.4
  _build_mysql_python # 1.2.4b4
  __build_module argparse 1.2.1 # 1.3.0
  __build_module chardet 2.1.1 # 2.3.0
  # modoboa 1.0.1 requires Django < 1.6
  __build_module Django 1.5.12 # 1.7.10
  # django-reversion >= 1.9 requires Django 1.7
  __build_module django-reversion 1.7.1 # 1.8.7
      __build_module LEPL 5.1.3
    __build_module rfc6266 0.0.3 # 0.0.4
  __build_module factory_boy 2.2.1 # 2.5.2
  __build_module sievelib 0.7 # 0.8
  __build_module South 0.8.2 # 1.0.2
_build_modoboa

# fix python shebang paths
pushd "${DEST}/bin"
local files="chardetect django-admin.py modoboa-admin.py"
for f in $files; do
  sed -e "s|#!/.*|#!${HPYTHON}|g" -i "$f"
done
popd
}

### MODOBOA 1.3.4 ###
# _build_webui() {
#     _build_pycrypto
#     _build_lxml
#     _build_mysql_python
#     __build_module argparse 1.3.0
#     __build_module dj-database-url 0.3.0
#     __build_module django-reversion 1.8.5
#     __build_module django-versionfield2 0.3.3
#     __build_module django-xforwardedfor-middleware 1.0
#     __build_module Django 1.7.10
#     __build_module passlib 1.6.2
#     __build_module requests 2.7.0
#   __build_module modoboa 1.3.4
#     __build_module progressbar 2.3
#   __build_module modoboa-admin 1.1.1
#         __build_module LEPL 5.1.3
#       __build_module rfc6266 0.0.4
#     __build_module factory_boy 2.5.2
#     __build_module chardet 2.3.0
#   __build_module modoboa-webmail 1.0.1 --always-unzip
# 
# # fix python shebang paths
# pushd "${DEST}/bin"
# local files="chardetect django-admin django-admin.py modoboa-admin.py"
# for f in $files; do
#   sed -e "s|#!/.*|#!${HPYTHON}|g" -i "$f"
# done
# popd
# }

### CONFIG ###
_build_config() {
local DATADIR="/mnt/DroboFS/System/mail"
local INSTANCE="www"
local XPYTHON="${HOME}/xtools/python2/${DROBO}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
export PYTHONPATH="${DEST}/lib/python2.7/site-packages"
export PATH="${XPYTHON}/bin:${PATH}"
export HOME="${DEST}/${INSTANCE}"

pushd "${DEST}"
mkdir -p var/empty var/run/dovecot var/run/postfix var/run/modoboa var/spool/dovecot var/spool/postfix

### modoboa 1.0.1 ###
# 'expect' does not work due to env variables
echo "${DATADIR}/modoboa.sqlite" | python ./bin/modoboa-admin.py postfix_maps ${DEST}/etc/postfix --dbtype sqlite
### modoboa 1.3.4 ###
#   ${XPYTHON}/bin/python ./bin/modoboa-admin.py \
#     postfix_maps ${DEST}/etc/postfix \
#     --dbtype sqlite
#     --dburl "sqlite://localhost//mnt/DroboFS/System/mail/modoboa.sqlite" \
#     --extensions "modoboa_admin" "modoboa_webmail"

rm -vfR "${DEST}/${INSTANCE}"

### modoboa 1.0.1 ###
# 'expect' does not work due to env variables
( sleep 10; echo "sqlite3"; sleep 2; echo "*" ) | python ./bin/modoboa-admin.py deploy "${INSTANCE}" --syncdb --collectstatic
python "./${INSTANCE}/manage.py" syncdb --migrate
./libexec/sqlite3 "./${INSTANCE}/default.db" << EOF
INSERT INTO "admin_extension" VALUES(1,'amavis',0);
INSERT INTO "admin_extension" VALUES(2,'limits',0);
INSERT INTO "admin_extension" VALUES(3,'postfix_autoreply',0);
INSERT INTO "admin_extension" VALUES(4,'sievefilters',0);
INSERT INTO "admin_extension" VALUES(5,'stats',0);
INSERT INTO "admin_extension" VALUES(6,'webmail',1);
EOF
### modoboa 1.3.4 ###
# mkdir -p "${DATADIR}" # modoboa 1.3.4
# PYTHONPATH="${DEST}/lib/python2.7/site-packages" \
#   PATH="${XPYTHON}/bin:${PATH}" \
#   HOME="${DEST}/${INSTANCE}" \
#   "${XPYTHON}/bin/python" ./bin/modoboa-admin.py deploy "${INSTANCE}" \
#     --dburl "default:sqlite://localhost/${DATADIR}/modoboa.sqlite" \
#     --domain "*" \
#     --extensions "modoboa_admin" "modoboa_webmail"

rm -vfr "${DEST}/${INSTANCE}/.python-eggs"
rm -vf www/www/settings.pyc
sed -e "s/DEBUG = False/DEBUG = True/g" \
    -e "s|default.db|/mnt/DroboFS/System/mail/modoboa.sqlite|g" \
    -i www/www/settings.py
mv -vf www/www/settings.py www/www/settings.py.default

### modoboa 1.0.1 ###
mv -vf "${DEST}/${INSTANCE}/default.db" "${DEST}/etc/modoboa.sqlite.initial"
### modoboa 1.3.4 ###
# mv -vf "${DATADIR}/modoboa.sqlite" "${DEST}/etc/modoboa.sqlite.initial"

rm -vfr "${DATADIR}"
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
ln -vfs certs/ca-certificates.crt "${DEST}/etc/ssl/cert.pem"
}

### BUILD ###
_build() {
  _build_zlib
  _build_icu
  _build_pcre
  _build_openssl
  _build_sqlite
  _build_bdb
  _build_mysqlc
  _build_postfix
  _build_dovecot
  _build_webui
  _build_config
  _build_certificates
  _package
}
