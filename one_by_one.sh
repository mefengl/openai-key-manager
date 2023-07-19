#!/bin/bash

# Function to send a GET request to a URL using the provided API key
function request_data() {
	RESPONSE=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $1" $2)
	echo "$RESPONSE"
}

# Function to extract a specific value from a JSON response
function extract_value() {
	echo "$1" | grep -oE "\"$2\": [^,]*" | cut -d' ' -f2-
}

# Function to process each API key
function process_keys() {
	IFS=',' read -ra API_KEY_ARRAY <<<"$1"
	for i in "${!API_KEY_ARRAY[@]}"; do
		API_KEY=${API_KEY_ARRAY[i]}
		# Printing a green divider line
		echo -e "\033[32m$(printf '%*s' "$(tput cols)" '' | tr ' ' '=')\033[0m"
		echo -e "API Key $((i + 1)): ${API_KEY:0:4}...${API_KEY: -4}"

		# Requesting balance data and printing the required details
		DATA=$(request_data "$API_KEY" "https://api.openai.com/v1/dashboard/billing/subscription")
		echo "Account Name: $(extract_value "$DATA" "account_name")"
		echo "Plan ID: $(extract_value "$DATA" "id")"
		LIMIT=$(extract_value "$DATA" "soft_limit_usd")
		echo "Limit (USD): $LIMIT"

		# Requesting usage data for the past 100 days and printing the total usage and percentage
		START_DATE=$(date -u -v-100d +"%Y-%m-%d")
		END_DATE=$(date -u +"%Y-%m-%d")
		DATA=$(request_data "$API_KEY" "https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE")
		TOTAL_USAGE=$(extract_value "$DATA" "total_usage")
		echo "Total Usage: $(echo "scale=2; $TOTAL_USAGE/100" | bc)"

		# Requesting today's usage data and printing it
		START_DATE=$(date -u +"%Y-%m-%d")
		END_DATE=$(date -u -v+1d +"%Y-%m-%d")
		DATA=$(request_data "$API_KEY" "https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE")
		TODAY_USAGE=$(extract_value "$DATA" "total_usage")
		echo "Today's Usage: $(echo "scale=2; $TODAY_USAGE/100" | bc)"

		# Checking GPT-4 support and printing the result
		DATA=$(request_data "$API_KEY" "https://api.openai.com/v1/models/gpt-4")
		echo "GPT-4 Support: $(if echo "$DATA" | grep -qE "\"error\": {"; then echo "Not Supported"; else echo "Supported"; fi)"
	done
	# Printing a green divider line
	echo -e "\033[32m$(printf '%*s' "$(tput cols)" '' | tr ' ' '=')\033[0m"
}

# Main execution
process_keys $1
