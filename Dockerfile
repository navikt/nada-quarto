FROM europe-north1-docker.pkg.dev/cgr-nav/pull-through/nav.no/python:3.13-dev as dev

USER root
RUN apk add --update jq curl shadow

WORKDIR /quarto

RUN useradd -m -d /quarto/ -u 1069 -s /bin/bash quarto && \
    chown -R quarto:quarto /quarto/

RUN QUARTO_VERSION=$(curl https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | jq '.tag_name' | sed -e 's/[\"v]//g') && \
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    tar -xvzf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    ln -s quarto-${QUARTO_VERSION} quarto-dist && \
    rm -rf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz

USER quarto

COPY main.py .
COPY index.qmd .
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python", "main.py"]