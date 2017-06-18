#!/bin/bash
logger "ACPI [lid]: START"

getXuser() {
    Xtty=$(</sys/class/tty/tty0/active)
    Xpid=$(pgrep -t $Xtty -f /usr/bin/X)

    Xenv+=("$(egrep -aoz 'USER=.+' /proc/$Xpid/environ)")
    Xenv+=("$(egrep -aoz 'XAUTHORITY=.+' /proc/$Xpid/environ)")
    Xenv+=("$(egrep -aoz ':[0-9](.[0-9])?' /proc/$Xpid/cmdline)")

    Xenv=(${Xenv[@]#*=})

    (( ${#Xenv[@]} )) && {
        export XUSER=${Xenv[0]} XAUTHORITY=${Xenv[1]} DISPLAY=${Xenv[2]}
        su -c "$*" "$XUSER"
    }
}

# run slock only once
run_slock_once() {
  [[ `pidof /usr/bin/slock` == "" ]] && getXuser slock
}

grep -q closed /proc/acpi/button/lid/*/state
if [ $? = 0 ]
then
  # the lid is closing
  logger "ACPI [lid]: Lid closed"
  ONLINE="$(cat /sys/devices/platform/smapi/BAT0/state)"

  # If we are discharging then sleep otherwise blank the screen
  if [[ $ONLINE == "discharging" ]]; then
    logger "ACPI [lid]: Discharging... Entering sleep"
    run_slock_once
    sleep 2
    echo -n mem > /sys/power/state
  else
    logger "ACPI user: $user"
    logger "ACPI [lid]: Power connected blanking screen"
    run_slock_once
  fi
else
  # the lid is being opened
  logger "ACPI [lid]: Lid opened"
fi
