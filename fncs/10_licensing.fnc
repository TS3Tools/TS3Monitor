#!/usr/bin/env bash

LICENSE_SIP='aHR0cHM6Ly93d3cudHMzLXRvb2xzLmluZm8vdHMzdG9vbHMvbGljZW5zaW5nLnBocD9wPXRzM21vbml0Cg=='
LICENSE_SEC='b7b90c2161419c7d44c9002315a6340f85345ea543387b61327bb8125bb8b7c6fac6fba6a121caece2d173122b519032efb5dc6b8b571990a417e8b9916a2e39'

# Creates a unique license key
# Return: 0:boolean or 1:boolean
function createUniqueLicenseKey() {
	LDIR='L3Zhci9jYWNoZS90czN1cy8='
	LSEED='c2VlZAo='
	LKEY='LnRzM21vbml0X2xpY2Vuc2Vfa2V5Cg=='

	if [[ ! -d "$(echo "${LDIR}" | base64 --decode)" ]]; then
		if [[ $(mkdir -m 0755 "$(echo "${LDIR}" | base64 --decode)") ]]; then
			return 1;
		fi
	fi

	if [[ ! -f "$(echo "${LDIR}${LSEED}" | base64 --decode)" ]]; then
		dd if=/dev/urandom bs=1k count=1 2>/dev/null | od -t x1 -v | cut -d " " -f 2- | grep -E "^([0-9a-f]{2} )+[0-9a-f]{2}$" > $(echo "${LDIR}${LSEED}" | base64 --decode)
		if $? -eq 0; then
			return 1;
		fi
	fi

	IP=$(wget -t 3 -T 3 -qO- $(echo "${LICENSE_SIP}" | base64 --decode))
	HNAME=$(hostname -f)
	UNAME=$(uname -mo)
	DISTID=$(cut -d ' ' -f 1 < /etc/issue | tr -d '[[:space:]]')
	LSEED=$(cat $(echo "${LDIR}${LSEED}" | base64 --decode))

	echo "${IP}${HNAME}${UNAME}${LICENSE_SEC}${DISTID}${LSEED}" | md5sum | head -c 24 > "${ABSOLUTE_PATH}/"$(echo "${LKEY}" | base64 --decode)

	if [[ $? -ne 0 ]]; then
		return 1;
	fi

	return 0;
}

# Gets the license verify key from the licensing server
# Return: 0:boolean or 1:boolean
function getLicenseVerifyKey() {
	LDIR='L3Zhci9jYWNoZS90czN1cy8='
	LKEY='LnRzM21vbml0X2xpY2Vuc2Vfa2V5Cg=='
	LVKEY='dmVyaWZ5X2tleQo='
	LCHKSUM='a2V5Cg=='

	if ! createUniqueLicenseKey; then
		return 1;
	fi

	LKEY=$(< "${ABSOLUTE_PATH}/$(echo "${LKEY}" | base64 --decode)")
	wget -t 3 -T 3 -qO- "$(echo "${LICENSE_SIP}" | base64 --decode)&lkey=${LKEY}&v=${SCRIPT_VERSION}" > $(echo "${LDIR}${LVKEY}" | base64 --decode)

	if [[ $? -ne 0 ]]; then
		return 1;
	fi

	LVKEY=$(< $(echo "${LDIR}${LVKEY}" | base64 --decode))

	echo "${LKEY}${LVKEY}" | sha256sum | cut -d ' ' -f 1 > $(echo "${LDIR}${LCHKSUM}" | base64 --decode)

	if [[ $? -ne 0 ]]; then
		return 1;
	fi

	return 0;
}

