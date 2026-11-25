# Étape 1 : installer les dépendances
FROM public.ecr.aws/docker/library/python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Étape 2 : l’image finale, sans outils de build
FROM public.ecr.aws/docker/library/python:3.12-slim
WORKDIR /app
COPY --from=build /install /usr/local
COPY . .
RUN useradd --create-home appuser
USER appuser
EXPOSE 8080
CMD ["gunicorn", "--access-logfile", "-", "--bind", "0.0.0.0:8080", "app:app"]
