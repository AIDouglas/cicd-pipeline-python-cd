# Dockerfile
# Usa una imagen base oficial de Python. Elige una versión específica para consistencia.
FROM python:3.13-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia solo el archivo de requerimientos primero para aprovechar el cache de Docker
COPY requirements.txt .

# Instala solo las dependencias de ejecución (Flask y Gunicorn)
# Usa --no-cache-dir para reducir el tamaño de la imagen
# --require-hashes verifica cada paquete contra el hash fijado en requirements.txt
RUN pip install --no-cache-dir --only-binary=:all: --require-hashes -r requirements.txt

RUN useradd --create-home appuser
USER appuser

# Copia el código de la aplicación (solo la carpeta app)
COPY app/ ./app/

# Expón el puerto en el que Gunicorn servirá la aplicación
# Gunicorn por defecto usa 8000, así que usaremos ese.
EXPOSE 8000

# Comando para ejecutar la aplicación usando Gunicorn cuando el contenedor inicie
# 'app.app:app' significa: del archivo app.py dentro del paquete app, usa la instancia 'app' de Flask.
# 'workers=4' es un ejemplo, ajusta según sea necesario.
# 'bind 0.0.0.0:8000' hace que Gunicorn escuche en todas las interfaces de red en el puerto 8000.
# --preload carga la app una sola vez antes de crear los workers, así todos
# comparten el mismo SECRET_KEY y el token CSRF es válido en cualquier worker.
CMD ["gunicorn", "--preload", "--workers=4", "--bind=0.0.0.0:8000", "app.app:app"]