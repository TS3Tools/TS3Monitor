#!/usr/bin/env bash

# Checks list of given software packages
# Par X: package:string
# Return: 0:boolean or 1:boolean
function checkdeps() {
	CHECKDEPS_FAILED=0;

	for cmd; do
		package_cmd=$(echo $cmd | cut -d ':' -f 1)
		package=$(echo $cmd | cut -d ':' -f 2)

		if [[ -z "$package" ]]; then
			package=$cmd
		fi

		command -v >&- "$package_cmd" || {
			printf >&2 "Package %s" "'$package' was not found. Please install this package.\n" >> SELF_TEST_STATUS.txt;
			CHECKDEPS_FAILED=1;
		}
	done

	if [[ "${CHECKDEPS_FAILED}" -eq 1 ]]; then
		return 1;
	fi

	return 0;
}
