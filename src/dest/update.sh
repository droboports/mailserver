#!/usr/bin/env sh
#
# update script

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
data_dir="/mnt/DroboFS/System/mail"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/update.log"

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

/bin/sh "${prog_dir}/service.sh" stop

## migrate data to new directory
mkdir -p "${data_dir}"

# migrate cert/key
if [   -f "${prog_dir}/etc/ssl/certs/mailserver.pem" ] && \
   [ ! -h "${prog_dir}/etc/ssl/certs/mailserver.pem" ] && \
   [   -f "${prog_dir}/etc/ssl/private/mailserver.pem" ] && \
   [ ! -h "${prog_dir}/etc/ssl/private/mailserver.pem" ]; then
  if [ ! -d "${data_dir}/certs" ]; then
    mkdir -p "${data_dir}/certs"
  fi
  mv "${prog_dir}/etc/ssl/certs/mailserver.pem" "${data_dir}/certs/cert.pem"
  ln -fs "${data_dir}/certs/cert.pem" "${prog_dir}/etc/ssl/certs/mailserver.pem"
  mv "${prog_dir}/etc/ssl/private/mailserver.pem" "${data_dir}/certs/key.pem"
  ln -fs "${data_dir}/certs/key.pem" "${prog_dir}/etc/ssl/private/mailserver.pem"
  chmod 640 "${data_dir}/certs/cert.pem" "${data_dir}/certs/key.pem"
fi

# migrate sqlite database
if [   -f "${prog_dir}/www/modoboa.sqlite" ] && \
   [ ! -h "${prog_dir}/www/modoboa.sqlite" ]; then
  mv "${prog_dir}/www/modoboa.sqlite" "${data_dir}/modoboa.sqlite"
  ln -fs "${data_dir}/modoboa.sqlite" "${prog_dir}/www/modoboa.sqlite"
  chmod 660 "${data_dir}/modoboa.sqlite"
fi
