#!/usr/bin/env bash
set -e
set -o pipefail

home="/home/pz"

cd "$home" || exit
if [ -f "${home}/mod_config.env" ]; then
    source "${home}/mod_config.env"
else
    printf "Please create %s, and set STEAMUSER, STEAMPASS, CRYPTKEY and WSCOLLECTIONID\n" "${home}/mod_config.env"
fi
# get my decrypt key
if [ -z "${CRYPTKEY}" ]; then
    printf "Error! Could not find my decryption key for stored passwords.\n"
    exit 1
fi

if [ -n "$WSCOLLECTIONID" ]; then
  mapfile -t WS_IDS_RAW < <(curl -s https://steamcommunity.com/sharedfiles/filedetails/?id="${WSCOLLECTIONID}" | grep "https://steamcommunity.com/sharedfiles/filedetails/?id=" | grep workshopItemPreviewHolder | grep -Eoi '<a [^>]+>' | grep -Eo 'href="[^\"]+"' | awk -F'"' '{ print $2 }'|awk -F'=' '{ print $2 }'| awk '!x[$0]++')
  WS_IDS=()
  while IFS= read -r -d '' x; do
    WS_IDS+=("$x")
  done < <(printf "%s\0" "${WS_IDS_RAW[@]}" | sort -uk2 | sort -n | cut -f2-)
fi

if [[ -z $WS_IDS ]]; then
    printf "Workshop mod IDs not configured, please set WS_IDS in the mod_config.env\n"
    exit 1
elif [ -z "${STEAMUSER}" ]; then
    printf "STEAMUSER is not set, please configure in mod_config.env"
    exit 1
elif [ -z "${STEAMPASS}" ]; then
    printf "STEAMPASS is not set, please configure in mod_config.env"
    exit 1
fi

STEAMPASS_decrypted=$(echo "${STEAMPASS}" | openssl enc -a -d -aes-256-cbc -md md5 -pass pass:"${CRYPTKEY}")
ALL_WSIDS=""
ALL_MODIDS=""
for workshop_item in "${WS_IDS[@]}"; do
    if ! [[ ${workshop_item} == ?(-)+([0-9]) ]]; then break; fi
    modname="$(curl -s https://steamcommunity.com/sharedfiles/filedetails/?id="${workshop_item}" | grep "<title>" | sed -e 's/<[^>]*>//g' | awk -F "::" '{print $2}')"
    modname_clean=$(echo "$modname" | dos2unix)
    counter=1
    printf "\n---|  DOWNLOADING : %s |-------------------------------\n" "$modname_clean"
    until ./steamcmd.sh +force_install_dir "${home}/Zomboid/" +login "${STEAMUSER}" "${STEAMPASS_decrypted}" +workshop_download_item 108600 "${workshop_item}" validate +quit; do
        printf "Error Downloading %s. Will try again \n" "$modname_clean"
        counter=$((counter+1))
        if ((counter > 4)); then
            break
        fi
    done
    modIDs="$(grep -rh --include=mod.info -oP 'id=\K[a-zA-Z0-9-_]+' "${home}/Zomboid/steamapps/workshop/content/108600/${workshop_item}/" | sort -u | tr '\n' ';')"
    printf "\n---|  DOWNLOADED : %s | %s | %s  |-------------------------------\n" "$modname_clean" "${workshop_item}" "${modIDs}"
    ln -sf ${home}/Zomboid/steamapps/workshop/content/108600/${workshop_item}/mods/* /home/pz/Zomboid/mods/
    ALL_WSIDS=${ALL_WSIDS}${workshop_item}";"
    ALL_MODIDS=${ALL_MODIDS}${modIDs}
done
echo --- Remove unwanted mods from the following line before updating your server config :
echo Mods=${ALL_MODIDS}
echo --- FYI. Do not use it in your configuration unles you know what your are doing.
echo WorkshopItems=${ALL_WSIDS}
