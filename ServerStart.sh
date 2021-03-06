#!/bin/bash

#### Minecraft-Forge Server install/launcher script
#### Linux Version
####
#### Created by: Dijkstra
#### Mascot: Ordinator
####
#### Originally created for use in "All The Mods" modpacks
#### NO OFFICIAL AFFILIATION WITH MOJANG OR FORGE
####
#### This script will fetch the appropriate forge installer
#### and run it to install forge AND fetch Minecraft (from Mojang)
#### If Forge and Minecraft are already installed it will skip
#### download/install and launch server directly (with
#### auto-restart-after-crash logic as well)
####
#### Make sure this is running as BASH
#### You might need to chmod +x before executing
####
#### IF THERE ARE ANY ISSUES
#### Please make a report on the AllTheMods github:
#### https://github.com/whatthedrunk/allthemods/issues
#### with the contents of [serverstart.log] and [installer.log]
####
#### or come find us on Discord: https://discord.gg/FdFDVWb
####

#For Server Owners

	# RAM to allocate to server
	export MAX_RAM="5G"

	# Filename for forge jar (needed by some hosts)
	export FORGE_JAR="forge.jar"

	# Server's JVM start args
	export JAVA_ARGS="-XX:+ExplicitGCInvokesConcurrent -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+UseConcMarkSweepGC -XX:MaxGCPauseMillis=250 -XX:UseSSE=3"

	# Max server crashes (1hr apart or less) to stop auto-restart (10 default)
	export CRASH_COUNT=10

	# Allow script to run in TMP or directories with no R/W access (0 default)
	export RUN_FROM_BAD_FOLDER=0

	# Skip internet connectivity [ping] check (default 0)
	export IGNORE_OFFLINE=0

# For Modpack Developers
# (Do not modify unless you know what you're doing)

	export MCVER="1.10.2"
	export FORGEVER="12.18.3.2221"
	export FORGEURL="DISABLE"
#
#
#
#
#
#
#
# Internal scripty stuff from here on out
# No lines intended to be edited past here
#
#
#
#
#

# routine to handle Forge/server install
install_server(){
	echo "Starting install of Forge/Minecraft server binaries"
	echo "DEBUG: Starting install of Forge/Minecraft server binaries" >>serverstart.log 2>&1
	if [ -f installer.jar ]; then
		echo "DEBUG: installer.jar found in current directory" >>serverstart.log 2>&1
		export answer="n"
		read -t 8 -p "Installer found. Use it (y) or download again (n)?  " answer
		if [ $answer = "y" ] || [ $answer = "Y" ] || [ $answer = "yes" ] || [ $answer = "YES" ]; then
			echo "INFO: Skipping download. Using existing installer.jar" >>serverstart.log 2>&1
			echo "Skipping download. Using existing installer.jar"
		fi
	else
		if [ "${FORGEURL}" = "DISABLE" ]; then
			export URL="http://files.minecraftforge.net/maven/net/minecraftforge/forge/${MCVER}-${FORGEVER}/forge-${MCVER}-${FORGEVER}-installer.jar"
		else
			export URL="${FORGEURL}"
		fi

		which wget >> /dev/null
		if [ $? -eq 0 ]; then
			echo "DEBUG: (wget) Downloading ${URL}" >>serverstart.log 2>&1
			wget -O installer.jar "${URL}" >>serverstart.log 2>&1
		else
			which curl >> /dev/null
			if [ $? -eq 0 ]; then
				echo "DEBUG: (curl) Downloading ${URL}" >>serverstart.log 2>&1
				curl -o installer.jar "${URL}" >>serverstart.log 2>&1
			else
				echo "Neither wget or curl were found on your system. Please install one and try again"
				echo "ERROR: Neither wget or curl were found" >>serverstart.log 2>&1
			fi
		fi
	fi

	if [ ! -f installer.jar ]; then
		echo "Forge installer did not download"
		echo "ERROR: Forge installer did not download" >>serverstart.log 2>&1
		exit 0
	else
		echo "Moving unneeded files/folders to ./DELETEME"
		echo "INFO: Moving unneeded files/folders to ./DELETEME" >>serverstart.log 2>&1
		rm -rf ./DELETEME >>serverstart.log 2>&1
		mv -f ./asm ./DELETEME >>serverstart.log 2>&1
		mv -f ./libraries ./DELETEME >>serverstart.log 2>&1
		mv -f ./llibrary ./DELETEME >>serverstart.log 2>&1
		mv -f ./minecraft_server*.jar ./DELETEME >>serverstart.log 2>&1
		mv -f ./forge*.jar ./DELETEME >>serverstart.log 2>&1
		mv -f ./OpenComputersMod*lua* ./DELETEME >>serverstart.log 2>&1
		echo "Installing Forge Server, please wait..."
		echo "INFO: Installing Forge Server" >>serverstart.log 2>&1
		java -jar installer.jar --installServer >>serverstart.log 2>&1
		echo "Deleting Forge installer (no longer needed)"
		echo "INFO: Deleting installer.jar" >>serverstart.log 2>&1
		rm -rf installer.jar  >>serverstart.log 2>&1
		echo "Renaming forge JAR to ${FORGE_JAR}"
		echo "DEBUG: Renaming forge-${MCVER}-${FORGEVER}-universal.jar to ${FORGE_JAR}" >>serverstart.log 2>&1
		mv "forge-${MCVER}-${FORGEVER}-universal.jar" ${FORGE_JAR} >>serverstart.log 2>&1
	fi
}

