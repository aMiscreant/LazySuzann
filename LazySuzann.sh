#!/bin/bash

# LazySuzann - Automatic PWN Framework
# Author: @aMiscreant

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

dependencies=("nmap" "aircrack-ng" "crunch" "nuclei" "hcxpcapngtool")
for dep in "${dependencies[@]}"; do
  command -v $dep >/dev/null 2>&1 || echo -e "${YELLOW}Missing dependency: $dep${NC}"
done

echo "[INFO] Module 2 launched by $USER at $(date)" >> logs/lz_activity.log

banner() {
  clear
  echo -e "${RED}"
  echo -e " _        _______  _______           _______           _______  _______  _        _"
  echo -e "( \      (  ___  )/ ___   )|\     /|(  ____ \|\     /|/ ___   )(  ___  )( (    /|( (    /|"
  echo -e "| (      | (   ) |\/   )  |( \   / )| (    \/| )   ( |\/   )  || (   ) ||  \  ( ||  \  ( |"
  echo -e "| |      | (___) |    /   ) \ (_) / | (_____ | |   | |    /   )| (___) ||   \ | ||   \ | |"
  echo -e "| |      |  ___  |   /   /   \   /  (_____  )| |   | |   /   / |  ___  || (\ \) || (\ \) |"
  echo -e "| |      | (   ) |  /   /     ) (         ) || |   | |  /   /  | (   ) || | \   || | \   |"
  echo -e "| (____/\| )   ( | /   (_/\   | |   /\____) || (___) | /   (_/\| )   ( || )  \  || )  \  |"
  echo -e "(_______/|/     \|(_______/   \_/   \_______)(_______)(_______/|/     \||/    )_)|/    )_)"
  echo "                   by aMiscreant   "
  echo -e "${YELLOW}     PWN AUTOMATION SUITE — Born to Break 💣${NC}"
  echo
}

main_menu() {
  banner
  echo -e "${GREEN}Select a Module:${NC}"
  echo " 1) 💥 Smash'n Grab Wi-Fi (besside-ng, caps, crunch)"
  echo " 2) 🎯 Exploit Hunt (nmap, nuclei, custom fuzzers)"
  echo " 3) 🧠 PostX (shells, persistence, Mimikatz)"
  echo " 4) 🧪 Payload Forge (build/dropper toolkits)"
  echo " 5) 📡 Bluetooth Exploiter"
  echo " 6) 🛠️  SQLmap PWN Wrapper"
  echo " 7) ⚙️  System Settings (RAM tricks, GPU support)"
  echo " 8) 📜 View Logs"
  echo " 9) 💀 Exit"
  echo
  read -p "Choose an option [1-9]: " choice

  case $choice in
    1) bash core/wifi_attack.sh ;;
    2) bash core/exploit_fuzzer.sh ;;
    3) bash core/post_exploit_tools.sh ;;
    4) bash core/payload_forge.sh ;;
    5) bash core/exploit_bluetooth.sh ;;
    6) bash core/exploit_sqlmap.sh ;;
    7) bash utils/sys_config.sh ;;
    8) cat logs/lz_activity.log | less ;;
    9) echo -e "${RED}Goodbye, Operator.${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid selection, try again.${NC}"; sleep 1; main_menu ;;
  esac
}

main_menu
