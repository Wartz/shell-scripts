#!/bin/bash

# IBM Notifier binary paths
NA_PATH="/Applications/IBM Notifier.app/Contents/MacOS/IBM Notifier"

# Variables for the popup notification for ease of customization
WINDOWTYPE="onboarding"
PAYLOAD=$(cat <<-END
{
   "pages":[
      {
         "title":"First page's title",
         "subtitle":"First page's subtitle",
         "body":"First page's body",
         "mediaType":"image",
         "mediaPayload":"http://image.address"
      },
      {
         "title":"Second page's title",
         "subtitle":"Second page's subtitle",
         "body":"Second page's body",
         "mediaType":"video",
         "mediaPayload":"http://video.address"
      },
      {
         "title":"Third page's title",
         "subtitle":"Third page's subtitle",
         "body":"Third page's body",
         "mediaType":"image",
         "mediaPayload":"base64encodedimage",
         "infoSection":{
            "fields":[
               {
                  "label":"First label only"
               },
               {
                  "label":"Second label only"
               },
               {
                  "label":"Third label only"
               }
            ]
         }
      }
   ]
}
END
)

### FUNCTIONS ###

prompt_user() {
    button=$("${NA_PATH}" \
        -type "${WINDOWTYPE}" \
        -payload "${PAYLOAD}")

    echo "$?"
}

### END FUNCTIONS ###

RESPONSE=$(prompt_user)
echo "$RESPONSE"