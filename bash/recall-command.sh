#!/bin/bash
#
# recall-command
# allows one to recall commands
#
# nodes:
#   add command;description the above script array

commands=()
commands+=("ctl + R;Search history")
commands+=("history | grep ?;Search for specific history item (replace ? with desired term)")
commands+=("create basic container;lxc-create-basic-container.sh CONTAINER_NAME IP /projects/dir")
commands+=("create UBUNTU container;lxc-create-basic-ubuntu-container.sh CONTAINER_NAME IP /projects/dir")

COLOUR_DEFAULT='\033[39m'
COLOUR_COMMAND='\033[36m'
COLOUR_DESCRIPTION='\033[33m'

command_max_padding=0
description_max_padding=0

determine_command_and_description_padding() {
  for i in "${commands[@]}"; do
    IFS=';' read command description <<< $i
    command_len=${#command}
    description_len=${#description}
    if (( command_len > command_max_padding )); then let command_max_padding=command_len; fi
    if (( description_len > description_max_padding )); then let description_max_padding=description_len; fi
  done
}

display_command() {
  IFS=';' read command description <<< $1
  printf "${COLOUR_COMMAND}%${command_max_padding}s ${COLOUR_DEFAULT}| ${COLOUR_DESCRIPTION}%s${COLOUR_DEFAULT}\n" "$command" "$description"
}

display_break() {
  printf -v command_break '%*s' "$command_max_padding"
  printf -v description_break '%*s' "$description_max_padding"
  echo "${command_break// /=}===${description_break// /=}"
}

determine_command_and_description_padding

# output
clear
printf "\n\033[34mcommand-recall\e[0m - command lookup reference\n\n"

display_break
printf "%${command_max_padding}s | Description\n" "Command"
display_break

for i in "${commands[@]}"; do
  display_command "$i"
done

display_break

echo
