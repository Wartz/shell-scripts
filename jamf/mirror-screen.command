#!/bin/bash
# Display a notification to user on how to mirror the screen on a classroom computer
# Joe Schlimmer & Jeremy Timmins
# 2022-12-09

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
computerSerial="$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')"

# This sets the variable for jamfHelper results from which button was clicked
buttonClicked=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
    -windowType utility \
    -icon "/Library/Ithaca/IC-Logo2L.png" \
    -title "To Mirror the Classroom Display" \
    -heading "Please press Command+F1" \
    -description "Please press Command+F1 to mirror the classroom display and projector.

Contact the service desk at 274-1000 for help" \
    -button1 "Settings" \
    -button2 "Close")

if [ "$buttonClicked" == 0 ]; then
	# Buttion 1 was Clicked
        # echo "$(date)::: Opening Scheduling page" >> /var/tmp/tech_renewal.log
        # echo "Your Ithaca College Mac Serialnumber: $computerSerial" >> /var/tmp/tech_renewal.log
        open /System/Library/PreferencePanes/Displays.prefPane
elif [ "$buttonClicked" == 2 ]; then
	# Buttion 2 was Clicked
        # echo "$(date)::: I dont want to right now" >> /var/tmp/tech_renewal.log
        echo "Closing info panel"
fi
exit $?