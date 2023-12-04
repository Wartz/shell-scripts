#!/bin/bash

# Uninstall Microsoft Defender

# unload the launchd plist for the current user
currentUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

# Temp plist files used for import and export from authorization database.

management_db_original_setting="$(mktemp).plist"
management_db_edited_setting="$(mktemp).plist"
management_db_check_setting="$(mktemp).plist"

# Expected settings from management database for com.apple.system-extensions.admin

original_setting="authenticate-admin-nonshared"
updated_setting="allow"

ManagementDatabaseUpdatePreparation() {
# Create temp plist files

touch "$management_db_original_setting"
touch "$management_db_edited_setting"
touch "$management_db_check_setting"

# Create backup of the original com.apple.system-extensions.admin settings from the management database

/usr/bin/security authorizationdb read com.apple.system-extensions.admin > "$management_db_original_setting"

# Create copy of the original com.apple.system-extensions.admin settings from the management database for editing.

/usr/bin/security authorizationdb read com.apple.system-extensions.admin > "$management_db_edited_setting"
}

UpdateManagementDatabase() {

if [[ -r "$management_db_edited_setting" ]] && [[ $(/usr/libexec/PlistBuddy -c "Print rule:0" "$management_db_edited_setting") = "$original_setting" ]]; then
   /usr/libexec/PlistBuddy -c "Set rule:0 $updated_setting" "$management_db_edited_setting"
   if [[ $(/usr/libexec/PlistBuddy -c "Print rule:0" "$management_db_edited_setting" ) = "$updated_setting" ]]; then
      echo "Edited $management_db_edited_setting is set to allow system extensions to be uninstalled without password prompt."
      echo "Now importing setting into authorization database."
      /usr/bin/security authorizationdb write com.apple.system-extensions.admin < "$management_db_edited_setting"
      if [[ $? -eq 0 ]]; then
         echo "Updated setting successfully imported."
         UpdatedAuthorizationSettingInstalled=1
      fi
    else
      echo "Failed to update $management_db_edited_setting file with the correct setting to allow system extension uninstallation without prompting for admin credentials."
    fi
fi
}

RestoreManagementDatabase() {

/usr/bin/security authorizationdb read com.apple.system-extensions.admin > "$management_db_check_setting"
if [[ ! $(/usr/libexec/PlistBuddy -c "Print rule:0" "$management_db_check_setting") = "$original_setting" ]]; then
   if [[ -r "$management_db_original_setting" ]] && [[ $(/usr/libexec/PlistBuddy -c "Print rule:0" "$management_db_original_setting") = "$original_setting" ]]; then
      echo "Restoring original settings to allow system extension uninstallation only after prompting for admin credentials."
      echo "Now importing setting into authorization database."
      /usr/bin/security authorizationdb write com.apple.system-extensions.admin < "$management_db_original_setting"
            if [[ $? -eq 0 ]]; then
         echo "Original setting successfully imported."
         OriginalAuthorizationSettingInstalled=1
      fi

    else
      echo "Failed to update the authorization database with the correct setting to allow system extension uninstallation only after prompting for admin credentials."
    fi
fi
}

if [[ -n "$currentUser" && "$currentUser" != "root" ]]; then
	/bin/launchctl bootout gui/$(/usr/bin/id -u "$currentUser") /Library/LaunchAgents/com.microsoft.wdav.tray.plist
fi

# Unload the launchd plist for the daemon

/bin/launchctl bootout system /Library/LaunchDaemons/com.microsoft.fresno.plist
/bin/launchctl bootout system /Library/LaunchDaemons/com.microsoft.fresno.uninstall.plist

# unload the kernel extension

/sbin/kextunload -v 6 -b com.microsoft.wdavkext

# Check for loaded system extensions.

wdavExtensions=$(/usr/bin/systemextensionsctl list | /usr/bin/grep -Eo "com.microsoft.wdav.[^[:space:]]+" | /usr/bin/uniq)

if [[ -n "$wdavExtensions" ]]; then

		# Prepare to update authorization database to allow system extensions to be uninstalled without password prompt.
		
		ManagementDatabaseUpdatePreparation
		
		# Update authorization database with new settings.
		
		UpdateManagementDatabase
		
		# Uninstall the system extensions
		#
		# Note: If the updated settings to allow system extensions to be uninstalled without password prompt were not
		# added successfully, this will prompt the user to enter their admin credentials, so a message will be displayed
		# to let the user know.

		if [[ -z UpdatedAuthorizationSettingInstalled ]]; then 
		
		/usr/bin/osascript -e 'display dialog "As part of the uninstall process for Microsoft" & "\nDefender, please enter your admin password when prompted." & "\n" & "\nYou may be prompted up to three times."buttons {"Understood"} default button 1 with icon Caution'

		fi

		# The system extensions will now be uninstalled. If needed, a message will be displayed to warn the user
		# to enter their admin credentials.
		#
		# After the message is displayed, the user will be prompted for the password to authorize removal of Defender's system extensions.
 
		for anExtension in ${wdavExtensions}; do
			"/Applications/Microsoft Defender.app/Contents/MacOS/wdavdaemon" uninstall-system-extension "$anExtension"
		done
		
		# Once the system extensions are uninstalled, the relevant settings for the authorization database will be restored from backup to their prior state.
		
		if [[ -n UpdatedAuthorizationSettingInstalled ]]; then 
		
		RestoreManagementDatabase
		
		  if [[ -n "$OriginalAuthorizationSettingInstalled" ]]; then
		   echo "com.apple.system-extensions.admin settings in the authorization database successfully restored to $original_setting."
		   rm -rf "$management_db_original_setting"
		   rm -rf "$management_db_edited_setting"
		   rm -rf "$management_db_check_setting"
		  fi
		
		fi
fi

# kill Microsoft Defender
/usr/bin/killall -SIGKILL "Microsoft Defender" "Microsoft Defender"

# remove the global stuff
/bin/rm -rf "/Applications/Microsoft Defender.app" \
			/Library/Logs/Microsoft/mdatp \
			"/Library/Application Support/Microsoft/Defender" \
			"/Library/Application Support/Microsoft Defender ATP" \
 			/Library/Extensions/com.microsoft.wdavkext \
 			/Library/Extensions/wdavkext.kext \
			/Library/LaunchDaemons/com.microsoft.fresno.* \
			/Library/LaunchAgents/com.microsoft.wdav.tray.plist

# remove stuff in users folders
localUsers=$(/usr/bin/dscl . -list /Users | /usr/bin/grep -v "^_")

for userName in ${localUsers}; do

	# get path to user's home directory
	userHome=$(/usr/bin/dscl . -read "/Users/$userName" NFSHomeDirectory 2>/dev/null | /usr/bin/sed 's/^[^\/]*//g')
	
	if [[ -d "$userHome" && "$userHome" != "/var/empty" ]]; then
			
		/bin/rm -rf "$userHome/Library/Saved Application State/com.microsoft.wdav.savedState" \
					"$userHome/Library/Preferences/com.microsoft.wdav.plist" \
					"$userHome/Library/Preferences/com.microsoft.wdavtray.plist" \
					"$userHome/Library/Caches/Microsoft/uls/com.microsoft.wdav"
	fi
done

# remove the mdatp user and group
/usr/bin/dscl /Local/Default -delete /Users/_mdatp
/usr/bin/dscl /Local/Default -delete /Groups/_mdatp

# forget the packages
allPKGS=$(/usr/sbin/pkgutil --pkgs="com.microsoft.wdav")
for aPKG in ${allPKGS}; do
	/usr/sbin/pkgutil --forget "$aPKG"
done

exit 0
