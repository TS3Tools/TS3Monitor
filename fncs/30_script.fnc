#!/usr/bin/env bash

# Get latest script version
# Return: LatestScriptVersion:string or 1:boolean
function getLatestScriptVersion() {
	LATEST_SCRIPT_VERSION="$(wget https://raw.githubusercontent.com/TS3Tools/TS3Monitor/master/docs/CHANGELOG.md --no-check-certificate -q -O - | grep Version | head -1 | cut -d ' ' -f 3 | tr -d '[[:space:]]')"

	if [[ -n "$LATEST_SCRIPT_VERSION" ]]; then
		echo -n "$LATEST_SCRIPT_VERSION";
	else
		return 1;
	fi
}

# Updates TS3UpdateScript to the latest version
# Return: 0:boolean or 1:boolean
function updateTS3Monitor() {
	if [ ! "$(bash ${ABSOLUTE_PATH}/.updateScript.sh &)" ]; then
		return 0;
	else
		return 1;
	fi
}

# Get administrator eMail
# Return: AdministratorEmail:string or 1:boolean
function getAdministratorEmail() {
	ADMINISTRATOR_EMAIL="$(grep ADMINISTRATOR_EMAILS ${ABSOLUTE_PATH}/configs/config.all | cut -d "=" -f 2)"

	if [[ -n "$ADMINISTRATOR_EMAIL" ]]; then
		echo -n "$ADMINISTRATOR_EMAIL";
	else
		return 1;
	fi
}

# Check if the settings of the script have been changed
# Return: 0:boolean or 1:boolean
function scriptSettingsChanged() {
	ADMIN_EMAIL_MD5SUM=$(grep ADMINISTRATOR_EMAILS "${ABSOLUTE_PATH}/configs/config.all" | cut -d '=' -f 2 | md5sum | cut -d ' ' -f 1)

	if [[ "$ADMIN_EMAIL_MD5SUM" != "160dfa42c0cb8e25311b6aff3a4d5361" ]]; then
		return 0;
	else
		return 1;
	fi
}

# Detect known cron.d path
# Return: KnownPath:string or 1:boolean
function detectKnownCronDPath() {
	if [[ -d "/etc/cron.d/" ]]; then
		# Debian, Ubuntu,...
		echo -n "/etc/cron.d/";
	elif [[ -d "/etc/fcron.cyclic/" ]]; then
		# IPFire
		echo -n "/etc/fcron.cyclic/";
	else
		return 1;
	fi
}

# Returns time difference
# Par 1: oldTimestamp:decimal
# Par 2: newTimestamp:decimal
# Return: Difference:integer or 1:boolean
function getTimeDifference() {
	DIFFERENCE=$(($2-$1))

	if [[ -n "$DIFFERENCE" ]]; then
		echo -n "$DIFFERENCE";
	else
		return 1;
	fi
}

# Checks last run timestamp and sets one, if none was set
# Par 1: minimumCheckIntervalInSeconds:decimal
# Return: 0:boolean or 1:boolean
function checkLastRunTimestamp() {
	LOCK_FILE=".ts3monitor.lock"
	CURRENT_TIMESTAMP=$(date +%s)

	if [[ -f ${LOCK_FILE} ]]; then
		LOCK_TIMESTAMP=$(< ${LOCK_FILE})
		TIME_DIFFERENCE=$(getTimeDifference $CURRENT_TIMESTAMP $LOCK_TIMESTAMP)

		if [[ "${TIME_DIFFERENCE}" -ge ${1} ]]; then
			return 0;
		fi
	else
		echo ${CURRENT_TIMESTAMP} > ${LOCK_FILE}
		return 0;
	fi

	return 1;
}

