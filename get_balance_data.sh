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

	for DATA in "${RESULTS[@]}"; do
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

		TABLE0_HEADERS=("Account Name" "Plan ID" "Limit (USD)" "Days Left")
    TABLE0_DATA=("${VALUES[0]}" "${VALUES[14]}" "${VALUES[12]}" "$DAYS_LEFT")
    TABLE0_COLORS=("$CYAN" "$YELLOW" "$BLUE" "$YELLOW")
		render_table TABLE0_DATA[@] TABLE0_HEADERS[@] TABLE0_COLORS[@]
		echo -e "${GREEN}${DIVIDER}${RESET}"

		# TABLE1_HEADERS=("Account Name" "Object" "Has Payment Method" "Canceled" "Access Until" "Days Left"
		# 	"Plan Title" "Plan ID")
		# TABLE1_DATA=("${VALUES[0]}" "${VALUES[1]}" "${VALUES[2]}" "${VALUES[3]}" "$ACCESS_UNTIL_DATE" "$DAYS_LEFT" "${VALUES[13]}" "${VALUES[14]}")
		# TABLE1_COLORS=("$CYAN" "$YELLOW" "$BLUE" "$PURPLE" "$GREEN" "$YELLOW" "$BLUE")
		# render_table TABLE1_DATA[@] TABLE1_HEADERS[@] TABLE1_COLORS[@]
		# echo -e "${GREEN}${DIVIDER}${RESET}"

		# TABLE2_HEADERS=("Soft Limit (USD)" "Hard Limit (USD)" "System Hard Limit (USD)" "Soft Limit" "Hard Limit" "System Hard Limit")
		# TABLE2_DATA=("${VALUES[10]}" "${VALUES[11]}" "${VALUES[12]}" "${VALUES[7]}" "${VALUES[8]}" "${VALUES[9]}")
		# TABLE2_COLORS=("$CYAN" "$YELLOW" "$BLUE" "$CYAN" "$YELLOW" "$BLUE")
		# render_table TABLE2_DATA[@] TABLE2_HEADERS[@] TABLE2_COLORS[@]
		# echo -e "${GREEN}${DIVIDER}${RESET}"

		# TABLE3_HEADERS=("Canceled At" "Delinquent" "PO Number" "Billing Email" "Tax IDs" "Billing Address" "Business Address")
		# TABLE3_DATA=("${VALUES[4]}" "${VALUES[5]}" "${VALUES[15]}" "${VALUES[16]}" "${VALUES[17]}" "${VALUES[18]}" "${VALUES[19]}")
		# TABLE3_COLORS=("$CYAN" "$YELLOW" "$BLUE" "$PURPLE" "$GREEN" "$YELLOW" "$BLUE")
		# render_table TABLE3_DATA[@] TABLE3_HEADERS[@] TABLE3_COLORS[@]
		# echo -e "${GREEN}${DIVIDER}${RESET}"
	done
}

get_balance_data $1
