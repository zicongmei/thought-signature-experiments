#!/bin/bash

# Ensure your API key is set
# export GEMINI_API_KEY="YOUR_KEY_HERE"

ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY"

# Run curl directly
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

echo $FUNC_ARG | jq .
