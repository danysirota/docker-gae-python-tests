FROM alpine:3.1

RUN apk update && apk add alpine-sdk musl-dev linux-headers wget bash python python-dev py-pip libffi-dev openssl-dev zip && rm -rf /var/cache/apk/*
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h
RUN pip install -U pip setuptools
RUN pip install psutil pytest requests[security] pycrypto cryptography appdirs

# Install the Google Cloud SDK.
ENV HOME /
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1

ENV NODE_VERSION 8.7.0
RUN curl -sSJL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" -o /tmp/node-v$NODE_VERSION-linux-x64.tar.gz \
    && tar -xzf "/tmp/node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && npm install --silent -g npm \
    && rm -f "/tmp/node-v$NODE_VERSION-linux-x64.tar.gz"

# Download and install the cloud sdk
RUN wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz --no-check-certificate \
    && tar zxvf google-cloud-sdk.tar.gz \
    && rm google-cloud-sdk.tar.gz \
    && ./google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --additional-components app-engine-python app cloud-datastore-emulator

# Disable updater check for the whole installation.
# Users won't be bugged with notifications to update to the latest version of gcloud.
RUN google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true

# Disable updater completely.
# Running `gcloud components update` doesn't really do anything in a union FS.
# Changes are lost on a subsequent run.
RUN sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' /google-cloud-sdk/lib/googlecloudsdk/core/config.json

RUN mkdir /.ssh
ENV GAE_SDK_ROOT /google-cloud-sdk/bin
ENV PATH $GAE_SDK_ROOT:$PATH
ENV PYTHONPATH $GAE_SDK_ROOT:$PYTHONPATH
VOLUME ["/.config"]
CMD ["/bin/bash"]