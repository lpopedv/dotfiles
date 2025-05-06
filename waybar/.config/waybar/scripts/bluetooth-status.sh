#!/usr/bin/env bash

powered=$(bluetoothctl show | grep "Powered: yes")
devices=$(bluetoothctl devices Connected | grep Device)

if [[ -n "$powered" ]]; then
  if [[ -n "$devices" ]]; then
    icon="" # Conectado
    tooltip=$(echo "$devices" | awk '{$1=$2=""; print substr($0,3)}' | paste -sd ", ")
    class="connected"
  else
    icon="" # Ligado, mas não conectado
    tooltip="Ligado, sem dispositivos conectados"
    class="on"
  fi
else
  icon="" # Desligado
  tooltip="Bluetooth desligado"
  class="off"
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
