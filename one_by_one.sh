#!/bin/bash

function request_data() {
	API_KEY=$1
	URL=$2
	RESPONSE=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $API_KEY" $URL)
	echo "$RESPONSE"
}

function process_keys() {
	API_KEYS=$1
	IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

	for i in "${!API_KEY_ARRAY[@]}"; do
		API_KEY=${API_KEY_ARRAY[i]}
		echo "Processing API Key $((i + 1))..."

		# Balance Data
		BALANCE_DATA=$(request_data "$API_KEY" "https://api.openai.com/v1/dashboard/billing/subscription")
		ACCOUNT_NAME=$(echo "$BALANCE_DATA" | grep -oE "\"account_name\": \"[^\"]*\"" | cut -d' ' -f2-)
		PLAN_ID=$(echo "$BALANCE_DATA" | grep -oE "\"id\": \"[^\"]*\"" | cut -d' ' -f2-)
		echo "Account Name: $ACCOUNT_NAME"
		echo "Plan ID: $PLAN_ID"

		# Usage Data for the past 100 days
		START_DATE=$(date -u -v-100d +"%Y-%m-%d")
		END_DATE=$(date -u +"%Y-%m-%d")
		USAGE_DATA=$(request_data "$API_KEY" "https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE")
		TOTAL_USAGE=$(echo "$USAGE_DATA" | grep -oE "\"total_usage\": [^,]*" | cut -d' ' -f2-)
		echo "Total Usage: $TOTAL_USAGE"

		# Today's Usage Data
		START_DATE=$(date -u +"%Y-%m-%d")
		END_DATE=$(date -u -v+1d +"%Y-%m-%d")
		TODAY_USAGE_DATA=$(request_data "$API_KEY" "https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE")
		TODAY_USAGE=$(echo "$TODAY_USAGE_DATA" | grep -oE "\"total_usage\": [^,]*" | cut -d' ' -f2-)
		echo "Today's Usage: $TODAY_USAGE"

		# GPT-4 Support
		GPT4_DATA=$(request_data "$API_KEY" "https://api.openai.com/v1/models/gpt-4")
		GPT4_ERROR=$(echo "$GPT4_DATA" | grep -oE "\"error\": {" | cut -d' ' -f2-)
		if [ -z "$GPT4_ERROR" ]; then
			echo "GPT-4 Support: Supported"
		else
			echo "GPT-4 Support: Not Supported"
		fi

		echo "-------------------------"
	done
}

process_keys $1
