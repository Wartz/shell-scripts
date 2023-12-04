#!/bin/bash
#
# AutoPkg update-trust-info in bulk
#
# Current user
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Path to autopkgr recipe list
RECIPE_PATH="/Users/$loggedInUser/Library/Application Support/AutoPkgr/recipe_list.txt"
mapfile -t RECIPES < "$RECIPE_PATH"

# Process each recipe from list and update override
for app in "${RECIPES[@]}"; do
    #autopkg update-trust-info "$app"
    echo "autopkg update $app"
done

exit 0

