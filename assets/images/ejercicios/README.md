# Ilustraciones de ejercicios

Esta carpeta está vacía a propósito: por ahora **todos los ejercicios
muestran un placeholder** con su nombre. Las ilustraciones definitivas
entran en una versión posterior.

## Cómo agregar una

Deja el PNG con el **id del ejercicio** como nombre de archivo:

```
assets/images/ejercicios/<id>.png
```

Por ejemplo, para el ejercicio `rd-1` ("Pararse y sentarse de un banco"),
el archivo va como `rd-1.png`.

No hay que tocar código ni `pubspec.yaml`: `ExerciseModel.imagenAsset`
apunta por defecto a esa ruta, y `ExerciseImage` cae en el placeholder
solo mientras el archivo no exista. Los ids están en
`lib/data/repositories/exercise_repository.dart`.

> Este README existe para que la carpeta no quede vacía, porque
> `pubspec.yaml` la declara como directorio de assets.
