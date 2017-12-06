#! /bin/sh
set -e

# don't start ts3server with root permissions
if [ "$1" = 'ts3server' -a "$(id -u)" = '0' ]; then
    chown -R ts3server /var/ts3server
    exec su-exec ts3server "$0" "$@"
fi

# have the default inifile as the last parameter
if [ "$1" = 'ts3server' ]; then
    set -- "$@" inifile=/opt/ts3server/ts3server.ini
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
	file_env 'TEAMSPEAK_DB_HOST'
	file_env 'TEAMSPEAK_DB_USER'
	file_env 'TEAMSPEAK_DB_PASSWORD'
	file_env 'TEAMSPEAK_DB_NAME'
	
	if [ ! -f '/opt/ts3server/ts3server.ini' ]; then
		cat <<- EOF >/opt/ts3server/ts3server.ini
			licensepath=${TEAMSPEAK_LICENSEPATH}
			query_ip_whitelist=${TEAMSPEAK_IP_WHITELIST:-query_ip_whitelist.txt}
			query_ip_blacklist=${TEAMSPEAK_IP_BLACKLIST:-query_ip_blacklist.txt}
			dbplugin=${TEAMSPEAK_DB_PLUGIN:-ts3db_sqlite3}
			dbpluginparameter=${TEAMSPEAK_DB_PLUGINPARAMETER:-/opt/ts3server/ts3db.ini}
			dbsqlpath=${TEAMSPEAK_DB_SQLPATH:-/opt/ts3server/sql/}
			dbsqlcreatepath=${TEAMSPEAK_DB_SQLCREATEPATH:-create_sqlite}
			dbconnections=${TEAMSPEAK_DB_CONNECTIONS:-10}
			dbclientkeepdays=${TEAMSPEAK_DB_CLIENTKEEPDAYS:-30}
			logpath=${TEAMSPEAK_LOG_PATH:-/var/ts3server/logs}
			logquerycommands=${TEAMSPEAK_LOG_QUERY_COMMANDS:-0}
			logappend=${TEAMSPEAK_LOG_APPEND:-0}
		EOF
	fi
	if [ ! -f '/opt/ts3server/ts3db.ini' ]; then
		cat <<- EOF >/opt/ts3server/ts3db.ini
			[config]
			host='${TEAMSPEAK_DB_HOST}'
			port='${TEAMSPEAK_DB_PORT:-3306}'
			username='${TEAMSPEAK_DB_USER}'
			password='${TEAMSPEAK_DB_PASSWORD}'
			database='${TEAMSPEAK_DB_NAME}'
			socket=
			wait_until_ready='${TEAMSPEAK_DB_WAITUNTILREADY:-30}'
		EOF
	fi
fi

exec "$@"
