#!/bin/bash

API_KEYS=$1
IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

declare -a URLS=(
"https://api.openai.com/v1/dashboard/billing/subscription"
"https://api.openai.com/dashboard/billing/usage?start_date=$(date -u -v-100d +"%Y-%m-%d")&end_date=$(date -u +"%Y-%m-%d")"
"https://api.openai.com/dashboard/billing/usage?start_date=$(date -u +"%Y-%m-%d")&end_date=$(date -u -v+1d +"%Y-%m-%d")"
"https://api.openai.com/v1/models/gpt-4"
)

for i in "${!API_KEY_ARRAY[@]}"; do
	API_KEY=${API_KEY_ARRAY[i]}
	for URL in "${URLS[@]}"; do
		CONTENT_TYPE="Content-Type: application/json"
		AUTHORIZATION="Authorization: Bearer $API_KEY"
		echo "Making request to: $URL"
		RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)
		echo "Response: $RESPONSE"
	done
done
