# C H A N G E L O G

This file shows all the adjustments which were done in this TS3Monitor. For example there were some corrections on the code, some new features and bugfixes. This file is always referred to the attached TS3Monitor.

## Meaning of releases

Major Release | Minor Release | Hotfix Release
:------------- | :------------- | :-------------
4 | 1 | 0

Release | Meaning
:------------- | :-------------
Major | New features, Re-development of code (structure) and fundamental changes to the TS3Monitor
Minor | Small improvements, new best practice checks and something like this
Hotfix | Important fix for one more issues, which causes a not (correct) working TS3Monitor

## Legend / History

	+ Added something
	- Removed something
	* Changed/Fixed something
	! Hint/Warning

## Releases

### Version 1.1.0 (2017-05-04)

	* One translation for de_DE was missing
	* Installation of cronjob will now also set the ts3server and tsdns monitoring lines
	- Removed line with email from cronjob file, because it is not used
	+ TS3Monitor writes now also a log file to '/var/log/ts3tools/ts3monitor.log' by default (GitHub issue [#2](https://github.com/TS3Tools/TS3Monitor/issues/2))
	! If you want to disable this logging, you can add this variable to your 'configs/config.all' file: WRITE_TS3MONITOR_LOG=false
	* Fixed broken README layout

### Version 1.0.0 (2016-12-12)

	+ Initial version of this script