# routine to [re]start Forgemodded minecraft server
start_server() {
	echo ""
	echo ""
	echo "Starting server"
	echo "INFO: Starting Server at " $(date -u +%Y-%m-%d_%H:%M:%S) >>serverstart.log 2>&1
	java -Xmx${MAX_RAM} ${JAVA_ARGS} -jar ${FORGE_JAR} nogui
}

# routine for basic directory checks
check_dir(){
	echo "DEBUG: Current directory is " $(pwd) >>serverstart.log 2>&1
	if [ "$(pwd)" = "/tmp" ] || [ "$(pwd)" = "/var/tmp" ]; then
		echo "Current directory appears to be TMP"
		echo "WARN: Current DIR is TEMP"  >>serverstart.log 2>&1
		if [ ${RUN_FROM_BAD_FOLDER} -eq 0 ]; then
			echo "ERROR: Stopping due to bad folder (TMP)" >>serverstart.log 2>&1
			echo "RUN_FROM_BAD_FOLDER setting is off, exiting script"
			exit 0
		else
			echo "WARN: Bad folder (TMP) but continuing anyway" >>serverstart.log 2>&1
			echo "Bypassing cd=temp halt per script settings"
		fi
	fi

	if [ ! -r . ] || [ ! -w . ]; then
	echo "WARN: Not full R/W access on current directory"
	echo "You do not have full R/W access to current directory"
		if [ ${RUN_FROM_BAD_FOLDER} -eq 0 ]; then
		echo "ERROR: Stopping due to bad folder (R/W access)" >>serverstart.log 2>&1
		echo "RUN_FROM_BAD_FOLDER setting is off, exiting script"
		exit 0
		else
		echo "WARN: Bad folder (R/W) cut continuing anyway" >>serverstart.log 2>&1
		echo "Bypassing no R/W halt (per script settings)"
		fi
	fi
}

# routine for ping inet connectivity
check_connection(){
	if [ ${IGNORE_OFFLINE} -eq 1 ]; then
		echo "WARN: Internet connectivity checking is disabled" >>serverstart.log 2>&1
		echo "Skipping internet connectivity check"
	else
		if ping -c 1 8.8.8.8 >> /dev/null 2>&1; then
			echo "INFO: Ping to Google DNS successfull" >>serverstart.log 2>&1
			echo "Ping to Google DNS successfull"
		else
			echo "ERROR: Ping to Google DNS failed. No internet access?" >>serverstart.log 2>&1
			echo "Ping to Google DNS failed. No internet access?"
		fi

		if ping -c 1 4.2.2.1 >> /dev/null 2>&1; then
			echo "INFO: Ping to L4 successfull" >>serverstart.log 2>&1
			echo "Ping to L4 successfull"
		else
			echo "ERROR: Ping to L4 failed. No internet access?"  >>serverstart.log 2>&1
			echo "Ping to L4 failed. No internet access?"
			exit 0
		fi
	fi
}