# Checks the license every 7 days or immediately
# Par 1: force:string
# Return: license:string or 1:boolean
function checkLicense() {
	LDIR='L3Zhci9jYWNoZS90czN1cy8='
	LKEY='LnRzM21vbml0X2xpY2Vuc2Vfa2V5Cg=='
	LVKEY='dmVyaWZ5X2tleQo='
	LCHKSUM='a2V5Cg=='

	find $(echo "${LDIR}${LVKEY}" | base64 --decode) -mtime +7 -exec rm {} \;

	if [[ -n "$1" ]]; then
		if [[ "$1" == "force" ]]; then
			if [[ -f "${ABSOLUTE_PATH}/$(echo "${LKEY}" | base64 --decode)" ]]; then
				rm "${ABSOLUTE_PATH}/$(echo "${LKEY}" | base64 --decode)"
			fi
		fi
	fi

	if [[ ! -f "${ABSOLUTE_PATH}/$(echo "${LKEY}" | base64 --decode)" ]] || [[ ! -f "$(echo "${LDIR}${LVKEY}" | base64 --decode)" ]]; then
		if ! getLicenseVerifyKey; then
			return 1;
		else
			if [[ "$1" == "force" ]]; then
				return 0;
			fi
		fi
	fi

	LDIR='L3Zhci9jYWNoZS90czN1cy8='
	LKEY='LnRzM21vbml0X2xpY2Vuc2Vfa2V5Cg=='
	LVKEY='dmVyaWZ5X2tleQo='
	LCHKSUM='a2V5Cg=='

	LKEY=$(< "${ABSOLUTE_PATH}/$(echo "${LKEY}" | base64 --decode)")
	VKEY=$(< $(echo "${LDIR}${LVKEY}" | base64 --decode))
	CHKSUM=$(< $(echo "${LDIR}${LCHKSUM}" | base64 --decode))
	SHASUM=$(echo "${LKEY}${VKEY}" | sha256sum | cut -d ' ' -f 1)

	if [[ "${CHKSUM}" != "${SHASUM}" ]]; then
		if ! getLicenseVerifyKey; then
			return 1;
		fi
	fi

	LDEC=$(echo "${VKEY}" | base64 --decode | cut -d ':' -f 3-)

	if [[ -n "${LDEC}" ]]; then
		echo "${LDEC}";
	fi

	return 1;
}

# Returns license details
# Par 1: force:string (optional)
# Return: licenseDetails:string or 1:boolean
function getLicenseDetails() {
	LICENSE_DETAILS=""
	if [[ "${1}" == "force" ]]; then
		STR_LICENSE=$(checkLicense force)
	else
		STR_LICENSE=$(checkLicense)
	fi
	SCRIPT_LICENSE=$(echo "${STR_LICENSE}" | cut -d ':' -f 1);
	SCRIPT_LICENSE_START_TS=$(echo "${STR_LICENSE}" | cut -d ':' -f 2);
	SUPPORT_LICENSE=$(echo "${STR_LICENSE}" | cut -d ':' -f 3);
	SUPPORT_LICENSE_START_TS=$(echo "${STR_LICENSE}" | cut -d ':' -f 4);

	if [[ "${SCRIPT_LICENSE}" == "Community" ]] || [[ "${SCRIPT_LICENSE}" == "Professional" ]]; then
		SCRIPT_LICENSE_END="No support bought"
	else
		SCRIPT_LICENSE_START=$(date +'%Y-%m-%d' --date="@${SCRIPT_LICENSE_START_TS}")
		if [[ ${SCRIPT_LICENSE_START_TS} -lt 1472594400 ]]; then
			SCRIPT_LICENSE_END=$(date +'%Y-%m-%d' --date="@${SCRIPT_LICENSE_START_TS}" --date="+5 years")
		else
			SCRIPT_LICENSE_END=$(date +'%Y-%m-%d' --date="@${SCRIPT_LICENSE_START_TS}" --date="+2 years")
		fi
	fi

	if [[ "${SUPPORT_LICENSE}" == "Community" ]]; then
		SUPPORT_LICENSE_END="No support bought"
	else
		SUPPORT_LICENSE_START=$(date +'%Y-%m-%d' --date="@${SUPPORT_LICENSE_START_TS}")

		if [[ "${SUPPORT_LICENSE}" == "SLA-Basis" ]] || [[ "${SUPPORT_LICENSE}" == "SLA-Professional" ]]; then
			SUPPORT_LICENSE_END=$(date +'%Y-%m-%d' --date="@${SUPPORT_LICENSE_START_TS}" --date="+1 years")
		elif [[ "${SUPPORT_LICENSE}" == "SLA-Enterprise" ]]; then
			SUPPORT_LICENSE_END=$(date +'%Y-%m-%d' --date="@${SUPPORT_LICENSE_START_TS}" --date="+3 years")
		fi
	fi

	LICENSE_DETAILS="${SCRIPT_LICENSE}|${SCRIPT_LICENSE_START}|${SCRIPT_LICENSE_END}|${SUPPORT_LICENSE}|${SUPPORT_LICENSE_START}|${SUPPORT_LICENSE_END}"

	if [[ -n "${LICENSE_DETAILS}" ]]; then
		echo -n "${LICENSE_DETAILS}";
	fi

	return 1;
}
