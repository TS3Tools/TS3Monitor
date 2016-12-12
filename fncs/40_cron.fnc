#!/usr/bin/env bash

# Checks list of given software packages
# Par 1: crondPath:string
# Par 2: install:string or deinstall:string
# Par 3: instancePath:string
# Par 4: cronjobHour:string (optional)
# Par 5: cronjobMinute:string (optional)
# Return: 0:boolean or 1:boolean
function crond() {
	CROND_PATH=${1}
	CROND_PATH_FILE="${CROND_PATH}TS3Monitor"

	if [[ "${2}" == "install" ]]; then
		if [ "$CROND_PATH" == "/etc/fcron.cyclic/" ]; then
			echo -en "#!/usr/bin/env bash\n" > ${CROND_PATH_FILE};
			echo -en "PATH=/usr/local/bin:/usr/bin:/bin\n" >> ${CROND_PATH_FILE};
		else
			echo -en "PATH=/usr/local/bin:/usr/bin:/bin\n" > ${CROND_PATH_FILE};
		fi

		echo -en "#MAILTO=\"$(getAdministratorEmail)\"\n\n" >> ${CROND_PATH_FILE};
		echo -en "# TS3Monitor: Cronjob for updating the script\n" >> ${CROND_PATH_FILE};

		echo -e "  45 2 * * *  root $(pwd)/$(basename $0) --update-script\n" >> ${CROND_PATH_FILE};

		echo -en "# TS3Monitor: Cronjob(s) for monitoring\n" >> ${CROND_PATH_FILE};

		if [[ -n "${5}" ]]; then
			CRONJOB_MINUTE=${5};
		else
			CRONJOB_MINUTE="0";
		fi

		if [[ -n "${4}" ]]; then
			CRONJOB_HOUR=${4};
		else
			CRONJOB_HOUR="*";
		fi

		if findTS3ServerInstances; then
			while read instancePath; do
				INSTANCE_PATH=$(dirname $instancePath)

				if [[ -n "$INSTANCE_PATH" ]]; then
					echo -n "  ${CRONJOB_MINUTE} ${CRONJOB_HOUR} * * *  root ${ABSOLUTE_PATH}/${SCRIPT_NAME} " >> ${CROND_PATH_FILE};

					if [ "$PAR_TS3SERVER" -eq 1 ]; then
						echo -n "ts3server " >> ${CROND_PATH_FILE};
					elif [ "$PAR_TSDNSSERVER" -eq 1 ]; then
						echo -n "tsdnsserver " >> ${CROND_PATH_FILE};
					fi

					if [[ "$SCRIPT_LICENSE_TYPE" == "2" ]]; then
						echo -n "--path ${INSTANCE_PATH} " >> ${CROND_PATH_FILE};
					fi

					if [[ "$PAR_FORCE_START" -eq 1 ]]; then
						echo -n "--force-start" >> ${CROND_PATH_FILE};
					fi

					echo -e "\n" >> ${CROND_PATH_FILE};

					if [ "$CRONJOB_MINUTE" == "55" ]; then
						CRONJOB_MINUTE="0";
						if [ "$CRONJOB_HOUR" != "*" ]; then
							CRONJOB_HOUR=`expr $CRONJOB_HOUR + 1`
						fi
					else
						CRONJOB_MINUTE=`expr $CRONJOB_MINUTE + 5`
					fi
				fi
			done < TS3InstancePaths.txt
		fi

		echo -en "# ^ ^ ^ ^ ^\n" >> ${CROND_PATH_FILE};
		echo -en "# | | | | |\n" >> ${CROND_PATH_FILE};
		echo -en "# | | | | |___ Weekday (0-7, Sunday is mostly 0)\n" >> ${CROND_PATH_FILE};
		echo -en "# | | | |_____ Month (1-12)\n" >> ${CROND_PATH_FILE};
		echo -en "# | | |_______ Day (1-31)\n" >> ${CROND_PATH_FILE};
		echo -en "# | |_________ Hour (0-23)\n" >> ${CROND_PATH_FILE};
		echo -en "# |___________ Minute (0-59)" >> ${CROND_PATH_FILE};

		# Set correct permissions for file
		chmod 644 ${CROND_PATH_FILE}

		if [[ $? -eq 0 ]]; then
			return 0;
		else
			return 1;
		fi
	elif [[ "${2}" == "deinstall" ]]; then
		if [ -f "$CROND_PATH/TS3Monitor" ]; then
			rm $CROND_PATH/TS3Monitor
		fi

		if [[ $? -eq 0 ]]; then
			return 0;
		else
			return 1;
		fi
	fi

	return 1;
}
