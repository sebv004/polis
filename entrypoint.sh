#!/bin/bash
set -eo pipefail

CONFIG_FILE='polis.conf'
CONFIGFOLDER='/var/polis'
SENTI_CONFIGFOLDER='/var/sentinel'
COIN_DAEMON='/usr/local/bin/polisd'
COIN_CLI='/usr/local/bin/polis-cli'
COIN_REPO='https://github.com/polispay/polis/releases/download/v1.6.3/poliscore-1.6.3-x86_64-linux-gnu.tar.gz'
COIN_ZIP='poliscore-1.6.3-x86_64-linux-gnu.tar.gz'
SENTINEL_REPO='https://github.com/polispay/sentinel.git'
COIN_NAME='Polis'
COIN_PORT=24126
COIN_BS='https://github.com/polispay/polis/releases/download/v1.6.1/bootstrap.tar.gz'
TRACE_FILE=$CONFIGFOLDER/start.log

NODEIP=$(curl -s4 icanhazip.com)


function create_config() {
    echo -e "Enter create config"

  RPCUSER=$(pwgen -s 32 1)
  RPCPASSWORD=$(pwgen -s 64 1)
  echo -e "Enter create config cat"
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
echo -e "Ends create conf "
}

function create_key() {
  echo -e "Generating a new BLS ${RED}Masternode Private Key${NC} for you: see masternodeinfo file"
#   read -e COINKEY
#   echo -e "Generating a new ${RED}BLS Private Key${NC}"
#   if [[ -z "$COINKEY" ]]; then
  $COIN_DAEMON -daemon
  sleep 8
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "Could not start ${RED}$COIN_NAME server. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_CLI bls generate)
  COINKEYPRIVRAW=$(echo "$COINKEY" | grep -Po '"secret": ".*?[^\\]"' | cut -c12-)
  COINKEYPRIV=${COINKEYPRIVRAW::-1}
  COINKEYPUBRAW=$(echo "$COINKEY" | grep -Po '"public": ".*?[^\\]"' | cut -c12-)
  COINKEYPUB=${COINKEYPUBRAW::-1}
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_CLI bls generate)
    COINKEYPRIVRAW=$(echo "$COINKEY" | grep -Po '"secret": ".*?[^\\]"' | cut -c12-)
    COINKEYPRIV=${COINKEYPRIVRAW::-1}
    COINKEYPUBRAW=$(echo "$COINKEY" | grep -Po '"public": ".*?[^\\]"' | cut -c12-)
    COINKEYPUB=${COINKEYPUBRAW::-1}
  fi
  $COIN_CLI stop
  sleep 8
# fi
clear
}

function update_config() {
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=64
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeblsprivkey=$COINKEYPRIV
addnode=insight.polispay.org
addnode=116.203.116.205
addnode=95.216.56.42
addnode=207.180.218.18
addnode=80.211.45.85
addnode=176.233.138.86
addnode=5.189.161.94
addnode=149.28.209.101
addnode=167.99.85.39
addnode=157.230.87.57
EOF
echo $COINKEYPUB > $CONFIGFOLDER/masternode.info
}

adddate() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date)" "$line";
    done
}

updatecron()
{
  if [ ! -f "$SENTI_CONFIGFOLDER/$COIN_NAME.cron" ]; then
    echo "* * * * * export SENTINEL_CONFIG=\"/var/sentinel/sentinel.conf\" && cd /opt/sentinel && bash -c \"./venv/bin/python bin/sentinel.py\" >> $SENTI_CONFIGFOLDER/sentinel.log 2>&1 " >> $SENTI_CONFIGFOLDER/$COIN_NAME.cron
    chmod 0744 $SENTI_CONFIGFOLDER/$COIN_NAME.cron
    fi
  
  crontab $SENTI_CONFIGFOLDER/$COIN_NAME.cron
  # rm $SENTI_CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
}


# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
   echo "term_handler***Stopping"
   $COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
   exit 0
}



##### Main #####
mymain(){
export TERM=xterm
# Setup signal handlers
trap 'term_handler' SIGTERM
echo -e "Start entrypoint"
FILE=$CONFIGFOLDER/$CONFIG_FILE
if [ -f "$FILE" ]; then
    echo -e "$FILE exist"
else 
    echo -e "$FILE does not exist"
    create_config
  #import_bootstrap
  create_key
  update_config
  echo "default conf created see polis.conf"
fi

echo "lauchind daemon with conf"
$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
echo "lauching cron"
updatecron
cron
# Running something in foreground, otherwise the container will stop
while true
do
   sleep 4
   #tail -f /dev/null & wait ${!}
done
}


echo -e "call mymain"
mymain 2>&1 >> $TRACE_FILE

