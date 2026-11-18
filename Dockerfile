FROM europe-north1-docker.pkg.dev/cgr-nav/pull-through/nav.no/python:3.15-dev

USER root
WORKDIR /quarto

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/quarto \
    PATH="/opt/quarto/bin:$PATH"

RUN apk add --no-cache --virtual .quarto-download-deps curl jq && \
    QUARTO_VERSION=$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | jq -er '.tag_name | ltrimstr("v")') && \
    curl -fsSL -o /tmp/quarto.tar.gz \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" && \
    mkdir -p /opt/quarto && \
    tar -xzf /tmp/quarto.tar.gz -C /opt/quarto --strip-components=1 && \
    rm /tmp/quarto.tar.gz && \
    apk del .quarto-download-deps && \
    chown 1069:1069 /quarto

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && rm requirements.txt

USER 1069:1069

COPY --chown=1069:1069 main.py index.qmd ./

ENTRYPOINT ["python", "main.py"]
