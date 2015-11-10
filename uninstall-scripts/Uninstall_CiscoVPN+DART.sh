#!/bin/sh

## Function Declarations

UninstallCiscoAnyConnect()
{
	
	LEGACY_INSTPREFIX="/opt/cisco/vpn"
	LEGACY_BINDIR="${LEGACY_INSTPREFIX}/bin"

	INSTPREFIX="/opt/cisco/anyconnect"
	BINDIR="${INSTPREFIX}/bin"
	PLUGINDIR="${BINDIR}/plugins"
	LIBDIR="${INSTPREFIX}/lib"
	PROFDIR="${INSTPREFIX}/profile"
	SCRIPTDIR="${INSTPREFIX}/script"
	HELPDIR="${INSTPREFIX}/help"
	KEXTDIR="${BINDIR}"
	APPDIR="/Applications/Cisco"
	GUIAPP="Cisco AnyConnect Secure Mobility Client.app"
	UNINSTALLER="Uninstall AnyConnect.app"
	INITDIR="/System/Library/StartupItems"
	INIT="vpnagentd"
	LAUNCHD_DIR="/Library/LaunchDaemons"
	LAUNCHD_FILE="com.cisco.anyconnect.vpnagentd.plist"
	LAUNCHD_AGENT_DIR="/Library/LaunchAgents"
	LAUNCHD_AGENT_FILE="com.cisco.anyconnect.gui.plist"
	ACMANIFESTDAT="${INSTPREFIX}/VPNManifest.dat"
	VPNMANIFEST="ACManifestVPN.xml"
	UNINSTALLLOG="/tmp/vpn-uninstall.log"

	ANYCONNECT_VPN_PACKAGE_ID=com.cisco.pkg.anyconnect.vpn

	# Array of files to remove
	FILELIST=("${BINDIR}/vpnagentd" \
			  "${BINDIR}/vpn_uninstall.sh" \
			  "${BINDIR}/anyconnect_uninstall.sh" \
			  "${BINDIR}/vpnui" \
			  "${BINDIR}/vpn" \
			  "${BINDIR}/vpndownloader.app" \
			  "${LEGACY_BINDIR}/vpndownloader.app" \
			  "${LEGACY_BINDIR}/vpndownloader.sh" \
			  "${LEGACY_BINDIR}/manifesttool" \
			  "${LEGACY_BINDIR}/vpn_uninstall.sh" \
			  "${BINDIR}/libnspr4.dylib" \
			  "${BINDIR}/libnss3.dylib" \
			  "${BINDIR}/libnssutil3.dylib" \
			  "${BINDIR}/libplc4.dylib" \
			  "${BINDIR}/libplds4.dylib" \
			  "${BINDIR}/libsoftokn3.dylib" \
			  "${BINDIR}/SetUIDTool" \
			  "${INSTPREFIX}/AnyConnectLocalPolicy.xsd" \
			  "${INSTPREFIX}/gui_keepalive" \
			  "${INSTPREFIX}/OpenSource.html" \
			  "${LEGACY_INSTPREFIX}/update.txt" \
			  "${INSTPREFIX}/update.txt" \
			  "${INSTPREFIX}/${VPNMANIFEST}" \
			  "${LIBDIR}/libacciscossl.dylib" \
			  "${LIBDIR}/libacciscocrypto.dylib" \
			  "${LIBDIR}/libaccurl.4.dylib" \
			  "${LIBDIR}/libvpnagentutilities.dylib" \
			  "${LIBDIR}/libvpncommon.dylib" \
			  "${LIBDIR}/libvpncommoncrypt.dylib" \
			  "${LIBDIR}/libvpnapi.dylib" \
			  "${LIBDIR}/libac_sock_fltr_api.dylib" \
			  "${PLUGINDIR}/libvpnipsec.dylib" \
			  "${PLUGINDIR}/libacfeedback.dylib" \
			  "${PLUGINDIR}/libvpnapishim.dylib" \
			  "${PROFDIR}/AnyConnectProfile.xsd" \
			  "${LAUNCHD_DIR}/${LAUNCHD_FILE}" \
			  "${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_FILE}" \
			  "${INITDIR}/${INIT}" \
			  "${APPDIR}/${GUIAPP}" \
			  "${APPDIR}/${UNINSTALLER}" \
			  "${KEXTDIR}/acsock.kext")

	echo "Uninstalling Cisco AnyConnect Secure Mobility Client..."
	echo "Uninstalling Cisco AnyConnect Secure Mobility Client..." > "${UNINSTALLLOG}"
	echo `whoami` "invoked $0 from " `pwd` " at " `date` >> "${UNINSTALLLOG}"

	# Check for root privileges
	if [ `whoami` != "root" ]; then
	  echo "Sorry, you need super user privileges to run this sacript."
	  echo "Sorry, you need super user privileges to run this script." >> "${UNINSTALLLOG}"
	  exit 1
	fi

	# update the VPNManifest.dat; if no entries remain in the .dat file then
	# this tool will delete the file - DO NOT blindly delete VPNManifest.dat by
	# adding it to the FILELIST above - allow this tool to delete the file if needed
	if [ -f "${BINDIR}/manifesttool" ]; then
	  echo "${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${VPNMANIFEST}" >> "${UNINSTALLLOG}"
	  ${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${VPNMANIFEST}
	fi

	# check the existence of the manifest file - if it does not exist, remove the manifesttool
	if [ ! -f ${ACMANIFESTDAT} ] && [ -f ${BINDIR}/manifesttool ]; then
	  echo "Removing ${BINDIR}/manifesttool" >> "${UNINSTALLLOG}"
	  rm -f ${BINDIR}/manifesttool
	fi

	# Unload the GUI launch agent if it exists
	if [ -e ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_FILE} ] ; then
		MYUID=`echo "show State:/Users/ConsoleUser" | scutil | awk '/UID/ { print $3 }'`
		echo "Stopping gui launch agent..." >> "${UNINSTALLLOG}"
		echo "sudo -u #${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_FILE}" >> "${UNINSTALLLOG}"
		logger "Stopping the GUI launch agent..."
		sudo -u \#${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_FILE} >> "${UNINSTALLLOG}" 2>&1
	fi

	# ensure that the gui and cli are not running
	OURPROCS=`ps -A -o pid,command | egrep '(Cisco AnyConnect Secure Mobility Client)' | egrep -v 'grep|vpn_uninstall|anyconnect_uninstall' | cut -c 1-5`
	if [ -n "${OURPROCS}" ] ; then
		for DOOMED in ${OURPROCS}; do
			echo Killing `ps -A -o pid,command -p ${DOOMED} | grep ${DOOMED} | egrep -v 'ps|grep'` >> "${UNINSTALLLOG}"
			kill -INT ${DOOMED} >> "${UNINSTALLLOG}" 2>&1
		done
	fi

	# Wait one second to allow the GUI and CLI to properly close. This hack
	# prevents some IPC issues related to trying to close the GUI and agent
	# almost simultaneously.
	sleep 1

	# Remove the plugins directory
	if [ -e ${PLUGINDIR} ] ; then
	  echo "rm -rf "${PLUGINDIR}"" >> "${UNINSTALLLOG}"
	  rm -rf "${PLUGINDIR}" >> "${UNINSTALLLOG}" 2>&1
	fi

	# Remove the vpnagent init scripts.  Attempt to disable agent first.
	# If the old StartupItems file exists, try to use that method to stop the agent
	if [ -e ${INITDIR}/${INIT}/${INIT} ] ; then
		echo "Stopping agent..." >> "${UNINSTALLLOG}"
		echo "${INITDIR}/${INIT}/${INIT} stop" >> "${UNINSTALLLOG}"
		logger "Stopping the VPN agent..."
		${INITDIR}/${INIT}/${INIT} stop >> "${UNINSTALLLOG}" 2>&1
	fi

	# If the new launchd file exists, try to use that method to stop the agent
	# IMPORTANT: The use of sudo here is necessary to ensure that we communicate
	#  with the global instance of launchd. Without the sudo, the uninstall will fail
	#  when initiated from the GUI. This appears to be due to launchctl working
	#  based on the UID, rather than the EUID. The GUI program will only set the
	#  EUID to root, while the UID remains as the user.
	if [ -e ${LAUNCHD_DIR}/${LAUNCHD_FILE} ] ; then
		echo "Stopping agent..." >> "${UNINSTALLLOG}"
		echo "sudo launchctl unload ${LAUNCHD_DIR}/${LAUNCHD_FILE}" >> "${UNINSTALLLOG}"
		logger "Stopping the VPN agent..."
		sudo launchctl unload ${LAUNCHD_DIR}/${LAUNCHD_FILE} >> "${UNINSTALLLOG}" 2>&1
	fi

	case "${1}" in
		noblock)
		echo "uninstalling immediately..." >> "${UNINSTALLLOG}"
		;;

		*)

		max_seconds_to_wait=10
		ntests=$max_seconds_to_wait
		# Wait up to max_seconds_to_wait seconds for the agent to finish.
		while [ -n "`ps -A -o command | grep \"/opt/cisco/anyconnect/bin/${INIT}\" | egrep -v 'grep'`" ]
		do
			ntests=`expr  $ntests - 1`
			if [ $ntests -eq 0 ]; then
				logger "Timeout waiting for agent to stop."
				echo "Timeout waiting for agent to stop." >> "${UNINSTALLLOG}"
				break
			fi
			sleep 1
		done
	  ;;
	esac

	# ensure that the agent, gui and cli are not running - show no mercy
	OURPROCS=`ps -A -o pid,command | egrep '(/opt/cisco/anyconnect/bin)|(Cisco AnyConnect Secure Mobility Client)' | egrep -v 'grep|vpn_uninstall|anyconnect_uninstall' | cut -c 1-5`
	if [ -n "${OURPROCS}" ] ; then
		for DOOMED in ${OURPROCS}; do
			echo Killing `ps -A -o pid,command -p ${DOOMED} | grep ${DOOMED} | egrep -v 'ps|grep'` >> "${UNINSTALLLOG}"
			kill -KILL ${DOOMED} >> "${UNINSTALLLOG}" 2>&1
		done
	fi

	# unload the acsock if it is still loaded by the system
	ACSOCKLOADED=`kextstat | grep acsock`
	if [ ! "x${ACSOCKLOADED}" = "x" ]; then
	  echo "Unloading {KEXTDIR}/acsock.kext" >> ${UNINSTALLLOG}
	  kextunload ${KEXTDIR}/acsock.kext >> ${UNINSTALLLOG} 2>&1
	  echo "${KEXTDIR}/acsock.kext unloaded" >> ${UNINSTALLLOG}
	fi

	INDEX=0

	# Remove only those files that we know we installed
	INDEX=0
	while [ $INDEX -lt ${#FILELIST[@]} ] ; do
	  echo "rm -rf "${FILELIST[${INDEX}]}"" >> "${UNINSTALLLOG}"
	  rm -rf "${FILELIST[${INDEX}]}"
	  let "INDEX = $INDEX + 1"
	done

	# Remove the bin directory if it is empty
	if [ -e ${BINDIR} ] ; then
	  if [ ! -z `find "${BINDIR}" -prune -empty` ] ; then
		echo "rm -df "${BINDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${BINDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi	
	fi

	# Only remove the Application directory if it is empty
	if [ ! -z `find "${APPDIR}" -prune -empty` ] ; then
	  echo "rm -rf "${APPDIR}"" >> "${UNINSTALLLOG}"
	  rm -rf "${APPDIR}" >> "${UNINSTALLLOG}" 2>&1
	fi

	# Remove the lib directory if it is empty
	if [ -e ${LIBDIR} ] ; then
	  if [ ! -z `find "${LIBDIR}" -prune -empty` ] ; then
		echo "rm -df "${LIBDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${LIBDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# Remove the script directory if it is empty
	if [ -e ${SCRIPTDIR} ] ; then
	  if [ ! -z `find "${SCRIPTDIR}" -prune -empty` ] ; then
		echo "rm -df "${SCRIPTDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${SCRIPTDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# Remove the help directory if it is empty
	if [ -e ${HELPDIR} ] ; then
	  if [ ! -z `find "${HELPDIR}" -prune -empty` ] ; then
		echo "rm -df "${HELPDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${HELPDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# Remove the profile directory if it is empty
	if [ -e ${PROFDIR} ] ; then
	  if [ ! -z `find "${PROFDIR}" -prune -empty` ] ; then
		echo "rm -df "${PROFDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${PROFDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# Remove the legacy bin directory if it is empty
	if [ -e ${LEGACY_BINDIR} ] ; then
	  if [ ! -z `find "${LEGACY_BINDIR}" -prune -empty` ] ; then
		echo "rm -df "${LEGACY_BINDIR}"" >> "${UNINSTALLLOG}"
		rm -df "${LEGACY_BINDIR}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# Remove the legacy directory if it is empty
	if [ -e ${LEGACY_INSTPREFIX} ] ; then
	  if [ ! -z `find "${LEGACY_INSTPREFIX}" -prune -empty` ] ; then
		echo "rm -df "${LEGACY_INSTPREFIX}"" >> "${UNINSTALLLOG}"
		rm -df "${LEGACY_INSTPREFIX}" >> "${UNINSTALLLOG}" 2>&1
	  fi
	fi

	# remove installer receipt
	pkgutil --forget ${ANYCONNECT_VPN_PACKAGE_ID} >> "${UNINSTALLLOG}" 2>&1

	echo "Successfully removed Cisco AnyConnect Secure Mobility Client from the system." >> "${UNINSTALLLOG}"
	echo "Successfully removed Cisco AnyConnect Secure Mobility Client from the system."


}		
## End UninstallCiscoAnyConnect

UninstallCiscoDART()
{
	INSTPREFIX="/opt/cisco/anyconnect"
	BINDIR="${INSTPREFIX}/bin"
	LEGACY_BINDIR="/opt/cisco/vpn/bin"
	DARTDIR="${INSTPREFIX}/dart"
	CONFIGXMLDIR="${DARTDIR}/xml/config"
	REQUESTXMLDIR="${DARTDIR}/xml/request"
	APPDIR="/Applications/Cisco"
	DARTAPP="Cisco AnyConnect DART.app"
	ACMANIFESTDAT="${INSTPREFIX}/VPNManifest.dat"
	DARTMANIFEST="ACManifestDART.xml"
	LOG="/tmp/dart-uninstall.log"

	ANYCONNECT_DART_PACKAGE_ID=com.cisco.pkg.anyconnect.dart

	# List of files to remove
	FILELIST=("${APPDIR}/${DARTAPP}" \
			  "${INSTPREFIX}/${DARTMANIFEST}" \
			  "${BINDIR}/dart_uninstall.sh" \
			  "${LEGACY_BINDIR}/dart_uninstall.sh" \
			  "${DARTDIR}") 
		  
	echo "Uninstalling Cisco AnyConnect Diagnostics and Reporting Tool..."
	echo "Uninstalling Cisco AnyConnect Diagnostics and Reporting Tool..." > "${LOG}"
	echo `whoami` "invoked $0 from " `pwd` " at " `date` >> "${LOG}"

	# Check for root privileges
	if [ `id | sed -e 's/(.*//'` != "uid=0" ]; then
	  echo "Sorry, you need super user privileges to run this script."
	  echo "Sorry, you need super user privileges to run this script." >> "${LOG}"
	  exit 1
	fi

	# update the VPNManifest.dat; if no entries remain in the .dat file then
	# this tool will delete the file - DO NOT blindly delete VPNManifest.dat by
	# adding it to the FILELIST above - allow this tool to delete the file if needed
	if [ -f "${BINDIR}/manifesttool" ]; then
	  echo "${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${DARTMANIFEST}" >> "${LOG}"
	  ${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${DARTMANIFEST}
	fi

	# check the existence of the manifest file - if it does not exist, remove the manifesttool
	if [ ! -f ${ACMANIFESTDAT} ] && [ -f ${BINDIR}/manifesttool ]; then
	  echo "Removing ${BINDIR}/manifesttool" >> "${LOG}"
	  rm -f ${BINDIR}/manifesttool
	fi

	# ensure that DART is not running
	OURPROCS=`ps -A -o pid,command | egrep '(Cisco AnyConnect DART)' | egrep -v 'grep|dart_uninstall' | cut -c 1-5`
	if [ -n "${OURPROCS}" ] ; then
		for DOOMED in ${OURPROCS}; do
			echo Killing `ps -A -o pid,command -p ${DOOMED} | grep ${DOOMED} | egrep -v 'ps|grep'` >> "${LOG}"
			kill -INT ${DOOMED} >> "${LOG}" 2>&1
		done
	fi

	# Remove only those files that we know we installed
	INDEX=0
	while [ $INDEX -lt ${#FILELIST[@]} ] ; do
		echo "rm -rf "${FILELIST[${INDEX}]}"" >> "${LOG}"
		rm -rf "${FILELIST[${INDEX}]}"
		let  "INDEX = $INDEX + 1"
	done

	# Remove the bin directory if it is empty
	if [ -e ${BINDIR} ] ; then
	  if [ ! -z `find "${BINDIR}" -prune -empty` ] ; then
		echo "rm -df "${BINDIR}"" >> ${LOG}
		rm -df "${BINDIR}" >> ${LOG} 2>&1
	  fi	
	fi

	# Remove the legacy bin directory if it is empty
	if [ -e ${LEGACY_BINDIR} ] ; then
	  if [ ! -z `find "${LEGACY_BINDIR}" -prune -empty` ] ; then
		echo "rm -df "${LEGACY_BINDIR}"" >> ${LOG}
		rm -df "${LEGACY_BINDIR}" >> ${LOG} 2>&1
	  fi
	fi

	# Remove the Cisco directory if it is empty
	if [ ! -z `find "${APPDIR}" -prune -empty` ] ; then 
		echo "rm -rf "${APPDIR}"" >> "${LOG}"
		rm -rf "${APPDIR}"
	fi

	# remove installer receipt
	pkgutil --forget ${ANYCONNECT_DART_PACKAGE_ID} >> "${LOG}" 2>&1

	echo "Successfully removed Cisco AnyConnect Diagnostics and Reporting Tool from the system." >> "${LOG}"
	echo "Successfully removed Cisco AnyConnect Diagnostics and Reporting Tool from the system."
}
## END UninstallCiscoDART

UninstallCiscoPostureModule()
{
	POSTUREDIR="/opt/cisco/hostscan"
	INITDIR="/System/Library/StartupItems/ciscod"
	INIT="ciscod"
	LOG="/tmp/posture-uninstall.log"

	ANYCONNECT_POSTURE_PACKAGE_ID=com.cisco.pkg.anyconnect.posture

	echo "Uninstalling Cisco AnyConnect Posture Module..."
	echo "Uninstalling Cisco AnyConnect Posture Module..." > "${LOG}"
	echo `whoami` "invoked $0 from " `pwd` " at " `date` >> "${LOG}"

	# Check for root privileges
	if [ `id | sed -e 's/(.*//'` != "uid=0" ]; then
	  echo "Sorry, you need super user privileges to run this script."
	  echo "Sorry, you need super user privileges to run this script." >> "${LOG}"
	  exit 1
	fi


	# Attempt to stop the service if it is running, and remove the init script.

	if [ "x${INITDIR}" != "x" ]; then
	  echo "Stopping the security service..." >> "${LOG}"
	  echo "${INITDIR}/${INIT} stop" >> "${LOG}"
	  ${INITDIR}/${INIT} stop >> "${LOG}"
	  echo "rm -rf ${INITDIR}" >> "${LOG}"
	  rm -rf ${INITDIR} || echo "Warning: unable to remove init script"
	fi

	# Remove those pre-deploy files that we may have installed

	if [ -e ${POSTUREDIR} ]; then
	  echo "rm -rf ${POSTUREDIR}" >> "${LOG}"
	  rm -rf ${POSTUREDIR} >> "${LOG}" 2>&1
	fi

	# update manifest
	ANYCONNECT_INSTPREFIX="/opt/cisco/anyconnect"
	ANYCONNECT_BINDIR="/opt/cisco/anyconnect/bin"
	ACMANIFESTDAT="${ANYCONNECT_INSTPREFIX}/VPNManifest.dat"
	POSTUREMANIFEST="ACManifestPOS.xml"

	# update the VPNManifest.dat; if no entries remain in the .dat file then
	# this tool will delete the file - DO NOT blindly delete VPNManifest.dat by
	# adding it to the FILELIST above - allow this tool to delete the file if needed
	if [ -f "${ANYCONNECT_BINDIR}/manifesttool" ]; then
	  echo "${ANYCONNECT_BINDIR}/manifesttool -x ${ANYCONNECT_INSTPREFIX} ${ANYCONNECT_INSTPREFIX}/${POSTUREMANIFEST}" >> "${LOG}"
	  ${ANYCONNECT_BINDIR}/manifesttool -x ${ANYCONNECT_INSTPREFIX} ${ANYCONNECT_INSTPREFIX}/${POSTUREMANIFEST}
	fi

	# check the existence of the manifest file - if it does not exist, remove the manifesttool
	if [ ! -f ${ACMANIFESTDAT} ] && [ -f ${ANYCONNECT_BINDIR}/manifesttool ]; then
	  echo "Removing ${ANYCONNECT_BINDIR}/manifesttool" >> "${LOG}"
	  rm -f ${ANYCONNECT_BINDIR}/manifesttool
	fi

	rm -f ${ANYCONNECT_INSTPREFIX}/${POSTUREMANIFEST}

	# remove installer receipt
	pkgutil --forget ${ANYCONNECT_POSTURE_PACKAGE_ID} >> "${LOG}" 2>&1

	echo "Successfully removed Cisco AnyConnect Posture Module from the system." >> "${LOG}"
	echo "Successfully removed Cisco AnyConnect Posture Module from the system."
}
## END UninstallCiscoPostureModule

UninstallCiscoWebSecModule()
{
	INSTPREFIX="/opt/cisco/anyconnect"
	BINDIR="${INSTPREFIX}/bin"
	PLUGINSDIR="${BINDIR}/plugins"
	LIBDIR="${INSTPREFIX}/lib"
	PROFILESDIR="${INSTPREFIX}/websecurity"
	ACMANIFESTDAT="${INSTPREFIX}/VPNManifest.dat"
	WEBSECMANIFEST="ACManifestWebSecurity.xml"
	UNINSTALLLOG="/tmp/websecurity-uninstall.log"

	ANYCONNECT_WEBSECURITY_PACKAGE_ID=com.cisco.pkg.anyconnect.websecurity

	# Array of files to remove
	FILELIST=("${INSTPREFIX}/${WEBSECMANIFEST}" \
			  "${BINDIR}/acwebsecagent" \
			  "${BINDIR}/websecurity_uninstall.sh" \
			  "${LIBDIR}/libboost_filesystem.dylib" \
			  "${LIBDIR}/libboost_system.dylib" \
			  "${LIBDIR}/libboost_thread.dylib" \
			  "${LIBDIR}/libboost_date_time.dylib" \
			  "${INSTPREFIX}/libacwebsecapi.dylib" \
			  "${INSTPREFIX}/libacwebsecctrl.dylib")

	echo "Uninstalling Cisco AnyConnect Web Security Module..."
	echo "Uninstalling Cisco AnyConnect Web Security Module..." > ${UNINSTALLLOG}
	echo `whoami` "invoked $0 from " `pwd` " at " `date` >> ${UNINSTALLLOG}

	# Check for root privileges
	if [ `whoami` != "root" ]; then
	  echo "Sorry, you need super user privileges to run this script."
	  echo "Sorry, you need super user privileges to run this script." >> ${UNINSTALLLOG}
	  exit 1
	fi

	# update the VPNManifest.dat; if no entries remain in the .dat file then
	# this tool will delete the file - DO NOT blindly delete VPNManifest.dat by
	# adding it to the FILELIST above - allow this tool to delete the file if needed
	if [ -f "${BINDIR}/manifesttool" ]; then
	  echo "${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${WEBSECMANIFEST}" >> ${UNINSTALLLOG}
	  ${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${WEBSECMANIFEST}
	fi

	# check the existence of the manifest file - if it does not exist, remove the manifesttool
	if [ ! -f ${ACMANIFESTDAT} ] && [ -f ${BINDIR}/manifesttool ]; then
	  echo "Removing ${BINDIR}/manifesttool" >> ${UNINSTALLLOG}
	  rm -f ${BINDIR}/manifesttool
	fi

	# move the plugins to a different folder to stop the websec agent and then remove
	# these plugins once websec agent is stopped. 
	echo "Moving plugins from ${PLUGINSDIR}" >> ${UNINSTALLLOG}
	mv -f ${PLUGINSDIR}/libacwebsecapi.dylib ${INSTPREFIX} 2>&1 >/dev/null
	echo "mv -f ${PLUGINSDIR}/libacwebsecapi.dylib ${INSTPREFIX}" >> ${UNINSTALLLOG}
	mv -f ${PLUGINSDIR}/libacwebsecctrl.dylib ${INSTPREFIX} 2>&1 >/dev/null
	echo "mv -f ${PLUGINSDIR}/libacwebsecctrl.dylib ${INSTPREFIX}" >> ${UNINSTALLLOG}

	# wait for 2 seconds for the websecagent to exit
	sleep 2

	# ensure that the websec agent is not running
	WEBSECPROC=`ps -A -o pid,command | grep '(${BINDIR}/acwebsecagent)' | egrep -v 'grep|websecurity_uninstall' | cut -c 1-5`
	if [ ! "x${WEBSECPROC}" = "x" ] ; then
		echo Killing `ps -A -o pid,command -p ${WEBSECPROC} | grep ${WEBSECPROC} | egrep -v 'ps|grep'` >> ${UNINSTALLLOG}
		kill -TERM ${WEBSECPROC} >> ${UNINSTALLLOG} 2>&1
	fi

	# Remove only those files that we know we installed
	INDEX=0
	while [ $INDEX -lt ${#FILELIST[@]} ]; do
	  echo "rm -rf "${FILELIST[${INDEX}]}"" >> ${UNINSTALLLOG}
	  rm -rf "${FILELIST[${INDEX}]}"
	  let "INDEX = $INDEX + 1"
	done

	# Remove the plugins directory if it is empty
	if [ -d ${PLUGINSDIR} ]; then
	  if [ ! -z `find "${PLUGINSDIR}" -prune -empty` ] ; then
		echo "rm -df "${PLUGINSDIR}"" >> ${UNINSTALLLOG}
		rm -df "${PLUGINSDIR}" >> ${UNINSTALLLOG} 2>&1
	  fi	
	fi

	# Remove the bin directory if it is empty
	if [ -d ${BINDIR} ]; then
	  if [ ! -z `find "${BINDIR}" -prune -empty` ] ; then
		echo "rm -df "${BINDIR}"" >> ${UNINSTALLLOG}
		rm -df "${BINDIR}" >> ${UNINSTALLLOG} 2>&1
	  fi	
	fi

	# Remove the bin directory if it is empty
	if [ -d ${LIBDIR} ]; then
	  if [ ! -z `find "${LIBDIR}" -prune -empty` ] ; then
		echo "rm -df "${LIBDIR}"" >> ${UNINSTALLLOG}
		rm -df "${LIBDIR}" >> ${UNINSTALLLOG} 2>&1
	  fi
	fi

	# Remove the profiles directory
	# During an upgrade, the profiles will be moved and restored by
	# preupgrade and postupgrade scripts.

	if [ -d ${PROFILESDIR} ]; then
		echo "rm -rf "${PROFILESDIR}"" >> ${UNINSTALLLOG}
		rm -rf "${PROFILESDIR}" >> ${UNINSTALLLOG} 2>&1
	fi

	# remove installer receipt
	pkgutil --forget ${ANYCONNECT_WEBSECURITY_PACKAGE_ID} >> ${UNINSTALLLOG} 2>&1

	echo "Successfully removed Cisco AnyConnect Web Security Module from the system." >> ${UNINSTALLLOG}
	echo "Successfully removed Cisco AnyConnect Web Security Module from the system."
}
## END UninstallCiscoWebSecModule

ANYCONNECT_BINDIR="/opt/cisco/anyconnect/bin"
POSTURE_BINDIR="/opt/cisco/hostscan/bin"

VPN_UNINST=${ANYCONNECT_BINDIR}/vpn_uninstall.sh
WEBSECURITY_UNINST=${ANYCONNECT_BINDIR}/websecurity_uninstall.sh
POSTURE_UNINST=${POSTURE_BINDIR}/posture_uninstall.sh
DART_UNINST=${ANYCONNECT_BINDIR}/dart_uninstall.sh

if [ -x "${POSTURE_UNINST}" ]; then
  UninstallCiscoPostureModule
  if [ $? -ne 0 ]; then
    echo "Error uninstalling AnyConnect Posture Module."
  fi
fi

if [ -x "${WEBSECURITY_UNINST}" ]; then
  UninstallCiscoWebSecModule
  if [ $? -ne 0 ]; then
    echo "Error uninstalling AnyConnect Web Security Module."
  fi
fi

if [ -x "${VPN_UNINST}" ]; then
  UninstallCiscoAnyConnect
  if [ $? -ne 0 ]; then
    echo "Error uninstalling AnyConnect Secure Mobility Client."
  fi
fi

if [ -x "${DART_UNINST}" ]; then
  UninstallCiscoDART
  if [ $? -ne 0 ]; then
    echo "Error uninstalling AnyConnect DART."
  fi
fi

if [ -a "/usr/sbin/dockutil.py" ]; then
    echo "Removing Dock Items"
    /usr/sbin/dockutil.py --remove "Cisco AnyConnect Secure Mobility Client" --allhomes
  if [ $? -ne 0 ]; then
    echo "Error removing dock items."
  fi
fi

exit 0

