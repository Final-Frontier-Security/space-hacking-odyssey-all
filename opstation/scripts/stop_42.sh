#!/bin/bash
#
zenity --info \
    --title="Stopping 42" \
    --text="The 42 windows should begin to close shortly..." \
    --timeout=5

# Stop the running container named 'fortytwo' if it exists
if docker ps --filter "name=fortytwo" --format '{{.Names}}' | grep -q "^fortytwo$"; then
  echo "Stopping 42 container..."
  docker stop fortytwo
else
  echo "No container named 'fortytwo' is currently running."
fi

