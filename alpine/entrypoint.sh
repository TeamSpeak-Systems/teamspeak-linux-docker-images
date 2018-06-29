#! /bin/sh
set -e

# don't start ts3server with root permissions
if [ "$1" = 'ts3server' -a "$(id -u)" = '0' ]; then
    chown -R ts3server /var/ts3server
    exec su-exec ts3server "$0" "$@"
fi

# have the default inifile as the last parameter
if [ "$1" = 'ts3server' ]; then
    set -- "$@" inifile=/var/run/ts3server/ts3server.ini
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	eval local varValue="\$${var}"
	eval local fileVarValue="\$${var}_FILE"
	local def="${2:-}"
	if [ "${varValue:-}" ] && [ "${fileVarValue:-}" ]; then
			echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
			exit 1
	fi
	local val="$def"
	if [ "${varValue:-}" ]; then
			val="${varValue}"
	elif [ "${fileVarValue:-}" ]; then
			val="$(cat "${fileVarValue}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
	unset "$fileVarValue"
}

if [ "$1" = 'ts3server' ]; then
	file_env 'TS3SERVER_DB_HOST'
	file_env 'TS3SERVER_DB_USER'
	file_env 'TS3SERVER_DB_PASSWORD'
	file_env 'TS3SERVER_DB_NAME'
	
	cat <<- EOF >/var/run/ts3server/ts3server.ini
		licensepath=${TS3SERVER_LICENSEPATH}
		query_protocols=${TS3SERVER_QUERY_PROTOCOLS:-raw}
		query_timeout=${TS3SERVER_QUERY_TIMEOUT:-300}
		query_ssh_rsa_host_key=${TS3SERVER_QUERY_SSH_RSA_HOST_KEY:-ssh_host_rsa_key}
		query_ip_whitelist=${TS3SERVER_IP_WHITELIST:-query_ip_whitelist.txt}
		query_ip_blacklist=${TS3SERVER_IP_BLACKLIST:-query_ip_blacklist.txt}
		dbplugin=${TS3SERVER_DB_PLUGIN:-ts3db_sqlite3}
		dbpluginparameter=${TS3SERVER_DB_PLUGINPARAMETER:-/var/run/ts3server/ts3db.ini}
		dbsqlpath=${TS3SERVER_DB_SQLPATH:-/opt/ts3server/sql/}
		dbsqlcreatepath=${TS3SERVER_DB_SQLCREATEPATH:-create_sqlite}
		dbconnections=${TS3SERVER_DB_CONNECTIONS:-10}
		dbclientkeepdays=${TS3SERVER_DB_CLIENTKEEPDAYS:-30}
		logpath=${TS3SERVER_LOG_PATH:-/var/ts3server/logs}
		logquerycommands=${TS3SERVER_LOG_QUERY_COMMANDS:-0}
		logappend=${TS3SERVER_LOG_APPEND:-0}
		serverquerydocs_path=${TS3SERVER_serverquerydocs_path:-/opt/ts3server/serverquerydocs/}
	EOF
	cat <<- EOF >/var/run/ts3server/ts3db.ini
		[config]
		host='${TS3SERVER_DB_HOST}'
		port='${TS3SERVER_DB_PORT:-3306}'
		username='${TS3SERVER_DB_USER}'
		password='${TS3SERVER_DB_PASSWORD}'
		database='${TS3SERVER_DB_NAME}'
		socket=
		wait_until_ready='${TS3SERVER_DB_WAITUNTILREADY:-30}'
	EOF
fi

exec "$@"
