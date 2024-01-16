#!/bin/bash
API_KEYS=$1
IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"
AVAILABLE_KEYS=()
# Adjusting URL to include API key as a parameter
BASE_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
CONTENT_TYPE="Content-Type: application/json"
DATA='{
  "contents": [
    {
      "parts": [
        {
          "text": "how to say hello in French, one word"
        }
      ]
    }
  ]
}'

for API_KEY in "${API_KEY_ARRAY[@]}"; do
    URL="${BASE_URL}?key=${API_KEY}"
    success=false
    for attempt in {1..2}; do
        RESPONSE=$(curl -s -X POST -H "$CONTENT_TYPE" -d "$DATA" $URL)
        echo "Response: $RESPONSE"
        # Adjust error handling as per Gemini API response format
        ERROR_CODE=$(echo $RESPONSE | jq -r '.error.code')
        if [ "$ERROR_CODE" = "null" ] || [ -z "$ERROR_CODE" ]; then
            success=true
            break
        fi
    done
    if [ "$success" = true ]; then
        AVAILABLE_KEYS+=("$API_KEY")
    else
        echo "Request failed with key: $API_KEY"
        echo "Error code: $ERROR_CODE"
    fi
done

echo "Number of available keys: ${#AVAILABLE_KEYS[@]}"
echo "Available keys: "
IFS=','; echo "${AVAILABLE_KEYS[*]}"; unset IFS