# Sends email notification
# Par 1: status:string (ok, crashed, started, stopped or failure)
# Par 2: service:string (ts3server or tsdnsserver)
# Par 3: InstanceDirectory:string
# Par 4: startscriptStatus:string (only with service ts3server)
# Par 5: TS3ServerInstanceLogPath:string (only with service ts3server)
# Return: 0:boolean or 1:boolean
function sendEmailNotification() {
	# Wait a few seconds, that the startup of the server can be finished
	sleep 5s

	EMAIL_RECEIPIENTS=$(getAdministratorEmail)
	EMAIL_SENDER_NAME=$(grep EMAIL_SENDER_NAME ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)
	HOST_NAME=$(hostname -s)
	HOST_DOMAIN=$(hostname -d)

	if [[ "${2}" == "ts3server" ]]; then
		SERVICE_NAME="TeamSpeak 3"

		INSTANCE_LOG_FILE="$(find ${3} -name *_0.log | sort -nr | head -1)"

		(
			echo	"Host: $(hostname -f) ($(hostname -I | cut -d ' ' -f 1))";
			echo -e "Datum: $(date +'%Y-%m-%d %H:%M %Z')\n";

			echo	"Instanz: ${3}/";
			if [[ "${1}" == "ok" ]]; then
				echo	"Status: OK - Server is running";
			elif [[ "${1}" == "crashed" ]]; then
				echo	"Status: Crashed - Server has been crashed";
			elif [[ "${1}" == "started" ]]; then
				echo	"Status: Stopped - Server has been shutdown successfully";
			elif [[ "${1}" == "stopped" ]]; then
				echo	"Status: Shutdown - Server has been shutdown gracefully";
			elif [[ "${1}" == "failure" ]]; then
				echo    "Status: Buggy - Server is online, but not running as expected"
			fi

			echo -e "TS3 Server Startscript: ${4}\n";

			echo	"See attached TeamSpeak 3 server instance log file for further details.";

			echo -e "\n\nSincerely,";
			echo	"TS3Monitor by TS3tools";
			echo	"https://github.com/TS3Tools/TS3Monitor";
		) | mail -a "From: ${EMAIL_SENDER_NAME} <no-reply@${HOST_DOMAIN}>" -s "[TS3Monitor] ${HOST_NAME}: Status of ${SERVICE_NAME} server instance '${3}'" ${EMAIL_RECEIPIENTS} -A ${INSTANCE_LOG_FILE}
	elif [[ "${2}" == "tsdnsserver" ]]; then
		SERVICE_NAME="TSDNS"

		(
			echo	"Host: $(hostname -f) ($(hostname -I | cut -d ' ' -f 1))";
			echo -e "Datum: $(date +'%Y-%m-%d %H:%M %Z')\n";

			echo	"Instanz: ${3}/";
			if [[ "${1}" == "ok" ]]; then
				echo	"Status: OK - Server is running";
			elif [[ "${1}" == "crashed" ]]; then
				echo	"Status: Restarted - Server has been crashed";
			fi

			echo -e "\n\nSincerely,";
			echo	"TS3Monitor by TS3tools";
			echo	"https://github.com/TS3Tools/TS3Monitor";
		) | mail -a "From: ${EMAIL_SENDER_NAME} <no-reply@${HOST_DOMAIN}>" -s "[TS3Monitor] ${HOST_NAME}: Status of ${SERVICE_NAME} server instance '${3}'" ${EMAIL_RECEIPIENTS}
	fi

	if [[ $? -eq 0 ]]; then
		return 0;
	fi

	return 1;
}

# Writes a log file
# Par 1: result:string
# Return: 0:boolean or 1:boolean
function writeAndAppendLog() {
	LOG_FILE_PATH="/var/log/ts3tools"
	LOG_FILE_NAME="ts3monitor.log"

	RESULT="${1}"

	if [[ ! -d ${LOG_FILE_PATH} ]]; then
		mkdir -p ${LOG_FILE_PATH}
	fi

	CURRENT_DATE=$(date +'%b %e %H:%M:%S')
	CURRENT_PID=$$

	echo "${CURRENT_DATE} $(hostname -s) ${TYPE}[${CURRENT_PID}]: (${REAL_LOGGED_IN_USER}) CMD (${PAR_FULL_CMD}) RESULT (${RESULT})" >> ${LOG_FILE_PATH}/${LOG_FILE_NAME};

	if [[ $? -eq 0 ]]; then
		return 0;
	else
		return 1;
	fi
}
