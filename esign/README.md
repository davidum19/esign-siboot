# Instalador E-Sign para Open Minis

Lanzador de Davidios para ejecutar el instalador de E-Sign en Open Minis.

## Uso

Para iniciar la instalacion:

```sh
sh install.sh
```

Si no se indica una opcion, se utiliza `install`. Tambien se pueden ejecutar estas opciones:

- `check`: comprobar el entorno.
- `pair`: iniciar el emparejamiento.
- `developer-mode`: gestionar el modo de desarrollador.
- `sign-out`: cerrar la sesion.

Ejemplo:

```sh
sh install.sh check
```

## Que hace este instalador

- Comprueba que el sistema sea Linux ARM64.
- Verifica que esten disponibles `minis-bonjour`, `minis-open`, `sha256sum` y `wget`.
- Descarga el instalador E-Sign desde su servidor de distribucion.
- Utiliza XZ o GZIP si el dispositivo dispone de la herramienta necesaria; de lo contrario, descarga el archivo original.
- Verifica las sumas SHA-256 antes de ejecutar el archivo.
- Guarda el ejecutable verificado en `~/.e-sign/bin/e-sign-installer` y le envia la opcion seleccionada.

El ejecutable de E-Sign no se incluye en este repositorio. Se descarga desde su fuente de distribucion y se verifica antes de ejecutarlo.

## Version

- Instalador E-Sign: 0.2.2
- Compilacion: 24
- Arquitectura: aarch64
- Lanzador: Davidios
