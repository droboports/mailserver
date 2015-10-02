#!/usr/bin/env sh

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
data_dir="/mnt/DroboFS/System/mail"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/install.log"
daemon="/mnt/DroboFS/Shares/DroboApps/python2/bin/python"

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

## migrate data to new directory
mkdir -p "${data_dir}"

# generate cert/key
mkdir -p "${data_dir}/certs"
if [ ! -f "${data_dir}/certs/cert.pem" ] || \
   [ ! -f "${data_dir}/certs/key.pem" ]; then
  "${prog_dir}/libexec/openssl" req -new -x509 \
    -keyout "${data_dir}/certs/key.pem" \
    -out "${data_dir}/certs/cert.pem" \
    -days 3650 -nodes -subj "/C=US/ST=CA/L=San Jose/CN=$(hostname)"
  chmod 640 "${data_dir}/certs/cert.pem" "${data_dir}/certs/key.pem"
fi

# create sqlite database
if [ ! -f "${data_dir}/modoboa.sqlite" ]; then
  cp "${prog_dir}/etc/modoboa.sqlite.initial" "${data_dir}/modoboa.sqlite"
  ln -fs "${data_dir}/modoboa.sqlite" "${prog_dir}/www/modoboa.sqlite"
  chmod 660 "${data_dir}/modoboa.sqlite"
fi

# copy default configuration files
find "${prog_dir}" -type f -name "*.default" -print | while read deffile; do
  basefile="$(dirname "${deffile}")/$(basename "${deffile}" .default)"
  if [ ! -f "${basefile}" ]; then
    cp -vf "${deffile}" "${basefile}"
  fi
done

# install apache 2.x
/usr/bin/DroboApps.sh install_version apache 2
