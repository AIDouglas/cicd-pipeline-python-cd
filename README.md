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

### 1. ¿Qué ventajas le proporciona a un proyecto el uso de un pipeline de CI?

1. **Detección temprana de errores.** Cada push y cada Pull Request ejecutan las pruebas de forma automática. Un error se descubre minutos después de escribirlo, cuando todavía es barato de corregir y se sabe exactamente qué cambio lo introdujo. Lo vimos con el error intencional en `restar`: el pipeline falló antes de que el cambio llegara a `main`.
2. **Calidad consistente y objetiva.** Black, Pylint, Flake8, el umbral de cobertura del 80 % y el Quality Gate de SonarCloud aplican las mismas reglas a todos los integrantes. La calidad no depende de que alguien recuerde revisar el formato o correr las pruebas.
3. **`main` siempre desplegable.** Junto con la protección de rama, solo se integra código que pasó todas las verificaciones. Por eso la imagen publicada en Docker Hub siempre corresponde a una versión probada.
4. **Builds reproducibles.** El pipeline corre en una máquina limpia con dependencias fijadas y verificadas por hash. Esto elimina el "en mi máquina funciona" y deja un historial auditable de cada ejecución con sus reportes.

### 2. ¿Cuál es la diferencia entre una prueba unitaria, una prueba de componente y una prueba de aceptación?

La aplicación es una calculadora web. El módulo `app/calculadora.py` contiene las funciones `sumar`, `restar`, `multiplicar` y `dividir`. El módulo `app/app.py` es una aplicación Flask que muestra un formulario con dos números y una operación, llama a la función correspondiente y muestra el resultado o un mensaje de error.

- **Prueba unitaria:** verifica una sola función aislada, sin servidor ni navegador. Ejemplo (`tests/test_calculadora.py`): `dividir(1, 0)` lanza `ZeroDivisionError` y `restar(5, 2) == 3`.
- **Prueba de componente:** verifica la aplicación Flask como un componente completo (ruta, formulario y plantilla) usando el cliente de pruebas de Flask, sin levantar un servidor real. Ejemplo (`tests/test_app.py`): un `POST /` con `num1=6`, `num2=0` y `operacion=dividir` responde 200 y la página contiene `Error: No se puede dividir por cero`.
- **Prueba de aceptación:** verifica el sistema desde el punto de vista del usuario, sobre la aplicación desplegada. Ejemplo (`tests/test_acceptance_app.py`): Selenium abre Chrome headless contra el contenedor Docker, escribe `2` y `3`, elige "Sumar", pulsa "Calcular" y comprueba que el `<h2>` muestra exactamente `Resultado: 5.0`.

### 3. Describe brevemente qué hace cada uno de los *steps* principales de tu workflow de GitHub Actions

| Step | Qué hace y por qué |
|------|--------------------|
| **Checkout** | Descarga el código del commit con el historial completo (`fetch-depth: 0`), que SonarCloud usa para identificar el código nuevo. |
| **Set up Python** | Instala Python 3.13, la misma versión de la imagen Docker. |
| **Install dependencies** | Instala `requirements-dev.txt` con `--require-hashes` y `--only-binary=:all:`. Usa versiones bloqueadas y verificadas por hash, y no ejecuta scripts de instalación. |
| **Run Black** | Verifica (`--check`) que el código de `app` tenga el formato de Black. Si no lo tiene, falla el pipeline. |
| **Run Pylint / Run Flake8** | Analizan el código y generan `pylint-report.txt` y `flake8-report.txt`, que luego se envían a SonarCloud. |
| **Run Unit and Component Tests** | Ejecuta pytest (sin las pruebas de aceptación) con cobertura. Falla si alguna prueba falla o si la cobertura baja del 80 %. Genera `coverage.xml` para SonarCloud. |
| **Build Docker image** | Construye la imagen etiquetada con el SHA del commit. |
| **Start container** | Arranca la imagen recién construida y espera hasta 30 s a que la aplicación responda en el puerto 8000. |
| **Run Acceptance Tests** | Ejecuta las pruebas de Selenium contra el contenedor, es decir, contra el artefacto que se va a publicar. |
| **Show container logs on failure** | Si algo falla, muestra los logs del contenedor para diagnosticar. |
| **Upload Test Reports Artifacts** | Siempre sube los reportes (cobertura HTML, reportes de pytest y de los linters) como artefactos de la ejecución. |
| **SonarCloud Scan** | Analiza el código con la cobertura y los reportes de los linters, y espera el Quality Gate. Si no pasa, falla el pipeline. |
| **Login to Docker Hub** | Solo en push a `main`: inicia sesión con el usuario (variable) y el token (secreto). |
| **Push Docker image** | Solo en push a `main`: etiqueta la misma imagen probada como `latest` y publica las etiquetas `<sha>` y `latest`. |