# routine to make sure necessary binaries are found
check_binaries(){
	if [ ! -f ${FORGE_JAR} ] ; then
		echo "WARN: ${FORGE_JAR} not found"  >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
	if [ ! -f ./minecraft_server.${MCVER}.jar ] ; then
		echo "WARN: minecraft_server.${MCVER}.jar not found" >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
	if [ ! -d ./libraries ] ; then
		echo "WARN: library directory not found" >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
}

# Script/batch starts here...

# init log file and dump basic info
echo "INFO: Starting script at" $(date -u +%Y-%m-%d_%H:%M:%S) >serverstart.log 2>&1
echo "DEBUG: Dumping starting variables: " >>serverstart.log 2>&1
echo "DEBUG: MAX_RAM=${MAX_RAM}" >>serverstart.log 2>&1
echo "DEBUG: FORGE_JAR=$FORGE_JAR" >>serverstart.log 2>&1
echo "DEBUG: JAVA_ARGS=$JAVA_ARGS" >>serverstart.log 2>&1
echo "DEBUG: CRASH_COUNT=$CRASH_COUNT" >>serverstart.log 2>&1
echo "DEBUG: RUN_FROM_BAD_FOLDER=$RUN_FROM_BAD_FOLDER" >>serverstart.log 2>&1
echo "DEBUG: IGNORE_OFFLINE=$IGNORE_OFFLINE" >>serverstart.log 2>&1
echo "DEBUG: MCVER=$MCVER" >>serverstart.log 2>&1
echo "DEBUG: FORGEVER=$FORGEVER" >>serverstart.log 2>&1
echo "DEBUG: FORGEURL=$FORGEURL" >>serverstart.log 2>&1
echo "DEBUG: Basic System Info: " $(uname -a) >>serverstart.log 2>&1
echo "DEBUG: Total RAM estimate: " $(getconf -a | grep PAGES | awk 'BEGIN {total = 1} {if (NR == 1 || NR == 3) total *=$NF} END {print total / 1024 / 1024" MB"}') >>serverstart.log 2>&1
echo "DEBUG: Java Version info: " $(java -version) >>serverstart.log 2>&1
echo "DEBUG: Dumping current directory listing " >>serverstart.log 2>&1
ls -s1h >>serverstart.log 2>&1

export answer="n"
echo ""
read -t 6 -p "About to start server. Force re-install (y/n)?  " answer
if [ $answer = "y" ] || [ $answer = "Y" ] || [ $answer = "yes" ] || [ $answer = "YES" ]; then
	echo "INFO: User chose to manually re-install server files"  >>serverstart.log 2>&1
	echo "User chose to manually re-install server files"
	install_server
fi

check_dir
check_connection
check_binaries

# loop to restart server and check crash frequency
a=0
last_crash=$((SECONDS))
while true ; do
	start_server
	b=$?
	if [ "$b" -eq "0" ]; then
		a=0
	else
		now=$((SECONDS))
		diff=$(($now-$last_crash))
		if [ "$diff" -gt "3600" ]; then
			a=1
			else
			a=$((a+1))
		fi
		last_crash=$((SECONDS))
	fi
	if [ "$a" -eq ${CRASH_COUNT} ]; then
		echo "The server has crashed to many times"
		echo "ERROR: Server has failed too start too many times in a row." >>serverstart.log 2>&1
		exit 0
	fi

	export answer="y"
	echo "Server will restart in ~10 seconds. No input needed..."
	read -t 12 -p "Restart now (y) or exit to shell (n)?  " answer
	if [ $answer = "n" ] || [ $answer = "N" ] || [ $answer = "no" ] || [ $answer = "NO" ]; then
		echo "INFO: User cancelled restart; exiting to shell" >>serverstart.log 2>&1
		exit 0
	fi

	#re-validate stuff each server restart
	check_dir
	check_connection
	check_binaries
	echo "INFO: Server-auto-restart commencing"  >>serverstart.log 2>&1
	echo "Rebooting now!"
done
