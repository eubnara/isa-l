#!/usr/bin/env bash

cd "$(dirname "$0")"
IMAGE_NAME="isal-build:latest"

docker build -t "${IMAGE_NAME}" - <<EOF
FROM centos:7
RUN yum -y install gcc make autoconf automake libtool git curl which \
    && git clone https://github.com/netwide-assembler/nasm.git \
    && pushd /nasm \
    && yum -y install epel-release \
    && yum -y install asciidoc xmlto fontconfig ghostscript adobe-source-code-pro-fonts adobe-source-sans-pro-fonts perl-Font-TTF perl-Sort-Versions \
    && git checkout tags/nasm-2.15.05 \
    && sh autogen.sh \
    && sh configure \
    && make everything \
    && make install \
    && popd \
    && git clone https://github.com/intel/isa-l.git
EOF

if [[ "$?" != "0" ]];then
  exit 1
fi


ISAL_VERSION=2.30.0
mkdir ./output

docker run --rm -it \
  -v "`pwd`/output:/output" \
  -w "/output" \
  "${IMAGE_NAME}" \
  bash -c "cd /isa-l && git checkout tags/v${ISAL_VERSION} && ./autogen.sh \
    && ./configure --prefix=/usr --libdir=/usr/lib64 \
    && make && cp ./.libs/* /output"
