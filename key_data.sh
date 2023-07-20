#!/bin/bash

# function to get and format balance data
function get_balance_data() {
  API_KEYS=$1
  IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

  for API_KEY in "${API_KEY_ARRAY[@]}"; do
    URL="https://api.openai.com/v1/dashboard/billing/subscription"
    CONTENT_TYPE="Content-Type: application/json"
    AUTHORIZATION="Authorization: Bearer $API_KEY"

    RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

    ACCESS_UNTIL=$(echo "$RESPONSE" | grep -oE "\"access_until\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2-)
    ACCESS_UNTIL_DATE=$(date -u -r "$ACCESS_UNTIL" +"%Y-%m-%d")
    NOW=$(date -u +"%s")
    SECONDS_LEFT=$((ACCESS_UNTIL - NOW))
    DAYS_LEFT=$((SECONDS_LEFT / 86400))

    echo "API Key: $API_KEY"
    echo "Days Left: $DAYS_LEFT"
  done
}

# function to get and format usage data
function get_usage_data() {
  API_KEYS=$1
  IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

  for API_KEY in "${API_KEY_ARRAY[@]}"; do
    START_DATE=$(date -u -v-100d +"%Y-%m-%d")
    END_DATE=$(date -u +"%Y-%m-%d")
    URL="https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE"
    CONTENT_TYPE="Content-Type: application/json"
    AUTHORIZATION="Authorization: Bearer $API_KEY"

    RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

    TOTAL_USAGE=$(echo "$RESPONSE" | grep -oE "\"total_usage\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2- | awk '{printf "%.2f", $1/100}')

    echo "API Key: $API_KEY"
    echo "Total Usage: $TOTAL_USAGE"
  done
}

# function to get and format today's usage data
function get_today_usage_data() {
  API_KEYS=$1
  IFS=',' read -ra API_KEY_ARRAY <<<"$API_KEYS"

  for API_KEY in "${API_KEY_ARRAY[@]}"; do
    START_DATE=$(date -u +"%Y-%m-%d")
    END_DATE=$(date -u -v+1d +"%Y-%m-%d")
    URL="https://api.openai.com/dashboard/billing/usage?start_date=$START_DATE&end_date=$END_DATE"
    CONTENT_TYPE="Content-Type: application/json"
    AUTHORIZATION="Authorization: Bearer $API_KEY"

    RESPONSE=$(curl -s -X GET -H "$CONTENT_TYPE" -H "$AUTHORIZATION" $URL)

    TODAY_USAGE=$(echo "$RESPONSE" | grep -oE "\"total_usage\": ([^,]*|\"[^\"]*\")" | cut -d' ' -f2- | awk '{printf "%.2f", $1/100}')

    echo "API Key: $API_KEY"
    echo "Today's Usage: $TODAY_USAGE"
  done
}

API_KEYS=$1

echo "Balance Data:"
get_balance_data $API_KEYS

echo "\nUsage Data:"
get_usage_data $API_KEYS

echo "\nToday's Usage Data:"
get_today_usage_data $API_KEYS
