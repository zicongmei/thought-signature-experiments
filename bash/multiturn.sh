#!/bin/bash

# Ensure your API key is set
# export GEMINI_API_KEY="YOUR_KEY_HERE"

ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY"

# Source the dummy_func.sh to make get_current_temperature available in this script
source "$(dirname "$0")/dummy_func.sh"

# First API call: Send user prompt and tool declarations. Model should respond with function calls.
FUNC_ARG=$(curl "$ENDPOINT" \
  -H 'Content-Type: application/json' \
  -X POST \
  -d '{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Check the weather in Paris and London."
        }
      ]
    }
  ],
  "tools": [
    {
      "function_declarations": [
        {
          "name": "get_current_temperature",
          "description": "Gets the current temperature for a given location.",
          "parameters": {
            "type": "object",
            "properties": {
              "location": {
                "type": "string",
                "description": "The city name, e.g. San Francisco"
              }
            },
            "required": [
              "location"
            ]
          }
        }
      ]
    }
  ]
}')

echo "--- First API Response (Model's suggested function calls) ---"
echo "$FUNC_ARG" | jq .

# Extract the function calls requested by the model
# Assuming the model's response has candidates[0].content.parts containing functionCall objects
MODEL_FUNCTION_CALLS=$(echo "$FUNC_ARG" | jq -c '.candidates[0].content.parts[] | select(.functionCall != null)')

FUNCTION_RESPONSES_JSON=""
MODEL_PARTS_JSON=""
FIRST_CALL=true

# Iterate over each function call the model requested
while IFS= read -r call_part; do
  if [ -z "$call_part" ]; then
    continue
  fi

  FUNC_NAME=$(echo "$call_part" | jq -r '.functionCall.name')
  FUNC_ARGS_JSON=$(echo "$call_part" | jq -c '.functionCall.args')
  LOCATION=$(echo "$FUNC_ARGS_JSON" | jq -r '.location')

  echo "Executing local function: $FUNC_NAME(location=\"$LOCATION\")"

  # Execute the dummy function locally and capture its JSON output
  # The dummy function (get_current_temperature) is expected to return a JSON string
  LOCAL_FUNC_RESULT=$(get_current_temperature "$LOCATION")

  echo "Local function result: $LOCAL_FUNC_RESULT"

  # Build the 'functionResponse' part for the second API call
  # And also reconstruct the 'model's 'functionCall' parts
  if [ "$FIRST_CALL" = true ]; then
    FUNCTION_RESPONSES_JSON="{\"functionResponse\": {\"name\": \"$FUNC_NAME\", \"response\": $LOCAL_FUNC_RESULT}}"
    MODEL_PARTS_JSON="{\"functionCall\": {\"name\": \"$FUNC_NAME\", \"args\": $FUNC_ARGS_JSON}}"
    FIRST_CALL=false
  else
    FUNCTION_RESPONSES_JSON+=", {\"functionResponse\": {\"name\": \"$FUNC_NAME\", \"response\": $LOCAL_FUNC_RESULT}}"
    MODEL_PARTS_JSON+=", {\"functionCall\": {\"name\": \"$FUNC_NAME\", \"args\": $FUNC_ARGS_JSON}}"
  fi
done <<< "$MODEL_FUNCTION_CALLS"

# Construct the full 'contents' array for the second API call (multiturn conversation)
# This includes the user's turn, the model's function calls, and the results from those calls.
CONTENTS_PAYLOAD=$(cat <<EOF
[
  {
    "role": "user",
    "parts": [
      {
        "text": "Check the weather in Paris and London."
      }
    ]
  },
  {
    "role": "model",
    "parts": [
      $MODEL_PARTS_JSON
    ]
  },
  {
    "role": "function",
    "parts": [
      $FUNCTION_RESPONSES_JSON
    ]
  }
]
EOF
)

# Second API call: Send the function results back to the model
SECOND_CALL_RESULT=$(curl "$ENDPOINT" \
  -H 'Content-Type: application/json' \
  -X POST \
  -d "{
  \"contents\": $CONTENTS_PAYLOAD
}")

echo "--- Second API Response (Model's final answer after receiving func results) ---"
echo "$SECOND_CALL_RESULT" | jq .