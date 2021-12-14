# mod_installer.sh

Download mods from a collection and keep them in the same order.

Rely on your steam account to download the mods, and place them in the Zomboid/mods folder.
Generate the Mods= config, but you might need to remove a few mods, otherwise all optionnal/duplicate mods will be enabled.

Original work from https://github.com/michaelsstuff/Arma3-stuff/tree/22fde3f14590d0d52a2fb198334d250af20ebd34/mod-sync with modification to fit PZ needs.
Works with b41.60+

---

Create a cryptokey to store the passwords:

`< /dev/urandom hexdump -n 16 -e '4/4 "%08X" 1 "\n"'`

Encrypt your steampassword:

`echo "yourpassword" | openssl enc -a -e -aes-256-cbc -md md5 -pass pass:"${CRYPTKEY}"`

create a mod_config.env

```cfg
CRYPTKEY=""
STEAMUSER=""
STEAMPASS=""
WSCOLLECTIONID=
HOME=""
```

Instead of WSCOLLECTIONID you can also make a list yourself:

```cfg
WS_IDS=(xxxxxxxxxxx xxxxxxxxxxxx xxxxxxxxxxxxxx xxxxxxxxxx)
```

```bash
/home/pz/mod_installer.sh
```
