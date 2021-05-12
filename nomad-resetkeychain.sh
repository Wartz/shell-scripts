#/usr/bin/env bash
#
# Destroy any existing kerberos tickets, delete the cached password in NoMAD keychain
# item and then when the user signs in again, the password is updated and presumably,
# forces a local account password sync.
#
# nomad-resetkeychain.sh
# Joe Schlimmer
# 5-11-2021
# version: 1.0

# Get the current logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Get the kerberos ticket UPN
userPrincipalName=$(klist | awk '/Principal:/{print $2}')

# Make sure someone is logged in
if [[ -z $loggedInUser ]]; then
    echo "No user signed in"
    exit 1
else
    # Destroy any existing kerberos tickets for current user
    kdestroy -p "$userPrincipalName"

    # Delete the NoMAD application password from the Login keychain
    security delete-generic-password -l NoMAD "/Users/$loggedInUser/Library/Keychains/login.keychain-db"
fi

exit 0
