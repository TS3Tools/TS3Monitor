#!/usr/bin/env bash

# Main program
function main() {
	# Load text for set language
	LANGUAGE_CODE="$(grep 'DEFAULT_LANGUAGE' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
	if [[ -n "${LANGUAGE_CODE}" ]]; then
		if [[ -f "${ABSOLUTE_PATH}/languages/verified/${LANGUAGE_CODE}.conf" ]]; then
			PAR_LOCALE="languages/verified/${LANGUAGE_CODE}.conf";
		else
			PAR_LOCALE="languages/verified/en_US.conf";
		fi
	else
		PAR_LOCALE="languages/verified/en_US.conf";
	fi
	cd "$ABSOLUTE_PATH"
	source $PAR_LOCALE;
	cd - > /dev/null

	# En-/Disable writing of TS3Monitor log file
	WRITE_TS3MONITOR_LOG="$(grep 'WRITE_TS3MONITOR_LOG' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
	if [[ "${WRITE_TS3MONITOR_LOG}" != "true" ]] && [[ "${WRITE_TS3MONITOR_LOG}" != "false" ]] ; then
		WRITE_TS3MONITOR_LOG="true";
	fi

	# Load required functions
	for file in $(find "${ABSOLUTE_PATH}/fncs/" -type f -name "*_script.fnc" | sort -n); do
		. "${file}"
	done

	# Enable debugging
	if [[ -n "$PAR_DEBUG" ]] && [[ "$PAR_DEBUG" == 1 ]]; then
		echo "$TXT_DEBUG_INFO: ${PAR_LIST} [v${SCRIPT_VERSION}]";
		set -x
	fi

	##
	## SELFTESTS
	##
	if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
		echo -n "${TXT_SELF_TEST_INFO}";
	else
		echo -en "${SCurs}${TXT_SELF_TEST_INFO}";
		echo -e "${RCurs}${MCurs}[ ${Whi}.. ${RCol}]\n";
	fi

	# Self-Tests status flag
	SELF_TEST_STATUS=0;

	# Check consistency of script
	if ! checkConsistency; then
		echo "${TXT_SELF_TEST_CHECK_CONSISTENCY}" >> SELF_TEST_STATUS.txt;
		SELF_TEST_STATUS=1;
	fi

	# Latest version of script installed?
	LATEST_SCRIPT_VERSION=$(getLatestScriptVersion)

	if [[ "$LATEST_SCRIPT_VERSION" != 1 ]]; then
		if [[ -n "$LATEST_SCRIPT_VERSION" ]]; then
			if [[ "$SCRIPT_VERSION" != "$LATEST_SCRIPT_VERSION" ]]; then
				echo -e "${TXT_SELF_TEST_TS3MONITOR_RELEASED}: ./$SCRIPT_NAME --update-script\n" >> SELF_TEST_STATUS.txt;
			fi
		else
			echo "${TXT_SELF_TEST_DETECTION_FAILED}" >> SELF_TEST_STATUS.txt;
			SELF_TEST_STATUS=1;
		fi
	fi

	# Execute software checks
	if [[ $(checkdeps bash which grep) -eq 1 ]]; then
		SELF_TEST_STATUS=1;
	fi

	# Detect known cron.d path
	if [[ "$PAR_INSTALL_CRONJOB" -eq 1 ]] || [[ "$PAR_DEINSTALL_CRONJOB" -eq 1 ]]; then
		CROND_PATH="$(detectKnownCronDPath)"

		if [[ "$CROND_PATH" == "1" ]]; then
			echo "${TXT_SELF_TEST_SCRIPT_SUPPORT}" >> SELF_TEST_STATUS.txt;
			SELF_TEST_STATUS=1;
		fi
	fi

	# Set own settings in config files?
	if ! scriptSettingsChanged; then
		echo "${TXT_SELF_TEST_ADMINISTRATOR_EMAIL}" >> SELF_TEST_STATUS.txt;
		SELF_TEST_STATUS=1;
	fi

	if [[ "$SCRIPT_LICENSE_TYPE" == "1" ]]; then
		if ! checkLastRunTimestamp 1800; then
			echo "${TXT_SELF_TEST_LAST_RUN}" >> SELF_TEST_STATUS.txt;
			SELF_TEST_STATUS=1;
		fi
	elif [[ "$SCRIPT_LICENSE_TYPE" == "0" ]]; then
		if ! checkLastRunTimestamp 3600; then
			echo "${TXT_SELF_TEST_LAST_RUN}" >> SELF_TEST_STATUS.txt;
			SELF_TEST_STATUS=1;
		fi
	fi

	# Run other tasks, if all self-tests were successfull
	if [[ "$SELF_TEST_STATUS" -eq 1 ]]; then
		if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
			echo "[ FAILED ]";
		else
			echo -e "${RCurs}${MCurs}[ ${Red}FAILED ${RCol}]\n";
		fi

		# Show failed self-tests
		cat SELF_TEST_STATUS.txt;

		echo "${TXT_SELF_TEST_FAILED}";
	else
		if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
			echo "[ OK ]";
		else
			echo -e "${RCurs}${MCurs}[ ${Gre}OK ${RCol}]\n";
		fi

                # Show TS3Monitor update message
		if [[ -f SELF_TEST_STATUS.txt ]]; then
			cat SELF_TEST_STATUS.txt
		fi

		if [[ "$PAR_UPDATE_SCRIPT" -eq 1 ]]; then
			if [[ "$SCRIPT_VERSION" != "$LATEST_SCRIPT_VERSION" ]]; then
				if [[ "$PAR_CRONJOB_TASK" -eq 1 ]]; then
					UPDATE_SCRIPT_ANSWER=1;
				else
					UPDATE_SCRIPT_ANSWER=2;
					while [[ "$UPDATE_SCRIPT_ANSWER" -eq 2 ]]; do
						read -p "${TXT_EXECUTION_MECHANISM_SCRIPT_UPDATE_ANSWER} ([y]es/[n]o) " UPDATE_SCRIPT_ANSWER <&5

						if [[ -n "$UPDATE_SCRIPT_ANSWER" ]] && [[ "$UPDATE_SCRIPT_ANSWER" != "y" ]] && [[ "$UPDATE_SCRIPT_ANSWER" != "yes" ]] && [[ "$UPDATE_SCRIPT_ANSWER" != "n" ]] && [[ "$UPDATE_SCRIPT_ANSWER" != "no" ]]; then
							echo -en "${SCurs}${TXT_EXECUTION_MECHANISM_SCRIPT_UPDATE_ANSWER_ERROR}";
							echo -e "${RCurs}${MCurs}[ ${Red}ERROR ${RCol}]";
							UPDATE_SCRIPT_ANSWER=2;
						elif [[ "$UPDATE_SCRIPT_ANSWER" == "y" ]] || [[ "$UPDATE_SCRIPT_ANSWER" == "yes" ]]; then
							UPDATE_SCRIPT_ANSWER=1;
						elif [[ "$UPDATE_SCRIPT_ANSWER" == "n" ]] || [[ "$UPDATE_SCRIPT_ANSWER" == "no" ]]; then
							UPDATE_SCRIPT_ANSWER=0;
						fi
					done
				fi
			else
				UPDATE_SCRIPT_ANSWER=0;
			fi

			if [[ "$PAR_CRONJOB_TASK" -eq 1 ]]; then
				echo -n "${TXT_EXECUTION_MECHANISM_SCRIPT_UPDATE_INFO}";
			else
				echo -en "${SCurs}${TXT_EXECUTION_MECHANISM_SCRIPT_UPDATE_INFO}";
				echo -e "${RCurs}${MCurs}[ ${Whi}.. ${RCol}]";
			fi

			if [[ "$UPDATE_SCRIPT_ANSWER" -eq 1 ]]; then
				if updateTS3Monitor; then
					if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
						echo "[ Should be updated ]";
					else
						echo -e "${RCurs}${MCursBB}[ ${Gre}Should be updated ${RCol}]\n";
					fi
				else
					if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
						echo "[ FAILED ]";
					else
						echo -e "${RCurs}${MCurs}[ ${Red}FAILED ${RCol}]\n";
					fi
				fi
			elif [[ "$UPDATE_SCRIPT_ANSWER" -eq 0 ]]; then
				if [ "$PAR_CRONJOB_TASK" -eq 1 ]; then
					echo "[ Was not updated ]";
				else
					echo -e "${RCurs}${MCursBB}[ ${Cya}Was not updated ${RCol}]";
				fi
			fi
		elif [[ "$PAR_DISPLAY_SETTINGS" -eq 1 ]]; then
			echo	"Following your settings:";
			echo    "############################################################################";
			echo -e "	Default language:\t\t$(grep 'DEFAULT_LANGUAGE' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
			echo -e "	Write TS3Monitor Log:\t\t$(grep 'WRITE_TS3MONITOR_LOG' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
			echo -e "	Administrator E-Mail:\t\t$(getAdministratorEmail)";
			echo -e "	Send Emails always:\t\t$(grep 'SEND_EMAIL_ALWAYS' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
			echo -e "	Delete old TS3 server logs:\t$(grep 'TS3SERVER_DELETE_OLD_LOGS' ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)";
			echo	"############################################################################";
		elif [[ "${PAR_INSTALL_CRONJOB}" -eq 1 ]]; then
			echo -en "${SCurs}${TXT_EXECUTION_MECHANISM_CRONJOB_INSTALLATION_INFO}";
			echo -e "${RCurs}${MCurs}[ ${Whi}.. ${RCol}]\n";

			if crond ${CROND_PATH} install ${PAR_PATH_DIRECTORY} ${PAR_CRONJOB_HOUR} ${PAR_CRONJOB_MINUTE}; then
				echo -e "${RCurs}${MCurs}[ ${Gre}OK ${RCol}]\n";

				echo "${TXT_EXECUTION_MECHANISM_CRONJOB_INSTALLATION_SUCCESSFUL} ${CROND_PATH_FILE}";
			else
				echo -e "${RCurs}${MCurs}[ ${Red}FAILED ${RCol}]\n";
				EXECUTION_MECHANISM_STATUS=1;
			fi
		elif [[ "${PAR_DEINSTALL_CRONJOB}" -eq 1 ]]; then
			echo -en "${SCurs}${TXT_EXECUTION_MECHANISM_CRONJOB_DEINSTALLATION_INFO}";
			echo -e "${RCurs}${MCurs}[ ${Whi}.. ${RCol}]\n";

			if crond ${CROND_PATH} deinstall; then
				echo -e "${RCurs}${MCurs}[ ${Gre}OK ${RCol}]\n";

				echo "${TXT_EXECUTION_MECHANISM_CRONJOB_DEINSTALLATION_SUCCESSFUL}: ${CROND_PATH}TS3Monitor";
			else
				echo -e "${RCurs}${MCurs}[ ${Red}FAILED ${RCol}]\n";
			fi
		elif [[ "${PAR_TS3SERVER}" -eq 1 ]]; then
			TS3SERVER_DELETE_OLD_LOGS="$(grep TS3SERVER_DELETE_OLD_LOGS ${ABSOLUTE_PATH}/configs/config.all | cut -d "=" -f 2)"
			if [[ "${TS3SERVER_DELETE_OLD_LOGS}" == "true" ]]; then
				DELETE_OLD_LOGS=1;
			else
				DELETE_OLD_LOGS=0;
			fi
			SEND_EMAIL_ALWAYS=$(grep SEND_EMAIL_ALWAYS ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)
			TS3InstancePathsFilename="$(findTS3ServerInstances)"

			if [[ "${TS3InstancePathsFilename}" != "1" ]]; then
				while read instancePath; do
					INSTANCE_PATH=$(dirname $instancePath)

					echo "${TXT_EXECUTION_CHECKING_TS3SERVER}: ${INSTANCE_PATH}";

					# Detect instance log path
					TS3_SERVER_INSTANCE_LOG_PATH="$(getTS3ServerInstanceLogPath ${INSTANCE_PATH})";

					if [[ "$TS3_SERVER_INSTANCE_LOG_PATH" == "1" ]]; then
						echo "${TXT_COLLECTING_INFORMATION_INSTANCE_LOG_PATH_DETECTION_FAILED}" >> COLLECTING_INFORMATION_STATUS.txt;
					fi

					if ts3server ${INSTANCE_PATH} status; then
						echo "${TXT_EXECUTION_INSTANCE_IS_RUNNING_AS_EXPECTED}";

						REASONS=$(identifyReasonForStoppedTS3Server ${INSTANCE_PATH})
						STARTSCRIPT_STATUS=$(echo "${REASONS}" | cut -d '|' -f 1)

						if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
							writeAndAppendLog "${STARTSCRIPT_STATUS}"
						fi

						if [[ "${SEND_EMAIL_ALWAYS}" == "true" ]]; then
							if sendEmailNotification "ok" "ts3server" ${INSTANCE_PATH} "${STARTSCRIPT_STATUS}" ${TS3_SERVER_INSTANCE_LOG_PATH}; then
								echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
							else
								echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
							fi
						fi
					else
						echo "${TXT_EXECUTION_INSTANCE_IS_NOT_RUNNING}";

						REASONS=$(identifyReasonForStoppedTS3Server ${INSTANCE_PATH})
						STARTSCRIPT_STATUS=$(echo "${REASONS}" | cut -d '|' -f 1)
						TS3SERVER_PID_FILE_EXISTS=$(echo "${REASONS}" | cut -d '|' -f 2)
						PROCESS_STATUS=$(echo "${REASONS}" | cut -d '|' -f 3)

						if [[ "${STARTSCRIPT_STATUS}" == 'No server running (ts3server.pid is missing)' ]] && [[ "${TS3SERVER_PID_FILE_EXISTS}" -eq 0 ]] && [[ "${PROCESS_STATUS}" -eq 0 ]]; then
							echo "${TXT_EXECUTION_INSTANCE_STOPPED_GRACEFUL}";

							if [[ -f ${INSTANCE_PATH}/.ts3updatescript.lock ]]; then
								echo "${TXT_EXECUTION_INSTANCE_STOPPED_BY_TS3UPDATESCRIPT}";
							elif [[ "${PAR_FORCE_START}" -eq 1 ]] && [[ ! -f ${INSTANCE_PATH}/.ts3updatescript.lock ]]; then
								echo "${TXT_EXECUTION_INSTANCE_STARTING_GRACEFUL_STOPPED}";

								if [[ "${DELETE_OLD_LOGS}" -eq 1 ]]; then
									if [[ "$TS3_SERVER_INSTANCE_LOG_PATH" != "1" ]]; then
										if [[ ! $(rm -f ${TS3_SERVER_INSTANCE_LOG_PATH}/*) ]]; then
											echo "${TXT_EXECUTION_DELETING_OLD_LOGS_SUCCESSFUL}";
										else
											echo "${TXT_EXECUTION_DELETING_OLD_LOGS_FAILURE}";
										fi
									fi
								fi

								if ts3server ${INSTANCE_PATH} start; then
									echo "${TXT_EXECUTION_INSTANCE_STARTED_SUCCESSFUL}";

									if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
										writeAndAppendLog "${STARTSCRIPT_STATUS}"
									fi

									if sendEmailNotification "started" "ts3server" ${INSTANCE_PATH} "${STARTSCRIPT_STATUS}" ${TS3_SERVER_INSTANCE_LOG_PATH}; then
										echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
									else
										echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
									fi
								else
									echo "${TXT_EXECUTION_INSTANCE_STARTED_FAILURE}";
								fi
							fi

							REASONS=$(identifyReasonForStoppedTS3Server ${INSTANCE_PATH})
							STARTSCRIPT_STATUS=$(echo "${REASONS}" | cut -d '|' -f 1)

							if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
								writeAndAppendLog "${STARTSCRIPT_STATUS}"
							fi

							if sendEmailNotification "stopped" "ts3server" ${INSTANCE_PATH} "${STARTSCRIPT_STATUS}" ${TS3_SERVER_INSTANCE_LOG_PATH}; then
								echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
							else
								echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
							fi
						else
							echo "${TXT_EXECUTION_INSTANCE_CRASHED}";

							if ts3server ${INSTANCE_PATH} stop; then
								echo "${TXT_EXECUTION_INSTANCE_STOPPED_FOR_GRACEFUL_START}";

								if [[ "${DELETE_OLD_LOGS}" -eq 1 ]]; then
									if [[ "$TS3_SERVER_INSTANCE_LOG_PATH" != "1" ]]; then
										if [[ ! $(rm -f ${TS3_SERVER_INSTANCE_LOG_PATH}/*) ]]; then
											echo "${TXT_EXECUTION_DELETING_OLD_LOGS_SUCCESSFUL}";
										else
											echo "${TXT_EXECUTION_DELETING_OLD_LOGS_FAILURE}";
										fi
									fi
								fi

								if ts3server ${INSTANCE_PATH} start; then
									echo "${TXT_EXECUTION_INSTANCE_STARTED_SUCCESSFUL}";

									if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
										writeAndAppendLog "${STARTSCRIPT_STATUS}"
									fi

									if sendEmailNotification "crashed" "ts3server" ${INSTANCE_PATH} "${STARTSCRIPT_STATUS}" ${TS3_SERVER_INSTANCE_LOG_PATH}; then
										echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
									else
										echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
									fi
								else
									echo "${TXT_EXECUTION_INSTANCE_STARTED_FAILURE}";
								fi
							else
								echo "${TXT_EXECUTION_INSTANCE_GRACEFUL_STOP_FAILURE}";

								REASONS=$(identifyReasonForStoppedTS3Server ${INSTANCE_PATH})
								STARTSCRIPT_STATUS=$(echo "${REASONS}" | cut -d '|' -f 1)

								if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
									writeAndAppendLog "${STARTSCRIPT_STATUS}"
								fi

								if sendEmailNotification "failure" "ts3server" ${INSTANCE_PATH} "${STARTSCRIPT_STATUS}" ${TS3_SERVER_INSTANCE_LOG_PATH}; then
									echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
								else
									echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
								fi
							fi
						fi
					fi
				done < ${TS3InstancePathsFilename}
			fi
		elif [[ "${PAR_TSDNSSERVER}" -eq 1 ]]; then
			SEND_EMAIL_ALWAYS=$(grep SEND_EMAIL_ALWAYS ${ABSOLUTE_PATH}/configs/config.all | cut -d '=' -f 2)
			TSDNSServerInstancePathsFilename="$(findTSDNSServerInstances)"

			if [[ "${TSDNSServerInstancePathsFilename}" != "1" ]]; then
				while read instancePath; do
					INSTANCE_PATH=$(dirname $instancePath)

					echo "${TXT_EXECUTION_CHECKING_TSDNSSERVER}: ${INSTANCE_PATH}";

					if tsdns ${INSTANCE_PATH} status; then
						echo "${TXT_EXECUTION_INSTANCE_IS_RUNNING_AS_EXPECTED}";

						if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
							writeAndAppendLog "OK - service is running"
						fi

						if [[ "${SEND_EMAIL_ALWAYS}" == "true" ]]; then
							if sendEmailNotification "ok" "tsdnsserver" ${INSTANCE_PATH}; then
                                                                echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
							else
                                                                echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
							fi
						fi
					else
						echo "${TXT_EXECUTION_INSTANCE_IS_NOT_RUNNING}";

						if [[ ! -f ${INSTANCE_PATH}/../.ts3updatescript.lock ]]; then
							if tsdns ${INSTANCE_PATH} start; then
								echo "${TXT_EXECUTION_INSTANCE_STARTED_SUCCESSFUL}";

								if [[ "${WRITE_TS3MONITOR_LOG}" == "true" ]]; then
									writeAndAppendLog "CRASHED - Restarted service"
								fi

								if sendEmailNotification "crashed" "tsdnsserver" ${INSTANCE_PATH}; then
									echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_SENT}";
								else
									echo "${TXT_EXECUTION_NOTIFICATION_EMAIL_FAILURE}";
								fi
							else
								echo "${TXT_EXECUTION_INSTANCE_STARTED_FAILURE}";
							fi
						else
							echo "${TXT_EXECUTION_INSTANCE_STOPPED_BY_TS3UPDATESCRIPT}";
						fi
					fi
				done < ${TSDNSServerInstancePathsFilename}
			fi
		fi
	fi

	###
	### Cleanup
	###
	echo "${TXT_CLEANUP_INFO}";

	if [ -f SELF_TEST_STATUS.txt ]; then
		rm SELF_TEST_STATUS.txt
	fi

	if [ -f TS3InstancePaths.txt ]; then
		rm TS3InstancePaths.txt
	fi

	if [ -f TSDNSInstancePaths.txt ]; then
		rm TSDNSInstancePaths.txt
	fi
}
