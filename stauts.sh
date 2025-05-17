#!/bin/bash

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_RESET='\033[0m'

while true; do
    echo -e "${COLOR_YELLOW}"
    echo "Systemd User Service Inspector"
    echo -e "${COLOR_RESET}"
    echo "1) Show active services and dependencies"
    echo "2) Check status of a service"
    echo "3) Show recent logs for a service"
    echo "4) Show custom user service overrides"
    echo "5) Show running services"
    echo "6) Show failed or inactive services"
    echo "7) Find and manage broken services"
    echo "8) Start or stop a service"
    echo "9) Exit"
    echo
    read -rp "Select an option [1-9]: " choice

    case "$choice" in
    1)
        echo -e "\n${COLOR_YELLOW}### Active User Services and Dependencies ###${COLOR_RESET}"
        systemctl --user list-dependencies default.target --plain --no-pager
        ;;
    2)
        read -rp $'\nEnter the service name (e.g., pipewire.service): ' service
        echo -e "\n${COLOR_GREEN}-- $service --${COLOR_RESET}"
        systemctl --user status "$service" --no-pager --full | grep -E "Loaded:|Active:|Main PID:|Started|failed" || echo "Not found."
        ;;
    3)
        read -rp $'\nEnter the service name (e.g., wireplumber): ' service
        echo -e "\n${COLOR_YELLOW}### Recent Logs for $service ###${COLOR_RESET}"
        journalctl --user -u "$service" --no-pager -n 50 2>/dev/null || echo "No entries found."
        ;;
    4)
        echo -e "\n${COLOR_YELLOW}### Custom User Service Overrides (if any) ###${COLOR_RESET}"
        find ~/.config/systemd/user/ -name '*.service' -exec echo "{}:" \; -exec cat {} \; 2>/dev/null || echo "No custom overrides found."
        ;;
    5)
        echo -e "\n${COLOR_YELLOW}### Running Services (User) ###${COLOR_RESET}"
        systemctl --user list-units --type=service --state=running --no-pager
        ;;
    6)
        echo -e "\n${COLOR_YELLOW}### Failed/Inactive Services (User) ###${COLOR_RESET}"
        systemctl --user list-units --type=service --state=failed,inactive --no-pager

        echo -e "\n${COLOR_YELLOW}### Services with Missing Units (not-found) ###${COLOR_RESET}"
        systemctl --user list-units --type=service --no-pager | grep "not-found" || echo "None."

        echo -e "\n${COLOR_YELLOW}Note:${COLOR_RESET} Inactive services may simply not be in use currently."
        echo "  - Example: 'gpg-agent.service' runs on demand."
        echo "  - KDE autostart apps often appear 'inactive' after startup."
        ;;
    7)
        echo -e "\n${COLOR_YELLOW}### Checking for broken or obsolete user service overrides... ###${COLOR_RESET}"
        broken_services=0
        find ~/.config/systemd/user/ -name '*.service' | while read -r file; do
            unit=$(basename "$file")
            if ! systemctl --user status "$unit" &>/dev/null; then
                echo -e "${COLOR_RED}Stale service: $unit${COLOR_RESET}"
                echo "  → File: $file"
                read -rp "    Delete this file? [y/N]: " del
                if [[ "$del" == "y" || "$del" == "Y" ]]; then
                    rm -v "$file"
                    ((broken_services++))
                fi
            fi
        done
        if [[ $broken_services -eq 0 ]]; then
            echo -e "${COLOR_GREEN}✔ No broken service overrides found.${COLOR_RESET}"
        fi
        ;;
    8)
        read -rp $'\nEnter the service name (e.g., pipewire.service): ' service
        echo -e "${COLOR_YELLOW}Choose action:${COLOR_RESET}"
        echo "  1) Start"
        echo "  2) Stop"
        echo "  3) Restart"
        echo "  4) Enable"
        echo "  5) Disable"
        echo "  6) Back"
        read -rp "Select action [1-6]: " action

        case "$action" in
        1) systemctl --user start "$service" && echo "Started $service." ;;
        2) systemctl --user stop "$service" && echo "Stopped $service." ;;
        3) systemctl --user restart "$service" && echo "Restarted $service." ;;
        4) systemctl --user enable "$service" && echo "Enabled $service." ;;
        5) systemctl --user disable "$service" && echo "Disabled $service." ;;
        *) echo "Returning to main menu..." ;;
        esac
        ;;
    9)
        echo -e "\n${COLOR_GREEN}Goodbye!${COLOR_RESET}"
        exit 0
        ;;
    *)
        echo -e "${COLOR_RED}Invalid option. Please enter a number from 1 to 9.${COLOR_RESET}"
        ;;
    esac

    echo -e "\n${COLOR_YELLOW}Press [Enter] to continue...${COLOR_RESET}"
    read -r
done
