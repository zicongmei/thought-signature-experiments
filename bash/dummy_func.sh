#!/bin/bash

# A fake function to return a fake temperature for a given location.
get_current_temperature() {
  local location="$1"
  local temp

  # Simulate different temperatures for specific cities
  case "$location" in
    "Paris")
      temp="18 degrees C"
      ;;
    "London")
      temp="15 degrees C"
      ;;
    "San Francisco")
      temp="22 degrees C"
      ;;
    *) # Default temperature for other locations
      temp="20 degrees C"
      ;;
  esac

  # Return the result as a JSON string, matching the expected format for functionResponse.response
  echo "{\"temperature\": \"$temp\", \"location\": \"$location\"}"
}