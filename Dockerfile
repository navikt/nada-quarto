FROM gcr.io/distroless/cc AS cc
FROM python:3.13 as builder

RUN apt-get update && apt-get install -yq jq curl

WORKDIR /quarto

RUN useradd -m -d /quarto/ -u 1069 -s /bin/bash quarto && \
    chown -R quarto:quarto /quarto/

RUN QUARTO_VERSION=$(curl https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | jq '.tag_name' | sed -e 's/[\"v]//g') && \
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    tar -xvzf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz && \
    ln -s quarto-${QUARTO_VERSION} quarto-dist && \
    rm -rf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz

COPY main.py .
COPY index.qmd .

FROM python:3.13-alpine3.22

COPY --from=cc --chown=root:root --chmod=755 /lib/*-linux-gnu/* /usr/local/lib/
COPY --from=cc --chown=root:root --chmod=755 /lib/ld-linux-* /lib/

COPY --from=builder /quarto/quarto-dist/bin /usr/local/bin/
COPY --from=builder /quarto/quarto-dist/share /usr/local/share/
COPY --from=builder --chown=quarto:quarto /etc/passwd /etc/passwd
COPY --from=builder --chown=quarto:quarto /quarto /quarto

RUN mkdir /lib64 && ln -s /usr/local/lib/ld-linux-* /lib64/
ENV LD_LIBRARY_PATH="/usr/local/lib"

RUN apk update && apk add --no-cache \
    bash \
    build-base \
    libffi-dev \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="/opt/venv/lib/python3.13/site-packages"
ENV PATH="/opt/venv/bin:${PATH}"

WORKDIR /quarto

USER quarto

ENTRYPOINT ["python", "main.py"]