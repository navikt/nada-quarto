FROM gcr.io/distroless/cc AS cc
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

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
ENV PATH="/quarto/quarto-dist/bin:${PATH}"

RUN python -m venv venv
ENV PATH="/quarto/venv/bin":$PATH
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

FROM europe-north1-docker.pkg.dev/cgr-nav/pull-through/nav.no/python:3.13

COPY --from=dev --chown=root:root /bin/bash /bin/bash
COPY --from=dev --chown=root:root --chmod=755 /lib/libcrypt* /lib/
COPY --from=dev --chown=root:root --chmod=755 /bin /bin/
COPY --from=dev --chown=root:root /etc/passwd /etc/passwd
COPY --from=dev --chown=root:root /quarto/quarto-dist/bin /usr/local/bin/
COPY --from=dev --chown=root:root /quarto/quarto-dist/share /usr/local/share/

COPY --from=dev --chown=quarto:quarto /quarto /quarto
ENV PATH="/quarto/venv/bin:$PATH"

WORKDIR /quarto

COPY main.py .
COPY index.qmd .

USER quarto

ENTRYPOINT ["python", "main.py"]