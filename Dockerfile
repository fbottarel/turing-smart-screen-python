# Multi-stage build for smaller final image
FROM alpine:3.20 AS builder

# Install build dependencies
RUN apk update && \
    apk add --no-cache \
        gcc \
        python3-dev \
        musl-dev \
        linux-headers \
        python3 \
        python3-tkinter \
        py3-pip \
        git \
        && rm -rf /var/cache/apk/*
RUN python3 -m pip install --break-system-packages \
        Cython

# Install Python dependencies in builder stage
COPY requirements.txt /tmp/
RUN python3 -m pip install --break-system-packages --no-warn-script-location \
    --prefix=/install pyamdgpuinfo
RUN python3 -m pip install --break-system-packages --no-warn-script-location \
    --prefix=/install -r /tmp/requirements.txt

# Final stage - runtime image
FROM alpine:3.20

# Install only runtime dependencies
RUN apk update && \
    apk add --no-cache \
        python3 \
        libdrm \
        && rm -rf /var/cache/apk/* \
        && find /usr -name "*.pyc" -delete \
        && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Set working directory and create repo directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/usr/local/lib/python3.12/site-packages

# Default command
CMD ["python3", "/app/main.py"]
