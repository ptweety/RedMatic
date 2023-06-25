# syntax=docker/dockerfile:1.4

ARG NODE_VERSION=16
ARG VARIANT=bullseye

FROM node:$NODE_VERSION-$VARIANT as base

ARG VARIANT
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

# Support linux/amd64 linux/arm64 linux/arm/v7
ARG ARCH=${TARGETARCH}${TARGETVARIANT:+${TARGETVARIANT}l}

FROM base as builder

WORKDIR /app

COPY package.json build_packages.js ./

RUN apt update\
    && apt install -y jq libavahi-compat-libdnssd-dev libudev-dev \
    && rm -rf /var/lib/apt/lists/* \
    && echo "export VERSION_ADDON=`jq -r '.version' package.json`" >> /envfile \
    && echo "export NODE_VERSION=`jq -r '.engines.node' package.json`" >> /envfile \
    && . /envfile \
    && echo "\nBuild RedMatic v${VERSION_ADDON} (${ARCH})\n" \
    && case ${ARCH} in \
            amd64) \
                echo "export NODE_NAME=node-v${NODE_VERSION}-linux-x64" >> /envfile  \
            ;; \
            *) \
                echo "export NODE_NAME=node-v${NODE_VERSION}-linux-${ARCH}" >> /envfile  \
            ;; \
        esac \
    && . /envfile \
    && echo "export NODE_URL=https://nodejs.org/dist/v${NODE_VERSION}/${NODE_NAME}.tar.xz" >> /envfile \
    && echo "node version on build system: `node --version`" \
    && . /envfile \
    && mkdir build \
    && cd build \
    && echo "download and extract Node.js ${NODE_URL} ..." \
    && curl --silent ${NODE_URL} | tar -xJf - -C . || exit 1 \
    && mv ${NODE_NAME} redmatic \
    && rm redmatic/README.md \
    && rm redmatic/CHANGELOG.md \
    && mkdir ../licenses \
    && mv redmatic/LICENSE ../licenses/nodejs \
    && echo "copying addon_files and assets..."

COPY ./addon_files ./build
COPY ./assets/redmatic5* ./assets/favicon/apple-icon-180x180.png ./assets/favicon/favicon-96x96.png ./build/redmatic/www/

RUN echo "installing node modules..." \
    && cd build/redmatic/lib \
    && if [ "${ARCH}" = "amd64" ] ; then \
            echo "removing Raspberry Pi specific modules..." \
            && mv package.json package.json.tmp \
            && cat package.json.tmp | jq 'del(.dependencies."node-red-contrib-johnny-five",.dependencies."node-red-contrib-rcswitch2")' >  package.json \
            && rm package.json.tmp ; \
        fi \
    && npm install --no-package-lock --omit=dev --omit=optional --global-style \
    && npm install --silent --no-package-lock --omit=dev --global-style ain2 \
    && if [ "${ARCH}" = "amd64" ] ; then \
            echo "installing unix-dgram..." \
            && npm install --silent --no-package-lock --no-save --prefix=./node_modules/ain2 unix-dgram ; \
        fi

RUN echo "installing additional Node-RED nodes..." \
    && cd build/redmatic/var \
    && npm install --silent --no-package-lock --omit=dev --omit=optional --global-style

RUN echo "installing www node modules" \
    && cd build/redmatic/www \
    && npm install --silent --no-package-lock --omit=dev --omit=optional

RUN echo "creating version file" \
    && . /envfile \
    && cd build \
    && RED_VERSION=`jq -r '.version' redmatic/lib/node_modules/node-red/package.json` \
    && echo "export NODE_VERSION=${NODE_VERSION}\nexport VERSION_ADDON=${VERSION_ADDON}\nexport RED_VERSION=${RED_VERSION}\n" > redmatic/versions \
    && ln -s redmatic/bin/update_addon ./ \
    && echo "copying prebuilt ($ARCH) binaries..."

COPY prebuilt/${ARCH} ./build/redmatic/

RUN mkdir dist \
    && . /envfile \
    && echo "bundling packages..." \
    && node ./build_packages.js ${ARCH} \
    && echo "adapt Node-RED..." \
    && cd build \
    && INSTALLER=redmatic/lib/node_modules/node-red/node_modules/@node-red/registry/lib/installer.js \
    && sed "s/var args = \['install'/var args = ['install','--no-package-lock','--global-style'/" ${INSTALLER} > ${INSTALLER}.tmp && mv ${INSTALLER}.tmp ${INSTALLER} \
    && sed "s/var args = \['remove'/var args = ['remove','--no-package-lock'/" ${INSTALLER} > ${INSTALLER}.tmp && mv ${INSTALLER}.tmp ${INSTALLER} \
    && if [ "${ARCH}" = "armv7l" ] ; then \
            ADDON_FILE=redmatic-${VERSION_ADDON}.tar.gz ; \
        else \
            ADDON_FILE=redmatic-${ARCH}-${VERSION_ADDON}.tar.gz ; \
        fi \
    && echo "compressing addon package $ADDON_FILE ..." \
    && rm redmatic/lib/package.json \
    && if [ "${OSTYPE}" = "darwin"* ] ; then \
            if [[ -f /usr/local/bin/gtar ]] ; then \
                gtar --exclude=.DS_Store --owner=root --group=root -czf ../dist/${ADDON_FILE} * ; \
            else \
                tar --exclude=.DS_Store -czf ../dist/${ADDON_FILE} * ; \
            fi \
        else \
            tar --owner=root --group=root -czf ../dist/${ADDON_FILE} * ; \
        fi \
    && sha256sum ../dist/${ADDON_FILE} > ../dist/${ADDON_FILE}.sha256 \
    && echo "done."

CMD ["/bin/bash"]