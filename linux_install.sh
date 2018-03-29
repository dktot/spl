#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='simplicity.conf'
CONFIGFOLDER='/root/.simplicity'
COIN_DAEMON='simplicityd'
COIN_CLI='simplicity-cli'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/LunexCoin/Lunex.git'
COIN_TGZ='https://github.com/zoldur/Lunex/releases/download/1.0.0.0/Lunex.tgz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='Simplicity'
COIN_PORT=11957
RPC_PORT=11958


NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function compile_node() {
  echo -e "Prepare to compile $COIN_NAME"
  git clone $COIN_REPO $TMP_FOLDER >/dev/null 2>&1
  compile_error
  cd $TMP_FOLDER
  chmod +x ./autogen.sh 
  chmod +x ./share/genbuild.sh
  ./autogen.sh
  compile_error
  ./configure
  compile_error
  make
  compile_error
  make install
  compile_error
  strip $COIN_PATH$COIN_DAEMON $COIN_PATH$COIN_CLI
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function download_node() {
  echo -e "Prepare to download $COIN_NAME binaries"
  cd $TMP_FOLDER
  wget -q $COIN_TGZ
  tar xvzf $COIN_ZIP >/dev/null 2>&1
  compile_error
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH 
  chmod +x $COIN_PATH$COIN_DAEMON $COIN_PATH$COIN_CLI
  cd - >/dev/null 2>&1
  rm -r $TMP_FOLDER >/dev/null 2>&1
  clear
}

function ask_permission() {
 echo -e "${RED}I trust zoldur and want to use$ $COIN_NAME binaries compiled on his server.${NC}."
 echo -e "Please type ${RED}YES${NC} if you want to use precompiled binaries, or type anything else to compile them on your server"
 read -e ZOLDUR
 clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=32
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
addnode=1.217.65.210:11957
addnode=103.82.248.2:11957
addnode=104.156.226.149:11957
addnode=104.238.136.200:11957
addnode=107.191.53.101:9999
addnode=108.168.45.3:9999
addnode=108.61.175.84:11957
addnode=108.61.211.169:11957
addnode=112.213.91.4:11957
addnode=121.168.154.82:9999
addnode=121.82.177.68:9999
addnode=13.127.138.90:11957
addnode=139.59.57.207:9999
addnode=139.59.59.21:9999
addnode=14.3.127.5:9999
addnode=14.35.193.150:11957
addnode=140.82.16.248:11957
addnode=140.82.8.151:11957
addnode=144.202.43.227:9999
addnode=144.202.56.170:9999
addnode=144.202.66.162:9998
addnode=144.202.66.162:9999
addnode=144.202.86.229:11957
addnode=146.66.179.123:11957
addnode=146.66.179.123:9999
addnode=151.106.14.187:11957
addnode=159.203.56.163:9999
addnode=159.65.230.245:11956
addnode=159.65.230.245:11957
addnode=159.89.170.157:9999
addnode=163.172.157.248:11961
addnode=163.172.157.248:11963
addnode=163.172.157.248:11965
addnode=168.235.82.243:11957
addnode=172.245.154.198:11957
addnode=172.245.185.103:9900
addnode=172.92.244.123:11957
addnode=178.62.233.89:9999
addnode=18.188.137.227:11957
addnode=18.217.146.158:11957
addnode=185.63.188.60:11957
addnode=192.154.213.160:11957
addnode=192.210.226.13:49157
addnode=192.250.236.74:11957
addnode=195.133.49.67:11957
addnode=195.181.215.34:9999
addnode=195.201.100.57:9999
addnode=195.201.22.34:11957
addnode=195.64.155.181:9999
addnode=198.13.43.142:9998
addnode=198.13.43.142:9999
addnode=199.247.0.191:9999
addnode=199.247.22.78:11957
addnode=199.247.26.98:7777
addnode=2.224.132.235:9999
addnode=207.148.126.67:9999
addnode=207.148.78.192:11957
addnode=207.246.111.191:11957
addnode=207.246.124.75:11957
addnode=207.246.124.75:11958
addnode=207.246.124.75:11959
addnode=207.246.124.75:11960
addnode=207.246.124.75:11961
addnode=207.246.124.75:11962
addnode=207.246.73.14:9999
addnode=209.250.224.25:9999
addnode=209.250.252.83:9998
addnode=209.250.252.83:9999
addnode=212.104.97.56:11957
addnode=212.104.97.56:11957
addnode=212.237.4.148:11957
addnode=213.211.33.236:9999
addnode=23.95.221.245:9999
addnode=35.180.17.53:9999
addnode=35.185.166.90:11957
addnode=35.196.236.81:11957
addnode=35.197.188.46:9999
addnode=35.201.212.165:11957
addnode=35.204.190.239:9999
addnode=37.192.97.231:9999
addnode=45.32.12.45:9999
addnode=45.32.141.241:11958
addnode=45.32.141.241:11961
addnode=45.32.204.87:11957
addnode=45.32.6.178:11957
addnode=45.32.64.202:11957
addnode=45.63.67.119:9999
addnode=45.63.88.45:9997
addnode=45.63.88.45:9998
addnode=45.63.88.45:9999
addnode=45.63.95.121:11957
addnode=45.76.19.242:11957
addnode=45.76.205.209:11957
addnode=45.76.245.11:11957
addnode=45.76.44.87:11957
addnode=45.76.44.87:11959
addnode=45.76.44.87:11961
addnode=45.76.44.87:11963
addnode=45.76.54.84:11954
addnode=45.76.54.84:11957
addnode=45.76.96.157:11957
addnode=45.76.98.111:11957
addnode=45.77.108.112:9999
addnode=45.77.139.167:11957
addnode=45.77.162.145:11957
addnode=45.77.192.87:11957
addnode=45.77.193.46:9999
addnode=45.77.228.104:11957
addnode=45.77.230.184:11957
addnode=45.77.48.45:11957
addnode=45.77.63.39:11957
addnode=45.77.79.64:11957
addnode=45.77.97.245:9999
addnode=45.79.129.176:9999
addnode=46.196.30.133:11957
addnode=46.4.59.215:9999
addnode=47.196.31.31:11957
addnode=47.74.145.214:11957
addnode=51.15.58.41:11959
addnode=51.15.58.41:11960
addnode=51.15.58.41:11961
addnode=51.15.58.41:11962
addnode=51.15.58.41:11963
addnode=51.15.58.41:11964
addnode=51.15.58.41:11966
addnode=51.15.77.125:21111
addnode=51.15.81.104:23999
addnode=51.254.158.242:11957
addnode=60.227.0.178:11957
addnode=62.138.1.223:0
addnode=66.70.188.183:9993
addnode=66.70.188.183:9994
addnode=66.70.188.183:9995
addnode=66.70.188.183:9996
addnode=66.70.188.183:9997
addnode=66.70.188.183:9998
addnode=71.204.182.94:11957
addnode=71.234.111.128:10000
addnode=72.222.182.53:19700
addnode=72.222.182.53:19701
addnode=72.222.182.53:19702
addnode=72.222.182.53:19703
addnode=72.222.182.53:19704
addnode=72.222.182.53:19706
addnode=72.222.182.53:19707
addnode=72.222.182.53:19709
addnode=72.222.182.53:19710
addnode=72.222.182.53:19711
addnode=73.185.17.0:9999
addnode=73.84.24.197:9999
addnode=76.22.116.146:11957
addnode=77.93.202.229:10001
addnode=77.93.202.229:10002
addnode=77.93.202.229:10003
addnode=77.93.202.229:10004
addnode=77.93.202.229:10005
addnode=77.93.202.229:10006
addnode=78.46.231.139:9999
addnode=78.61.18.211:11957
addnode=80.211.1.147:9999
addnode=80.211.13.117:47001
addnode=80.211.13.174:9999
addnode=80.211.137.179:47001
addnode=82.199.168.63:9998
addnode=84.107.92.116:9998
addnode=84.200.105.175:11957
addnode=84.42.169.29:9996
addnode=84.42.169.29:9997
addnode=84.42.169.29:9998
addnode=84.42.169.29:9999
addnode=84.52.160.34:11957:1
addnode=85.214.122.236:9999
addnode=85.214.136.12:9999
addnode=85.214.154.230:9999
addnode=85.214.32.70:11957
addnode=85.25.242.201:9997
addnode=88.5.209.230:11957
addnode=89.111.23.33:11957
addnode=89.163.252.168:11957
addnode=91.249.5.238:9995
addnode=91.249.5.238:9996
addnode=91.249.5.238:9997
addnode=91.65.72.39:11957
addnode=93.114.161.41:41012
addnode=93.114.161.46:41012
addnode=93.116.29.98:11957
addnode=94.130.190.181:9999
addnode=94.130.190.255:9999
addnode=94.177.172.72:9999
addnode=96.127.206.72:9999
addnode=97.90.251.197:9999
EOF
}


function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ jq >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev jq"
 exit 1
fi

clear
}

function create_swap() {
 echo -e "Checking if swap space is needed."
 PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
 SWAP=$(free -g|awk '/^Swap:/{print $2}')
 if [ "$PHYMEM" -lt "2" ] && [ -n "$SWAP" ]
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM without SWAP, creating 2G swap file.${NC}"
    SWAPFILE=$(mktemp)
    dd if=/dev/zero of=$SWAPFILE bs=1024 count=2M
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon -a $SWAPFILE
 else
  echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
 fi
 clear
}


function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "================================================================================================================================"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}


##### Main #####
clear

checks
prepare_system
ask_permission
if [[ "$ZOLDUR" == "YES" ]]; then
  download_node
else
  create_swap
  compile_node
fi
setup_node
