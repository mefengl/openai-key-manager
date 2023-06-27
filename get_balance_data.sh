#!/bin/bash

function render_table() {
	DATA_ARRAY=("${!1}")
	HEADERS=("${!2}")
	COLORS=("${!3}")
	local FORMAT="%-18s"

	for i in "${!HEADERS[@]}"; do
		printf "${COLORS[i]}${FORMAT}${RESET}" "${HEADERS[i]}"
	done
	echo

	for i in "${!DATA_ARRAY[@]}"; do
		printf "${COLORS[i]}${FORMAT}${RESET}" "${DATA_ARRAY[i]}"
		if (((i + 1) % ${#HEADERS[@]} == 0)); then
			echo
		fi
	done
}

function print_api_keys() {
	API_KEYS=$1
	IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"
	echo "Your API keys:"
	for i in "${!API_KEY_ARRAY[@]}"; do
		echo "$((i + 1)). ${API_KEY_ARRAY[i]}"
	done
}

print_api_keys $1

function get_balance_data() {
	API_KEYS=$1
	IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

	if [ -z "$API_KEYS" ]; then
		echo "Error: Please provide API keys as an argument, separated by commas."
		return 1
	fi

	declare -a RESULTS
	for API_KEY in "${API_KEY_ARRAY[@]}"; do
		URL="https://api.openai.com/v1/dashboard/billing/subscription"
		CONTENT_TYPE="Content-Type: application/json"
		AUTHORIZATION="Authorization: Bearer $API_KEY"

		RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

		if [ -z "$RESPONSE" ]; then
			echo "Error: No response received for API key \"$API_KEY\". Please check your API key and try again."
			RESULTS+=("Error")
		else
			RESULTS+=("$RESPONSE")
		fi
	done

	format_data "${RESULTS[@]}"
}

function format_data() {
	RESULTS=("$@")

	GREEN="\033[32m"
	CYAN="\033[36m"
	YELLOW="\033[33m"
	BLUE="\033[34m"
	PURPLE="\033[35m"
	RESET="\033[0m"

	TERMINAL_WIDTH=$(tput cols)
	DIVIDER=$(printf '%*s' "$TERMINAL_WIDTH" '' | tr ' ' '=')

	echo -e "${GREEN}${DIVIDER}${RESET}"

	for i in "${!RESULTS[@]}"; do
		DATA="${RESULTS[i]}"
		if [ "$DATA" == "Error" ]; then
			echo "Error occurred while retrieving data."
			continue
		fi

		KEYS=(
			"account_name" "object" "has_payment_method" "canceled" "canceled_at" "delinquent"
			"access_until" "soft_limit" "hard_limit" "system_hard_limit"
			"soft_limit_usd" "hard_limit_usd" "system_hard_limit_usd"
			"title" "id" "po_number" "billing_email" "tax_ids"
			"billing_address" "business_address"
		)

		VALUES=()
		for KEY in "${KEYS[@]}"; do
			VALUE=$(echo "$DATA" | grep -oE "\"$KEY\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2-)
			VALUES+=("$VALUE")
		done

		ACCESS_UNTIL_DATE=$(date -u -r "${VALUES[6]}" +"%Y-%m-%d")
		NOW=$(date -u +"%s")
		SECONDS_LEFT=$((VALUES[6] - NOW))
		DAYS_LEFT=$((SECONDS_LEFT / 86400))

		TABLE0_HEADERS=("API Key No." "Account Name" "Plan ID" "Limit (USD)" "Days Left")
		TABLE0_DATA=("$((i + 1))" "${VALUES[0]}" "${VALUES[14]}" "${VALUES[12]}" "$DAYS_LEFT")
		TABLE0_COLORS=("$CYAN" "$YELLOW" "$BLUE" "$YELLOW")
		render_table TABLE0_DATA[@] TABLE0_HEADERS[@] TABLE0_COLORS[@]
		echo -e "${GREEN}${DIVIDER}${RESET}"
	done
}

get_balance_data $1

function get_usage_data() {
	API_KEYS=$1
	IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

	if [ -z "$API_KEYS" ]; then
		echo "Error: Please provide API keys as an argument, separated by commas."
		return 1
	fi

	declare -a RESULTS
	for i in "${!API_KEY_ARRAY[@]}"; do
		API_KEY=${API_KEY_ARRAY[i]}
		START_DATE=$(date -u -v-100d +"%Y-%m-%d")
		END_DATE=$(date -u +"%Y-%m-%d")
		URL="https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE"
		CONTENT_TYPE="Content-Type: application/json"
		AUTHORIZATION="Authorization: Bearer $API_KEY"

		RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

		if [ -z "$RESPONSE" ]; then
			echo "Error: No response received for API key \"$API_KEY\". Please check your API key and try again."
			RESULTS+=("Error")
		else
			RESULTS+=("$RESPONSE")
		fi
	done

	echo -e "\nUsage Data:"
	TABLE_HEADERS=("API Key No." "Total Usage")
	TABLE_COLORS=("$CYAN" "$YELLOW")
	for i in "${!RESULTS[@]}"; do
		TABLE_DATA=("$((i + 1))" "$(echo "${RESULTS[i]}" | grep -oE "\"total_usage\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2- | awk '{printf "%.2f$ ", $1/100}' | sed 's/ $/\n/')")
		render_table TABLE_DATA[@] TABLE_HEADERS[@] TABLE_COLORS[@]
		echo -e "${GREEN}${DIVIDER}${RESET}"
	done
}

get_usage_data $1

function get_today_usage_data() {
	API_KEYS=$1
	IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

	if [ -z "$API_KEYS" ]; then
		echo "Error: Please provide API keys as an argument, separated by commas."
		return 1
	fi

	declare -a RESULTS
	for i in "${!API_KEY_ARRAY[@]}"; do
		API_KEY=${API_KEY_ARRAY[i]}
		START_DATE=$(date -u +"%Y-%m-%d")
		END_DATE=$(date -u -v+1d +"%Y-%m-%d")
		URL="https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE"
		CONTENT_TYPE="Content-Type: application/json"
		AUTHORIZATION="Authorization: Bearer $API_KEY"

		RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

		if [ -z "$RESPONSE" ]; then
			echo "Error: No response received for API key \"$API_KEY\". Please check your API key and try again."
			RESULTS+=("Error")
		else
			RESULTS+=("$RESPONSE")
		fi
	done

	echo -e "\nToday's Usage Data:"
	TABLE_HEADERS=("API Key No." "Today's Usage")
	TABLE_COLORS=("$CYAN" "$YELLOW")
	for i in "${!RESULTS[@]}"; do
		TABLE_DATA=("$((i + 1))" "$(echo "${RESULTS[i]}" | grep -oE "\"total_usage\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2- | awk '{printf "%.2f$ ", $1/100}' | sed 's/ $/\n/')")
		render_table TABLE_DATA[@] TABLE_HEADERS[@] TABLE_COLORS[@]
		echo -e "${GREEN}${DIVIDER}${RESET}"
	done
}

get_today_usage_data $1
