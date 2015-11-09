#!/bin/sh

##First try getting the logged in user name
currentUser=$( ls -l /dev/console | awk '{print $3}' )

if [[ "$currentUser" == "root" ]]; then ## at the login screen try getting the last user to log in. 
{
	lastUser=$( last | awk '/console/{print $1}' ) 
	if [[ "$lastUser" == "wmtp" ]] || [[ "$lastUser" == "" ]] || [[ "$lastUser" == "adobeinstall" ]]; then 
	{
		echo "<result>N/A</result>"
		exit 0
	}
	else
	{ 
		userName="$lastUser" 
	}
	fi
}
else
{
	userName="$currentUser"
}
fi


ADName=$( dscl /Active\ Directory/FOSSIL/fossil.com -read /Users/${userName} RecordName | awk -F': ' '{print $NF}'  )
if [[ $ADName 
echo "<result>$ADName</result>"
exit 0


# Run Recon and insert AD values in Location fields.
# /usr/sbin/jamf recon -endUsername "$LOGIN" -realname "$REALNAME" -email "$EMAIL" -position "$OFFICE" -room "$COMMENT"
