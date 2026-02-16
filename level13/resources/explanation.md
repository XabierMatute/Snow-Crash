# 🚩 SnowCrash Level 13: Manipulación de UID con GDB

Este nivel presenta un binario con **SUID** que restringe su ejecución a un ID de usuario específico (UID 4242). Al no ser nosotros ese usuario, debemos realizar una "cirugía" en la memoria del programa para saltar la validación.

## 🔍 Análisis del Binario (`level13`)

Al intentar ejecutar el binario, recibimos un mensaje de error indicando que nuestro UID actual no es el esperado. Procedemos a analizar el código con GDB (`gdb ./level13` -> `disas main`):

### El Punto de Control (`getuid`)
En el desensamblado, identificamos el punto donde el programa consulta quiénes somos:
```asm
0x08048595 <+9>:  call   0x8048380 <getuid@plt>
0x0804859a <+14>: cmp    $0x1092,%eax ; 0x1092 en decimal es 4242
0x0804859f <+19>: je     0x80485cb <main+63>
```

### Lógica de la Vulnerabilidad
1.  **Llamada**: El programa llama a `getuid()`, que devuelve nuestro ID de usuario (level13 = 2013) y lo guarda en el registro **`eax`**.
2.  **Comparación**: Compara el contenido de `eax` con el valor hexadecimal **`0x1092`** (4242).
3.  **Salto**: Si son iguales (`je`), salta a la función que imprime la flag. Si no, imprime el error y termina.

---

## 🛠️ Metodología de Explotación

Como no podemos cambiar nuestro UID real, usaremos **GDB** para interceptar la ejecución justo después de la llamada a `getuid()` y cambiaremos manualmente el valor del registro `eax`.

### Paso 1: Cargar el binario en GDB
```bash
gdb ./level13
```

### Paso 2: Establecer el Breakpoint
Ponemos un punto de interrupción justo en la instrucción de comparación:
```gdb
(gdb) break *0x0804859a
```

### Paso 3: Ejecutar y Manipular
Iniciamos el programa y, cuando se detenga, forzamos el valor de `eax`:
```gdb
(gdb) run
(gdb) set $eax = 4242
(gdb) continue
```

---

## 🚀 Obtención de la Flag

1.  **Continuar ejecución**: Tras cambiar el registro, el comando `continue` hará que el programa realice la comparación.
2.  **Validación superada**: Como ahora `eax` vale 4242, la condición `cmp` será verdadera y el programa saltará a la función de éxito.
3.  **Resultado**: El programa imprimirá el token de la flag directamente en la consola de GDB.

---

## 🛡️ Prevención y Mitigación

*   **No confiar en comprobaciones de cliente**: Las validaciones de UID dentro del código son fácilmente saltables con un depurador.
*   **Permisos de Sistema de Archivos**: En lugar de verificar el UID por código, el binario debería intentar acceder a un recurso que solo el usuario 4242 tenga permiso para leer (mediante el sistema de archivos de Linux).
*   **Ofuscación/Protección**: El uso de técnicas de anti-debugging podría dificultar el uso de GDB, aunque no lo hace imposible para un atacante decidido.
