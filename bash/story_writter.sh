#!/bin/bash

ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent?key=$GEMINI_API_KEY"

# First API call: Send user prompt and tool declarations. Model should respond with function calls.
# Changed the -d argument to use a heredoc for robust multi-line JSON payload handling.
FIRST_CALL=$(curl "$ENDPOINT" \
  -H 'Content-Type: application/json' \
  -X POST \
  --data @- <<EOF
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "write the 1st paragraph of a hero story about 100 words"
        }
      ]
    }
  ]
}
EOF
)

echo "$FIRST_CALL"

# Save the response text into a variable
RESPONSE_TEXT=$(echo "$FIRST_CALL" | jq -r '.candidates[0].content.parts[0].text')

# Save the thought signature into a variable
THOUGHT_SIGNATURE=$(echo "$FIRST_CALL" | jq -r '.candidates[0].content.parts[0].thoughtSignature')

echo "--- Response Text ---"
echo "$RESPONSE_TEXT"

echo "--- Thought Signature ---"
echo "$THOUGHT_SIGNATURE"