#!/bin/bash
# AirPods Battery CLI, Version 2.3
# Contributors: duk242, ankushg, spetykowski, danozdotnet
# Released under the MIT License.

# ID="${1:}"

OUTPUT='🎧'
BLUETOOTH_DEFAULTS=$(defaults read /Library/Preferences/com.apple.Bluetooth)
SYSTEM_PROFILER=$(system_profiler SPBluetoothDataType)
MAC_ADDR=$(grep -b2 "Minor Type: Headphone" <<<"${SYSTEM_PROFILER}" | awk '/Address/{print $3}')
CONNECTED=$(grep -ia6 "${MAC_ADDR}" <<<"${SYSTEM_PROFILER}" | awk '/Connected: Yes/{print 1}')
BLUETOOTH_DATA=$(grep -ia6 '"'"${MAC_ADDR}"'"' <<<"${BLUETOOTH_DEFAULTS}")
BATTERY_LEVELS=("BatteryPercentCombined" "HeadsetBattery" "BatteryPercentSingle" "BatteryPercentCase" "BatteryPercentLeft" "BatteryPercentRight")

if [[ "${CONNECTED}" ]]; then
  for I in "${BATTERY_LEVELS[@]}"; do
    declare -x "${I}"="$(awk -v pat="${I}" '$0~pat{gsub (";",""); print $3 }' <<<"${BLUETOOTH_DATA}")"
    [[ ! -z "${!I}" ]] && OUTPUT="${OUTPUT} $(awk '/BatteryPercent/{print substr($0,15,1)": "}' <<<"${I}")${!I}%"
  done
  printf "%s\\n" "${OUTPUT}"
else
  printf "%s Not Connected\\n" "${OUTPUT}"
fi
