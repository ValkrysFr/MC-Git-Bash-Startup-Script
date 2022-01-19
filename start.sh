#!/bin/bash
# Obfuscation script to pull from Github and replace $variables
cd /home/container

# Declare variables
source ./key.secret # set secrets value

ENDER_RESET_TIME='0'
SERVER_MEMORY=1024
JAR_FILE='server.jar'
GIT_UPDATE=1

#------------------
# Begin Switches
#------------------
while [ "$#" -gt 0 ];
do
  case "$1" in
    -h|--help)
      # Display Help
      echo "Startup script for GitPaper server from Pterodactyl."
      echo
      echo "Syntax: script.sh [-e|sm|jf|gu]"
      echo "options:"
      echo "e   | --ender           Define day of the week to reset ender world. Set 0 to disable."
      echo "sm  | --server-memory   Define server max memory."
      echo "jf  | --jar-file        Jar file name to execute."
      echo "gu  | --git-update      Need to pull repo at startup ?"
      echo
      exit 1
      ;;

    -e|--ender)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        ENDER_RESET_TIME=$2
        shift
      else
        echo "Error in -e|--ender syntax. Script failed."
        exit 1
      fi
      ;;

    -sm|--server-memory)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        SERVER_MEMORY=$2
        shift
      else
        echo "Error in -hs|--heap-size syntax. Script failed."
        exit 1
      fi
      ;;

    -jf|--jar-file)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        JAR_FILE=$2
        shift
      else
        echo "Error in -jf|--jar-file syntax. Script failed."
        exit 1
      fi
      ;;

    -gu|--git-update)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        GIT_UPDATE=$2
        shift
      else
        echo "Error in -ug|--update-git syntax. Script failed."
        exit 1
      fi
      ;;

    --) # End of all options.
      shift
      break
      ;;

    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;

    '') # Empty case: If no more options then break out of the loop.
      break
      ;;

    *)  # Anything unrecognized
      echo "The value "$1" was not expected. Script failed."
      exit 1
      ;;
  esac

  shift
done

#------------------
# Pull from Github
#------------------
if [[ $GIT_UPDATE == 1 ]]; then
	git reset --hard
	git pull --recurse-submodules
	git submodule update --init --recursive --force
fi

#------------------
# Deobfuscation
#------------------
echo "Starting to deobfuscate files..."
for i in $(find . -regextype posix-basic -regex '.*/.\{1,13\}.\(yml\|txt\|menu\|properties\|conf\|json\)');
do
	for key in "${!secret_key[@]}"
	do
	  sed -i "s|\$$key|${secret_key[$key]}|g" $i
	done
done
echo "Deobfuscation complete."

#------------------
# Reset end dimension
#------------------
if [[ $ENDER_RESET_TIME > 0 && $(find . -maxdepth 1 -type d -name '*_the_end') ]]; then
	if [[ $(date +%u) = $ENDER_RESET_TIME ]]; then
	  echo "Time to reset end dimension."
	  ENDER_WORLD=$(find . -maxdepth 1 -type d -name '*_the_end')
	  ENDER_REGION_DIR=$ENDER_WORLD/DIM1/region
	  rm $ENDER_WORLD/level.dat $ENDER_REGION_DIR/r.0.0.mca $ENDER_REGION_DIR/r.0.-1.mca $ENDER_REGION_DIR/r.-1.0.mca $ENDER_REGION_DIR/r.-1.-1.mca
	else
	  echo "Not time to reset end dimension."
	fi
fi

#------------------
# Java arguments
#------------------
if (($SERVER_MEMORY < 12000)); then
  G1NewSizePercent=30
  G1MaxNewSizePercent=40
  G1HeapRegionSize=8
  G1ReservePercent=20
  InitiatingHeapOccupancyPercent=15
else
  G1NewSizePercent=40
  G1MaxNewSizePercent=50
  G1HeapRegionSize=16
  G1ReservePercent=15
  InitiatingHeapOccupancyPercent=20
fi

#------------------
# Java startup
#------------------
echo "Starting server..."
java -Xms${SERVER_MEMORY}M -Xmx${SERVER_MEMORY}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=${G1NewSizePercent} -XX:G1MaxNewSizePercent=${G1MaxNewSizePercent} -XX:G1HeapRegionSize=${G1HeapRegionSize}M -XX:G1ReservePercent=${G1ReservePercent} -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=${InitiatingHeapOccupancyPercent} -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dterminal.jline=false -Dterminal.ansi=true -Dfile.encoding=UTF-8 -Dcom.mojang.eula.agree=true -jar $JAR_FILE nogui