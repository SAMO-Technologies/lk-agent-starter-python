# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/appuser" \
    --shell "/usr/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libffi-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*



# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY . /app

# Place executables in the environment at the front of the path
# ENV PATH="/app/.venv/bin:$PATH"

WORKDIR /home/appuser/app


# Copy project files
COPY --chown=appuser:appuser pyproject.toml uv.lock ./
# Install Python dependencies inside a uv-managed venv
RUN uv sync

# Copy rest of code
COPY --chown=appuser:appuser . .

# Pre-download any required assets
RUN uv run python main.py download-files

EXPOSE 8081
CMD ["uv", "run", "python", "main.py", "start"]