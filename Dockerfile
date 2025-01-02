# Use Python 3.12 slim as the base image
FROM python:3.12-slim AS production

# Set environment variables
ENV VIRTUAL_ENV=/venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=mynewssite.settings.production
ENV PORT=8000

# Create a non-root user and necessary directories
RUN useradd wagtail --create-home && mkdir /app $VIRTUAL_ENV && chown -R wagtail /app $VIRTUAL_ENV

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    build-essential \
    libpq-dev \
    && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# Create a virtual environment and install Python dependencies
RUN python -m venv $VIRTUAL_ENV
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Switch to non-root user
USER wagtail

# Copy project files
COPY --chown=wagtail . .

# Collect static files
RUN SECRET_KEY=none python manage.py collectstatic --noinput --clear

# Expose the application port
EXPOSE 8000

# Command to run the application
CMD ["gunicorn", "mynewssite.wsgi:application", "--bind", "0.0.0.0:8000"]
