FROM python:3.12

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

RUN groupadd -g 1069 python && \
    useradd -r -u 1069 -g python python

WORKDIR /home/python

COPY index.qmd .
COPY publish.sh .
COPY requirements.txt .

RUN pip install -r requirements.txt
RUN ipython kernel install --name "python3"

ENV DENO_DIR=/home/python/deno
ENV XDG_CACHE_HOME=/home/python/cache
ENV XDG_DATA_HOME=/home/python/share

RUN chown python:python /home/python -R
USER python

CMD ["./publish.sh"]
