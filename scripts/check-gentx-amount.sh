#!/bin/bash
CHAIN_ID=akashnet-1

set -eo pipefail

for FILE in ./$CHAIN_ID/gentxs/*; 
do 
  path="$FILE"

  echo "Validating $FILE"

  declare -i maxbond=1000000000

  extraquery='[.value.msg[]| select(.type != "cosmos-sdk/MsgCreateValidator")]|length'

  gentxquery='.value.msg[]| select(.type == "cosmos-sdk/MsgCreateValidator")|.value.value'

  denomquery="[$gentxquery | select(.denom != \"uakt\")] | length"

  amountquery="$gentxquery | .amount"

  # only allow MsgCreateValidator transactions.
  if [ "$(jq "$extraquery" "$path")" != "0" ]; then
    echo "spurious transactions, FILE_PATH: $FILE"
    continue
  fi

  # only allow "uakt" tokens to be bonded
  if [ "$(jq "$denomquery" "$path")" != "0" ]; then
    echo "invalid denomination , FILE_PATH: $FILE"
    continue
  fi

  # limit the amount that can be bonded
  for amount in "$(jq -rM "$amountquery" "$path")"; do
    declare -i amt="$amount"
    if [ $amt -gt $maxbond ]; then
      echo "bonded too much: $amt > $maxbond , FILE_PATH: $FILE"
      continue
    fi
  done
done