### 4. ¿Qué problemas o dificultades encontraron al implementar este taller?

- **Santiago Alexander cardenas Laverde:**
  - *Pruebas de aceptación fallando en el contenedor.* En el pipeline fallaban 5 de las 6 pruebas de Selenium por timeout, aunque localmente funcionaban. La causa: Gunicorn arranca 4 workers y cada uno generaba su propio `SECRET_KEY` aleatorio, de modo que el token CSRF firmado por un worker era rechazado (400) por otro. Lo solucionamos con `gunicorn --preload`: la aplicación se carga una sola vez antes de crear los workers y todos comparten la misma clave.
  - *SonarCloud fallaba con "Automatic Analysis is enabled".* SonarCloud no permite usar a la vez el análisis automático y el análisis desde CI. Desactivamos Automatic Analysis en *Administration → Analysis Method*.
  - *Issues de seguridad S8541/S8544 en SonarCloud.* Pedían instalar dependencias bloqueadas y verificadas. Generamos `requirements.txt` y `requirements-dev.txt` con hashes usando `uv pip compile --generate-hashes` a partir de `requirements.in` y `requirements-dev.in`, e instalamos con `--require-hashes` en el workflow y en el Dockerfile.
  - *Aprendizaje sobre la protección de rama:* GitHub no permite que el autor de un Pull Request lo apruebe, así que la aprobación tuvo que venir de otro integrante.
- **Jennifer Andrea Lopez Gomez:** _(por completar)_
- **Danna Salazar Cardenas:** _(por completar)_
- **Samuel Cadavid Zapata:** _(por completar)_

### 5. ¿Qué ventajas ofrece construir la imagen Docker, ejecutar las pruebas de aceptación sobre ella y publicar esa misma imagen, en lugar de solo validar el código?

- **Se prueba lo que se entrega.** Las pruebas unitarias validan el código, pero no el artefacto final. Probar la imagen valida también el Dockerfile, las dependencias de ejecución, el usuario no root, Gunicorn y la configuración real. Nuestro error de CSRF con varios workers de Gunicorn solo aparecía dentro del contenedor y las pruebas unitarias y de componente nunca lo habrían detectado.
- **Sin diferencias entre lo probado y lo publicado.** Como se publica exactamente la imagen probada (la misma etiqueta `<sha>`, reetiquetada como `latest`), no hay riesgo de que una reconstrucción posterior traiga otra versión de una dependencia o de la imagen base.
- **Trazabilidad.** Cada imagen en Docker Hub lleva el SHA del commit, así que se sabe exactamente qué código contiene y qué ejecución del pipeline la validó, y se puede volver a una versión anterior fácilmente.

### 6. Sobre el Pull Request de la sección 9

**Pruebas agregadas** (en `tests/test_calculadora.py`):

- `test_sumar_decimales`: comprueba `sumar(0.1, 0.2) ≈ 0.3` y `sumar(1.5, 2.25) ≈ 3.75` con `pytest.approx`. Detectaría que `sumar` trunque o redondee los decimales (por ejemplo, convertir a `int`) o que se compare mal con flotantes.
- `test_multiplicar_dos_negativos`: comprueba `multiplicar(-2, -3) == 6` y `dividir(-10, -2) == 5.0`. Detectaría un error en la regla de signos, por ejemplo que `multiplicar` o `dividir` devuelvan un valor negativo, ignoren el signo o usen valores absolutos de forma incorrecta.

**Error intencional:** se cambió `restar` para que devolviera `a + b` en lugar de `a - b`.

- **Step que falló:** `Run Unit and Component Tests`. Fallaron `test_calculadora.py::test_restar` (`assert 7 == 3`) y `test_app.py::test_index_post_restar` (la página mostraba `Resultado: 8.0` en lugar de `2.0`).
- **Steps que no se ejecutaron:** `Build Docker image`, `Start container`, `Run Acceptance Tests`, `SonarCloud Scan`, `Login to Docker Hub` y `Push Docker image`.
- **Cómo se evitó que el error llegara a `main` y a Docker Hub:** la regla `proteger-main` exige un Pull Request, 1 aprobación y que el check `build-and-test` pase. Como el job falló, GitHub bloqueó el merge, y nadie podía saltarse la regla con un push directo (lo comprobamos: el push directo fue rechazado con `GH013: Repository rule violations`). Además, la publicación en Docker Hub solo ocurre en push a `main` y después de que pasen todos los steps anteriores, así que una imagen con el error nunca se habría publicado. Tras corregir `restar`, el pipeline volvió a verde, el PR fue aprobado por @dannx109 y @scadavidzea, y se integró.
