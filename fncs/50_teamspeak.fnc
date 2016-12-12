#!/usr/bin/env bash

# Get owner of TS3 server files
# Par 1: TS3ServerRootDirectory:string
# Return: Owner:string or 1:boolean
function getOwnerOfTS3ServerFiles() {
	OWNER="$(stat --format='%U' $(find ${1} -name 'ts3server_startscript.sh' 2> /dev/null | sort | tail -1))"

	if [[ -n "$OWNER" ]]; then
		echo -n "$OWNER";
	else
		return 1;
	fi
}

# Get owner of TSDNS server files
# Par 1: TSDNSServerRootDirectory:string
# Return: Owner:string or 1:boolean
function getOwnerOfTSDNSServerFiles() {
	OWNER="$(stat --format='%U' $(find ${1} -name 'tsdnsserver' 2> /dev/null | sort | tail -1))"

	if [[ -n "$OWNER" ]]; then
		echo -n "$OWNER";
	else
		return 1;
	fi
}

# Does INI-File exists?
# Par 1: TS3ServerRootDirectory:string
# Return: 0:boolean or 1:boolean
function INIFileExists() {
	if [[ -f "${1}/ts3server.ini" ]]; then
		return 0;
	else
		return 1;
	fi
}

# Find all TeamSpeak 3 server instances
# Return: ts3InstancePathsFilename:string or 1:string
function findTS3ServerInstances() {
	TS3InstancePathsFilename=$(mktemp /tmp/TS3InstancePaths.XXXXXXXX)
	if [[ "$SCRIPT_LICENSE_TYPE" == "2" ]]; then
		if [[ "$PAR_PATH_DIRECTORY" == "/" ]]; then
			find / -name 'ts3server_startscript.sh' 2> /dev/null | grep -Eiv "/tmp/TS3Tools|/var/backups/TS3Tools" | sort > ${TS3InstancePathsFilename}
		else
			echo "$PAR_PATH_DIRECTORY/ts3server_startscript.sh" > ${TS3InstancePathsFilename}
		fi
	else
		find / -name 'ts3server_startscript.sh' 2> /dev/null | grep -Eiv "/tmp/TS3Tools|/var/backups/TS3Tools" | sort | head -1 > ${TS3InstancePathsFilename}
	fi

	if [[ -s ${TS3InstancePathsFilename} ]]; then
		echo -n "${TS3InstancePathsFilename}";
	else
		echo -n "1";
	fi
}

# Find all TSDNS server instances
# Return: 0:boolean or 1:string
function findTSDNSServerInstances() {
	TSDNSInstancePathsFilename=$(mktemp /tmp/TSDNSInstancePaths.XXXXXXXX)
	if [[ "$SCRIPT_LICENSE_TYPE" == "2" ]]; then
		if [[ "$PAR_PATH_DIRECTORY" == "/" ]]; then
			find / -name 'tsdns_settings.ini' 2> /dev/null | grep -Eiv "/tmp/TS3Tools|/var/backups/TS3Tools" | sort > ${TSDNSInstancePathsFilename}
		else
			echo "$PAR_PATH_DIRECTORY/tsdns_settings.ini" > ${TSDNSInstancePathsFilename}
		fi
	else
		find / -name 'tsdns_settings.ini' 2> /dev/null | grep -Eiv "/tmp/TS3Tools|/var/backups/TS3Tools" | sort | head -1 > ${TSDNSInstancePathsFilename}
	fi

	if [[ -s ${TSDNSInstancePathsFilename} ]]; then
		echo -n "${TSDNSInstancePathsFilename}";
	else
		echo -n "1";
	fi
}

# Returns the real root directory of the TS3 server (required for ExaGear support)
# Par 1: TeamSpeakRootDirectory:String
# Return: realTeamSpeakRootDirectory:String
function findRealTS3RootDirectory() {
	if [[ -d "/opt/exagear/" ]]; then
		EXAGEAR_ENVIRONMENT="$(find /opt/exagear/images/ -maxdepth 1 -type d ! -path /opt/exagear/images/)"
		EXAGEAR_ENVIRONMENT_ESCAPED=$(echo -n "${EXAGEAR_ENVIRONMENT}" | sed -r 's/\//\\\//g')
		FOUND_TEAMSPEAK_DIRECTORY=$(grep -E "${1}" TS3InstancePaths.txt | sed 's/'${EXAGEAR_ENVIRONMENT_ESCAPED}'//' | sed 's/ts3server_startscript.sh//g')
		TEAMSPEAK_ROOT_DIRECTORY="${EXAGEAR_ENVIRONMENT}${FOUND_TEAMSPEAK_DIRECTORY}"
	else
		TEAMSPEAK_ROOT_DIRECTORY="${1}/"
	fi

	echo -n "${TEAMSPEAK_ROOT_DIRECTORY}";
}

