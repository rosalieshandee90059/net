#!/bin/sh
AKASH_HOME="/tmp/akash$(date +%s)"
AKASHCTL_HOME="/tmp/akashctl$(date +%s)"
RANDOM_KEY="randomvalidatorkeyxx"

GENTX_FILE=$(ls centauri/gentxs -I gosuri.json | head -1)
LEN_GENTX=$(echo ${#GENTX_FILE})

GENTX_DEADLINE=$(date -d '2020-05-06 16:00:00' '+%d/%m/%Y %H:%M:%S');
now=$(date +"%d/%m/%Y %H:%M:%S")

latest_dir="$(dirname "$0")/../latest"
version="$(cat "$latest_dir/version.txt")"
chain_id="$(cat "$latest_dir/chain_id.txt")"


# if [ $GENTX_DEADLINE < $now ]; then
#     echo 'Gentx submission is closed'
# el
if [ $LEN_GENTX -eq 0 ]; then
    echo "No new gentx file found."
else
    set -e

    echo "...........Init Akash.............."
    curl -sSfL https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- "v$version"
    cd bin

    echo "12345678" | ./akashctl keys add $RANDOM_KEY --keyring-backend test --home $AKASHCTL_HOME

    ./akashd init --chain-id "$chain_id" testvalxyz --home $AKASH_HOME -o

    echo "..........Fetching genesis......."
    rm -rf $AKASH_HOME/config/genesis.json

    cp "$latest_dir/genesis.json" "$AKASH_HOME/config/genesis.json"

    GENACC=$(cat ../centauri/gentxs/$GENTX_FILE | sed -n 's|.*"delegator_address":"\([^"]*\)".*|\1|p')

    echo $GENACC

    echo "12345678" | ./akashd add-genesis-account $RANDOM_KEY 1000000000000uakt --home $AKASH_HOME \
        --keyring-backend test --home-client $AKASHCTL_HOME
    ./akashd add-genesis-account $GENACC 1000000000uakt --home $AKASH_HOME

    echo "12345678" | ./akashd gentx --name $RANDOM_KEY --amount 900000000000uakt --home $AKASH_HOME \
        --keyring-backend test --home-client $AKASHCTL_HOME
    cp ../centauri/gentxs/$GENTX_FILE $AKASH_HOME/config/gentx/

    echo "..........Collecting gentxs......."
    ./akashd collect-gentxs --home $AKASH_HOME
    sed -i '/persistent_peers =/c\persistent_peers = ""' $AKASH_HOME/config/config.toml

    ./akashd validate-genesis --home $AKASH_HOME

    echo "..........Starting node......."
    ./akashd start --home $AKASH_HOME &

    sleep 5s

    echo "...checking network status.."

    ./akashctl status --chain-id "$chain_id"

    echo "...Cleaning the stuff..."
    killall akashd >/dev/null 2>&1
    rm -rf $AKASH_HOME >/dev/null 2>&1
fi
