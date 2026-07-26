# Publicar StepsTracker de forma automatizada

La automatización recomendada para este proyecto es **Xcode Cloud**. La app ya
usa firma automática y está conectada a GitHub, de modo que Xcode Cloud puede
archivar y distribuir sin copiar certificados, perfiles o claves privadas al
repositorio.

El esquema compartido `StepsTracker` y `ci_scripts/ci_pre_xcodebuild.sh` forman
parte del repositorio. En cada acción de archivado, el script solo valida el
número de build de Cloud; Xcode Cloud asigna ese número al archive sin modificar
el proyecto. La versión comercial se mantiene en el commit de la versión.

## Configuración única en Xcode Cloud

1. Abre `StepsTracker.xcodeproj` con una cuenta con rol **Admin** o **App
   Manager** tanto en Apple Developer como en App Store Connect.
2. En Xcode, abre el **Report navigator** (`⌘9`), pulsa el botón de la nube y
   selecciona **Get Started**. Autoriza entonces el acceso al repositorio
   `JoseMMA88/StepsTracker`.
3. Crea el flujo **Validation**:
   - Inicio: cambios en pull requests hacia `master`.
   - Acción: `Test`, esquema `StepsTracker`, destino de iPhone actual.
   - Sin distribución.
4. Crea el flujo **TestFlight**:
   - Inicio: cambio de etiqueta con el patrón `v*` y/o inicio manual.
   - Acción: `Archive`, esquema `StepsTracker`, configuración `Release`.
   - Postacción: distribuir a los testers internos de TestFlight.
5. En la pestaña **Xcode Cloud** de App Store Connect, confirma que los builds
   se numeran desde un valor válido. Para iOS, una nueva versión comercial puede
   volver a usar un build inferior; cada combinación versión/build debe ser
   única.
6. Protege `master` en GitHub para exigir el flujo **Validation** antes de
   fusionar.

No configures un envío automático a revisión. Tras el procesado de Apple, una
persona debe comprobar la ficha, las notas, la clasificación por edad, la
privacidad y seleccionar el build. Esa puerta humana evita publicar por error
una etiqueta o una versión incompleta.

## Preparar una versión

El número de versión comercial se prepara en local y se confirma en Git antes
de crear la etiqueta:

```sh
./scripts/prepare_release.sh --version 1.2.0 --build 1
./scripts/validate_release.sh
git add StepsTracker.xcodeproj/project.pbxproj
git commit -m "Prepare 1.2.0"
git tag v1.2.0
git push origin master --tags
```

La etiqueta inicia el flujo de TestFlight. Xcode Cloud asigna su número de
ejecución al build distribuido, por lo que el build publicado puede ser distinto
del valor de preparación. El commit, no la copia local, es la fuente de la
versión distribuida.

## Respaldo local a TestFlight

`scripts/release_to_testflight.sh` ofrece el mismo archive y subida desde un
Mac que tenga una identidad **Apple Distribution** y perfiles válidos de la
app. Se usa solo desde un árbol de trabajo limpio y ya confirmado:

```sh
export ASC_KEY_ID="tu-key-id"
export ASC_ISSUER_ID="tu-issuer-id"
mkdir -p "$HOME/.appstoreconnect/private_keys"
# Guarda ahí AuthKey_<tu-key-id>.p8, con permisos restringidos.
./scripts/release_to_testflight.sh
```

No añadas el fichero `.p8`, certificados ni perfiles a Git. El script valida el
IPA y lo sube a App Store Connect con la clave API; Apple todavía necesita
procesar el build antes de que aparezca en TestFlight.

Para verificar los requisitos locales sin crear archivos ni subir nada:

```sh
./scripts/release_to_testflight.sh --dry-run
```

## Límites intencionados

La automatización no crea un commit, etiqueta, captura ni envía la versión a
App Review. Apple puede bloquear un build durante el procesado y la versión
requiere información editorial y de cumplimiento que merece una última
validación humana. Una vez validado el build en TestFlight, selecciona el build
en App Store Connect y envíalo a revisión.
