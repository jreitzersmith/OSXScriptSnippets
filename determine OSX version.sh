#!/bin/bash

	##determine OS version
		OSVer=$( sw_vers -productVersion )
		
		## Set appropriate installer flag based on OS version.
		## Handles packages that may have an old cert
		## TODO: rewrite as a case statement for the 3 nanoseconds performance improvement
		if [[ $OSVer =~ "10.6" ]]; then
			allowFlag="-allow"
		elif [[ $OSVer =~ "10.7" ]]; then
			allowFlag="-allowUntrusted"
		elif [[ $OSVer =~ "10.8" ]]; then
			allowFlag="-allowUntrusted"
		elif [[ $OSVer =~ "10.10" ]]; then
			allowFlag="-allowUntrusted"    
		fi
		

