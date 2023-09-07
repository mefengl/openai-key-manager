#!/bin/bash
API_KEYS=$1
IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"
AVAILABLE_KEYS=()
URL="https://api.openai.com/v1/chat/completions"
CONTENT_TYPE="Content-Type: application/json"
DATA='{
  "model": "gpt-3.5-turbo",
  "messages": [
    {
      "role": "user",
      "content": "1+1=x, x="
    }
  ]
}'
for i in "${!API_KEY_ARRAY[@]}"; do
	API_KEY=${API_KEY_ARRAY[i]}
	AUTHORIZATION="Authorization: Bearer $API_KEY"
	success=false
	for attempt in {1..2}; do
		RESPONSE=$(curl -s -X POST -H "$CONTENT_TYPE" -H "$AUTHORIZATION" -d "$DATA" $URL)
		ERROR_CODE=$(echo $RESPONSE | jq -r '.error.code')
		if [ "$ERROR_CODE" = "null" ]; then
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
