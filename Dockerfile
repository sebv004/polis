# escape=\
FROM ubuntu:18.04

ARG COIN_VER='1.6.5'
ARG CONFIG_FILE='polis.conf'
ARG CONFIGFOLDER='/var/polis'
ARG SENTI_CONFIGFOLDER='/var/sentinel'
ARG SENTINEL_REPO='https://github.com/polispay/sentinel.git'
ARG COIN_NAME='Polis'
ARG COIN_PORT=24126
ARG COIN_BS='https://public.oly.tech/bootstrap.tar.gz'

RUN set -eux pipefail \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install apt-utils \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends dist-upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install software-properties-common \
    && apt-add-repository -y ppa:bitcoin/bitcoin \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
    wget \
    git \
    libevent-dev \
    libboost-dev \
    libboost-chrono-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libminiupnpc-dev \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    libssl-dev \
    libevent-dev \
    bsdmainutils \
    libzmq3-dev \
    python-virtualenv virtualenv cron pwgen vim curl \
    && wget "https://github.com/polispay/polis/releases/download/v${COIN_VER}/poliscore-${COIN_VER}-x86_64-linux-gnu.tar.gz" -P /var/tmp \
    && cd /var/tmp && tar xvf "poliscore-${COIN_VER}-x86_64-linux-gnu.tar.gz" \
    && mv /var/tmp/poliscore-$COIN_VER /opt \
    && rm /var/tmp/poliscore-$COIN_VER-x86_64-linux-gnu.tar.gz \
    && cp /opt/poliscore-$COIN_VER/bin/polisd /usr/local/bin \
    && cp /opt/poliscore-$COIN_VER/bin/polis-cli /usr/local/bin \
    && strip /usr/local/bin/polisd /usr/local/bin/polis-cli \
    && chmod +x /usr/local/bin/polisd \
    && chmod +x /usr/local/bin/polis-cli \
    && git clone $SENTINEL_REPO /opt/sentinel \
    && cd /opt/sentinel && virtualenv ./venv && ./venv/bin/pip install --no-cache-dir -r requirements.txt \
    && apt-get -y clean \
    && apt-get -y autoclean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb



EXPOSE ${COIN_PORT}
VOLUME ["/opt/poliscore-1.6.4","/opt/sentinel","/var/polis","/var/sentinel"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["entrypoint.sh"]
