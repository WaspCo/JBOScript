#!/bin/bash
#Fast access to fan control from /usr/local/bin

if [ "$1" == "full" ]; then
  echo level disengaged | sudo tee /proc/acpi/ibm/fan
  echo "Fan full speed set"
elif [ "$1" == "auto" ]; then
  echo level auto | sudo tee /proc/acpi/ibm/fan
  echo "Fan auto speed set"
fi