# Get TS3 server instance log path
# Par 1: TS3ServerRootDirectory:string
# Return: InstanceLogPath:string or 1:boolean
function getTS3ServerInstanceLogPath() {
	INSTANCE_LOG_PATH=""

	if INIFileExists ${1}; then
		INSTANCE_LOG_PATH_TEMP="$(grep logpath < ${1}/ts3server.ini | cut -d '=' -f 2)"
	else
		INSTANCE_LOG_PATH_TEMP="$(findRealTS3RootDirectory ${1})logs/"
	fi

	# Absolute or relative path?
	if [[ "$INSTANCE_LOG_PATH_TEMP" = /* ]]; then
		INSTANCE_LOG_PATH="$INSTANCE_LOG_PATH_TEMP"
	else
		cd ${1}/$INSTANCE_LOG_PATH_TEMP
		INSTANCE_LOG_PATH="$(pwd)"
		cd - > /dev/null
	fi

	if [[ -n "$INSTANCE_LOG_PATH" ]]; then
		echo -n "$INSTANCE_LOG_PATH";
	else
		return 1;
	fi
}

# Start, Status, Stop TS3 server instance
# Par 1: TeamSpeakRootDirectory:string
# Par 2: Action:string
# Return: 0:boolean or 1:boolean
function ts3server() {
	TS3SERVER_BINARY="ts3server";

	case $2 in
		start)
			STARTSCRIPT_STATUS=$(su -s "$(which bash)" -c "cd $1 && ./ts3server_startscript.sh start 2> /dev/null && cd - > /dev/null" - $(getOwnerOfTS3ServerFiles $1))

			if [[ "$STARTSCRIPT_STATUS" =~ 'TeamSpeak 3 server started, for details please view the log file' ]]; then
				return 0;
			else
				return 1;
			fi
		;;

		status)
			STARTSCRIPT_STATUS=$(su -s "$(which bash)" -c "cd $1 && ./ts3server_startscript.sh status && cd - > /dev/null" - $(getOwnerOfTS3ServerFiles $1))

			PROCESS_STATUS=0;
			ps opid= -C ${TS3SERVER_BINARY} > TEMP_PROCESS_LIST.txt
			if [ $? -eq 0 ]; then
				while read pid; do
					TS3SERVER_PID=$(echo "${pid}" | tr -d '[:space:]')

					if [[ -n "${TS3SERVER_PID}" ]]; then
						TS3SERVER_PATH="$(pwdx ${TS3SERVER_PID} | cut -d " " -f 2 | tr -d '[:space:]')"

						if [[ "${TS3SERVER_PATH}" == "${1}" ]]; then
							PROCESS_STATUS=1;
							break;
						fi
					fi
				done < TEMP_PROCESS_LIST.txt
			fi

			if [[ -f TEMP_PROCESS_LIST.txt ]]; then
				rm TEMP_PROCESS_LIST.txt
			fi

			if [[ "$STARTSCRIPT_STATUS" =~ 'Server is running' ]] && [[ "${PROCESS_STATUS}" -eq 1 ]]; then
				return 0;
			else
				return 1;
			fi
		;;

		stop)
			STARTSCRIPT_STATUS=$(su -s "$(which bash)" -c "cd $1 && ./ts3server_startscript.sh stop && cd - > /dev/null" - $(getOwnerOfTS3ServerFiles $1))

			PROCESS_KILL=0;
			if [[ "$STARTSCRIPT_STATUS" =~ 'No server running (ts3server.pid is missing)' ]]; then
				ps opid= -C ${TS3SERVER_BINARY} > TEMP_PROCESS_LIST.txt
				if [ $? -eq 0 ]; then
					while read pid; do
						TS3SERVER_PID=$(echo "${pid}" | tr -d '[:space:]')

						if [[ -n "${TS3SERVER_PID}" ]]; then
							TS3SERVER_PATH="$(pwdx ${TS3SERVER_PID} | cut -d " " -f 2 | tr -d '[:space:]')"

							if [[ "${TS3SERVER_PATH}" == "${1}" ]]; then
								kill -9 ${TS3SERVER_PID}

								if [[ $? -eq 0 ]]; then
									PROCESS_KILL=1;
								fi

								break;
							fi
						fi
					done < TEMP_PROCESS_LIST.txt
				fi

				if [[ -f TEMP_PROCESS_LIST.txt ]]; then
					rm TEMP_PROCESS_LIST.txt
				fi
			fi

			TS3SERVER_PID_DELETION=0;
			if [[ -f ${1}/ts3server.pid ]]; then
				rm ${1}/ts3server.pid

				if [[ $? -eq 0 ]]; then
					TS3SERVER_PID_DELETION=1;
				fi
			fi

			if [[ "$STARTSCRIPT_STATUS" =~ 'Stopping the TeamSpeak 3 server' ]] || [[ "${PROCESS_KILL}" -eq 1 ]] || [[ "${TS3SERVER_PID_DELETION}" -eq 1 ]]; then
				return 0;
			else
				return 1;
			fi
		;;

		*)
			return 1;
		;;
	esac
}

# Start, Status, Stop, Update TSDNS
# Par 1: TeamSpeakRootDirectory:string
# Par 2: Action:string
# Return: 0:boolean or 1:boolean
function tsdns() {
	DIRECTORY="${1}"
	TSDNS_BINARY="tsdnsserver"

	if [ $(ps opid= -C ${TSDNS_BINARY}) ]; then
		TSDNS_PID=$(ps opid= -C ${TSDNS_BINARY} | tr -d '[:space:]')

		if [[ -n "$TSDNS_PID" ]]; then
			TSDNS_PATH="$(pwdx ${TSDNS_PID} | cut -d " " -f 2 | tr -d '[:space:]')"
		fi
	fi

	case $2 in
		start)
			if [ -f "${DIRECTORY}/tsdns_settings.ini" ]; then
				cd ${DIRECTORY}/
				su -s "$(which bash)" -c "./${TSDNS_BINARY} &" $(getOwnerOfTSDNSServerFiles ${DIRECTORY})
				cd - > /dev/null

				return 0;
			else
				return 1;
			fi
		;;

		status)
			if [[ -n "$TSDNS_PID" ]]; then
				if [[ "$TSDNS_PATH" == "${DIRECTORY}" ]]; then
					return 0;
				else
					return 1;
				fi
			else
				return 1;
			fi
		;;

		stop)
			if [[ -n "$TSDNS_PID" ]]; then
				if [[ "$TSDNS_PATH" == "${DIRECTORY}" ]]; then
					if [ ! $(kill -9 ${TSDNS_PID}) ]; then
						return 0;
					else
						return 1;
					fi
				else
					return 1;
				fi
			else
				return 1;
			fi
		;;

		update)
			if [ -f "${DIRECTORY}/tsdns_settings.ini" ]; then
				cd ${DIRECTORY}/
				su -s "$(which bash)" -c "./${TSDNS_BINARY} --update" $(getOwnerOfTSDNSServerFiles ${DIRECTORY})
				cd - > /dev/null

				return 0;
			else
				return 1;
			fi
		;;
	esac
}

# Identify reason for stopped TeamSpeak 3 server
# Par 1: TeamSpeakRootDirectory:string
# Return: status:string or 1:boolean
function identifyReasonForStoppedTS3Server() {
	STARTSCRIPT_STATUS=$(su -s "$(which bash)" -c "cd $1 && ./ts3server_startscript.sh status && cd - > /dev/null" - $(getOwnerOfTS3ServerFiles $1))

	if [[ -f ${1}/ts3server.pid ]]; then
		TS3SERVER_PID_FILE_EXISTS=1;
	else
		TS3SERVER_PID_FILE_EXISTS=0;
	fi

	PROCESS_STATUS=0;
	ps opid= -C ${TS3SERVER_BINARY} > TEMP_PROCESS_LIST.txt
	if [ $? -eq 0 ]; then
		while read pid; do
			TS3SERVER_PID=$(echo "${pid}" | tr -d '[:space:]')

			if [[ -n "${TS3SERVER_PID}" ]]; then
				TS3SERVER_PATH="$(pwdx ${TS3SERVER_PID} | cut -d " " -f 2 | tr -d '[:space:]')"

				if [[ "${TS3SERVER_PATH}" == "${1}" ]]; then
					PROCESS_STATUS=1;
					break;
				fi
			fi
		done < TEMP_PROCESS_LIST.txt
	fi

	if [[ -f TEMP_PROCESS_LIST.txt ]]; then
		rm TEMP_PROCESS_LIST.txt
	fi

	if [[ -n "${STARTSCRIPT_STATUS}" ]]; then
		echo -n "${STARTSCRIPT_STATUS}|${TS3SERVER_PID_FILE_EXISTS}|${PROCESS_STATUS}";
	fi

	return 1;
}
