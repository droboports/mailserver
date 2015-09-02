#!/usr/bin/env sh
#
# Mailserver service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="mailserver"
version="1.0.1"
description="Mail hosting made simple"
depends="python2"
webui="WebUI"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${DROBOAPPS_DIR}/python2/bin/python"
data_dir="/mnt/DroboFS/System/mail"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  framework_version="2.0"
  . "${prog_dir}/libexec/service.subr"
fi

# $1 name
# $2 gid
_add_group() {
  if ! grep -q "^${1}" /etc/group; then
    addgroup -g "${2}" "${1}"
  fi
}

# $1 name
# $2 uid
# $3 group
# $4 home
_add_user() {
  if ! grep -q "^${1}" /etc/passwd; then
    adduser -S -H -h "${4}" -D -s /bin/false -G "${3}" -u "${2}" "${1}"
  fi
}

_create_users() {
  _add_group postfix 32
  _add_user postfix 32 postfix "${prog_dir}/var/empty"
  _add_group postdrop 33
  _add_user postdrop 33 nobody "${prog_dir}/var/empty"
  _add_group dovecot 35
  _add_user dovecot 35 dovecot "${prog_dir}/var/empty"
  _add_group dovenull 36
  _add_user dovenull 36 dovenull "${prog_dir}/var/empty"
  _add_group vmail 5000
  _add_user vmail 5000 vmail "${data_dir}"
}

_create_folders() {
  mkdir -m 770 -p "${data_dir}/vmail"
  chown -R vmail:vmail "${data_dir}/vmail"

  mkdir -m 770 -p "${data_dir}/attach"
  chown -R vmail:vmail "${data_dir}/attach"

  touch "${tmp_dir}/dovecot.log"
  chown dovecot:dovecot "${tmp_dir}/dovecot.log"
  chmod 666 "${tmp_dir}/dovecot.log"

  chown -R postfix:postfix "${prog_dir}/var/spool/postfix"
  "${prog_dir}/sbin/postfix" set-permissions
}

_fix_services() {
  if ! grep -q "smtps" /etc/services; then
    echo "smtps 465/tcp # Secure SMTP" >> /etc/services
    echo "smtps 465/udp # Secure SMTP" >> /etc/services
  fi
}

_python() {
  PATH="${prog_dir}/libexec:${PATH}" \
  HOME="${prog_dir}/www" \
  PYTHONPATH="${prog_dir}/lib/python2.7/site-packages" \
  "${daemon}" "$@"
}

_maintenance_tasks() {
  _python "${prog_dir}/www/manage.py" cleanlogs || true
  _python "${prog_dir}/www/manage.py" cleanup || true
#  _python "${prog_dir}/www/manage.py" qcleanup || true
  _python "${prog_dir}/www/manage.py" clearsessions || true
  _python "${prog_dir}/www/manage.py" handle_mailbox_operations || true

  if [ ! -f "${prog_dir}/etc/postfix/aliases.db" ]; then
    "${prog_dir}/sbin/postalias" "${prog_dir}/etc/postfix/aliases"
  fi

  if [ ! -f "${prog_dir}/etc/postfix/generic.db" ]; then
    "${prog_dir}/sbin/postmap" "${prog_dir}/etc/postfix/generic"
  fi

  if [ ! -f "${prog_dir}/etc/postfix/transport.db" ]; then
    "${prog_dir}/sbin/postmap" "${prog_dir}/etc/postfix/transport"
  fi
}

_is_modoboa_running() {
  ps w | grep -q "[r]unserver"
}

_start_modoboa() {
  PATH="${prog_dir}/libexec:${PATH}" HOME="${prog_dir}/www" PYTHONPATH="${prog_dir}/lib/python2.7/site-packages" setsid "${daemon}" "${prog_dir}/www/manage.py" runserver 0.0.0.0:8000 &
  echo $! > "${pidfile}"
}

_stop_modoboa() {
  local pids
  pids="$(grep -l [r]unserver /proc/*/cmdline | awk -F/ '{print $3}')"
  if [ -n "$pids" ]; then
    kill ${pids} || true
  fi
}

_force_stop_modoboa() {
  local pids
  pids="$(grep -l [r]unserver /proc/*/cmdline | awk -F/ '{print $3}')"
  if [ -n "$pids" ]; then
    kill -9 ${pids} || true
  fi
}

is_running() {
  killall -q -0 postfix
  killall -q -0 dovecot
}

is_stopped() {
  ! killall -q -0 postfix
  ! killall -q -0 dovecot
}

start() {
  _create_users
  _create_folders
  _fix_services
  _maintenance_tasks
  "${prog_dir}/sbin/postfix" start
  "${prog_dir}/sbin/dovecot"
  if ! _is_modoboa_running; then
    _start_modoboa
  fi
}

stop() {
  _stop_modoboa
  "${prog_dir}/sbin/dovecot" stop && "${prog_dir}/sbin/postfix" stop
}

force_stop() {
  _force_stop_modoboa
  killall -q -9 dovecot
  killall -q -9 postfix
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
