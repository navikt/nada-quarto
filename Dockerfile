FROM python:3.11

RUN apt-get update && apt-get install -yq --no-install-recommends \
    curl \
    jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN QUARTO_VERSION=$(curl https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | jq '.tag_name' | sed -e 's/[\"v]//g') && \
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    tar -xvzf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    ln -s /quarto-${QUARTO_VERSION}/bin/quarto /usr/local/bin/quarto && \
    rm -rf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz

WORKDIR /app

RUN groupadd -g 1069 python && \
    useradd -r -u 1069 -g python python

COPY index.qmd .
COPY publish.sh .

ENV DENO_DIR=/app/deno
ENV XDG_CACHE_HOME=/app/cache
ENV XDG_DATA_HOME=/app/share

RUN chown python:python /app -R

USER 1069

CMD ["/app/publish.sh"]
