# Calculadora Flask con pipeline de CI

Aplicación web de calculadora en Python/Flask con un pipeline de Integración Continua en GitHub Actions: formato, linters, pruebas unitarias, de componente y de aceptación, análisis en SonarCloud y publicación de la imagen Docker en Docker Hub.

- **Repositorio:** https://github.com/jalopezg4/taller2-cicd
- **SonarCloud:** https://sonarcloud.io/project/overview?id=jalopezg4_taller2-cicd
- **Docker Hub:** https://hub.docker.com/r/jenniferlopez2005/taller2-cicd

## Integrantes

Los nombres están en el mismo orden que la variable `AUTOR` de `app/calculadora.py`.

| # | Nombre completo | Usuario de GitHub |
|---|-----------------|-------------------|
| 1 | Jennifer Andrea Lopez Gomez | [@jalopezg4](https://github.com/jalopezg4) (**propietaria del repositorio**) |
| 2 | Santiago Alexander cardenas Laverde | [@AIDouglas](https://github.com/AIDouglas) |
| 3 | Danna Salazar Cardenas | [@dannx109](https://github.com/dannx109) |
| 4 | Samuel Cadavid Zapata | [@scadavidzea](https://github.com/scadavidzea) |

## Evidencias

- **Pull Request de la sección 9:** https://github.com/jalopezg4/taller2-cicd/pull/1
- **Ejecución fallida por el error intencional:** https://github.com/jalopezg4/taller2-cicd/actions/runs/43599326307/job/132460484388?pr=1
- **Ejecución exitosa tras la corrección (en el PR):** https://github.com/jalopezg4/taller2-cicd/actions/runs/43599401565

## Preguntas

### 1. ¿Qué ventajas tiene usar un pipeline de CI?

- **Los errores salen rapidito.** Cada vez que alguien sube algo, las pruebas corren solas. Si uno daña algo se entera ahí mismo y sabe qué cambio fue, no una semana después. Nos pasó con el error de `restar`: el pipeline lo atajó antes de que llegara a `main`.
- **Todos jugamos con las mismas reglas.** Black, los linters, la cobertura mínima del 80 % y SonarCloud revisan igual el código de todos, entonces no depende de que a alguien se le olvide correr las pruebas.
- **`main` siempre sirve.** Con la rama protegida solo entra código que pasó todo, entonces la imagen que queda en Docker Hub es una versión probada.
- **Se acabó el "en mi pc sí funciona".** Todo corre en una máquina limpia con las mismas versiones de las librerías, y queda el historial de cada ejecución con sus reportes.

### 2. ¿Cuál es la diferencia entre una prueba unitaria, una de componente y una de aceptación?

La app es una calculadora web: uno mete dos números, escoge la operación (sumar, restar, multiplicar o dividir) y le muestra el resultado o un mensaje si algo está mal, por ejemplo si divide por cero.

- **Unitaria:** prueba una función sola, sin servidor ni navegador. Por ejemplo, que `restar(5, 2)` dé `3` o que `dividir(1, 0)` lance el error.
- **De componente:** prueba la app de Flask completa (ruta, formulario y plantilla) con el cliente de pruebas de Flask, sin levantar servidor. Por ejemplo, mandar `6 / 0` por el formulario y que la página diga "No se puede dividir por cero".
- **De aceptación:** prueba como si fuera un usuario de verdad. Selenium abre Chrome contra el contenedor, escribe `2` y `3`, le da "Sumar" y revisa que salga `Resultado: 5.0`.

### 3. ¿Qué hace cada step del workflow?

1. **Checkout:** baja el código con todo el historial, que SonarCloud lo necesita para saber qué es código nuevo.
2. **Set up Python:** instala Python 3.13, la misma versión de la imagen Docker.
3. **Install dependencies:** instala las librerías con versiones fijas y verificadas por hash, para que siempre sean las mismas.
4. **Black:** revisa que el código esté bien formateado. Si no, falla.
5. **Pylint y Flake8:** revisan el código y sacan reportes que después se le pasan a SonarCloud.
6. **Pruebas unitarias y de componente:** corren con cobertura. Si una falla o la cobertura queda por debajo del 80 %, se cae el pipeline.
7. **Build Docker image:** arma la imagen con el SHA del commit como etiqueta.
8. **Start container:** prende el contenedor y espera a que la app responda.
9. **Pruebas de aceptación:** corren las de Selenium contra ese contenedor.
10. **Logs del contenedor:** si algo falla, muestra los logs para saber qué pasó.
11. **Subir reportes:** guarda los reportes de pruebas, cobertura y linters como artefactos.
12. **SonarCloud:** analiza el código y espera el Quality Gate. Si no pasa, falla.
13. **Login y push a Docker Hub:** solo cuando es push a `main`. Sube la misma imagen que se probó, con la etiqueta del SHA y `latest`.

### 4. ¿Qué problemas tuvimos y cómo los resolvimos?

- **Santiago Alexander cardenas Laverde:**
  - Las pruebas de Selenium pasaban en local pero en el pipeline fallaban casi todas. Resulta que Gunicorn prende 4 workers y cada uno se inventaba su propia clave secreta, entonces el token del formulario que daba uno no le servía al otro. Lo arreglamos con `--preload` para que todos usen la misma.
  - SonarCloud fallaba porque tenía prendido el análisis automático y a la vez lo estábamos corriendo desde el pipeline. Tocó apagar el automático en la configuración del proyecto.
  - Sonar marcaba issues de seguridad porque las librerías no estaban bien bloqueadas. Generamos los `requirements` con hashes usando `uv` y ahora se instalan con `--require-hashes`.
  - Aprendí que en GitHub uno no puede aprobar su propio PR, toca que lo apruebe otro del equipo.
- **Jennifer Andrea Lopez Gomez:** _(por completar)_
- **Danna Salazar Cardenas:** _(por completar)_
- **Samuel Cadavid Zapata:** _(por completar)_

### 5. ¿Por qué construir la imagen, probarla y publicar esa misma, y no solo probar el código?

Porque lo que uno entrega es la imagen, no el código suelto. Al probarla se revisa también el Dockerfile, las librerías y cómo arranca la app con Gunicorn. El problema del token con los workers solo pasaba dentro del contenedor, y con las pruebas unitarias nunca lo hubiéramos visto. Además, como se sube exactamente la imagen que se probó, no hay sorpresas de que al volverla a construir cambie algo. Y como lleva el SHA del commit, uno sabe qué código tiene cada imagen y puede volver a una anterior si algo sale mal.

### 6. Sobre el PR de la sección 9

**Pruebas que agregamos** (en `tests/test_calculadora.py`):

- `test_sumar_decimales`: revisa que `0.1 + 0.2` dé más o menos `0.3` y que `1.5 + 2.25` dé `3.75`. Atrapa si `sumar` redondea o pierde los decimales.
- `test_multiplicar_dos_negativos`: revisa que `-2 × -3` dé `6` y que `-10 / -2` dé `5`. Atrapa si `multiplicar` o `dividir` se equivocan con los signos.

**El error a propósito:** cambiamos `restar` para que sumara (`a + b`).

- **Qué falló:** el step de pruebas unitarias y de componente. Se cayeron `test_restar` (daba `7` en vez de `3`) y `test_index_post_restar` (la página mostraba `8.0` en vez de `2.0`).
- **Qué no corrió:** ni se construyó la imagen, ni corrieron las pruebas de aceptación, ni SonarCloud, ni el push a Docker Hub.
- **Por qué no llegó a `main` ni a Docker Hub:** la rama `main` está protegida. Pide PR, una aprobación y que `build-and-test` pase. Como falló, GitHub no dejó hacer merge, y tampoco se puede hacer push directo (lo intentamos y lo rechazó). Además, la imagen solo se sube cuando es push a `main` y todo pasó. Cuando corregimos `restar` el pipeline quedó en verde, @dannx109 y @scadavidzea aprobaron y se hizo el merge.
