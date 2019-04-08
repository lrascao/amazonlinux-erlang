FROM amazonlinux:latest

MAINTAINER Luis Rascao <luis.rascao@gmail.com>

ENV ANG=en_US.UTF-8 \
    # Set this so that CTRL+G works properly
    TERM=xterm \
    HOME=/opt/app/ \
    ERLANG_VERSION=19.3 \
    OPENSSL_VERSION=0.9.8zh \
    ERLANG_EC2_BUILD_VERSION=1.2.0

WORKDIR /tmp/erlang-build

# Compile and install Erlang
RUN \
    yum -y install sudo git && \
    # Create default user and home directory, set owner to default
    mkdir -p "${HOME}" && \
    adduser --shell /bin/bash --uid 1001 --groups root --base-dir "${HOME}" --system default && \
    chown -R 1001:0 "${HOME}" && \
    # Clone and run the set of scripts that will build the erlang vm for us
    git clone --branch $ERLANG_EC2_BUILD_VERSION https://github.com/lrascao/erlang-ec2-build.git && \
    pushd erlang-ec2-build && \
        ./setup.sh && \
        pushd openssl && \
            ./build.sh $OPENSSL_VERSION && \
        popd && \
        pushd erlang && \
            curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl && \
            chmod a+x kerl && \
             ./kerl update releases && \
             KERL_CONFIGURE_OPTIONS="--with-ssl=/tmp/erlang-build/erlang-ec2-build/openssl/releases/latest \
                                     --disable-dynamic-ssl-lib \
                                     --enable-hipe \
                                     --without-wx \
                                     --without-odbc \
                                     --without-javac \
                                     --without-debugger \
                                     --without-observer \
                                     --without-jinterface \
                                     --without-cosEvent \
                                     --without-cosEventDomain \
                                     --without-cosFileTransfer \
                                     --without-cosNotification \
                                     --without-cosProperty \
                                     --without-cosTime \
                                     --without-cosTransactions \
                                     --without-et \
                                     --without-gs \
                                     --without-ic \
                                     --without-megaco \
                                     --without-orber \
                                     --without-percept \
                                     --without-typer \
                                     --enable-builtin-zlib \
                                     --with-dynamic-trace=systemtap" \
                    CFLAGS="-g -O2 -march=native" ./kerl build $ERLANG_VERSION $ERLANG_VERSION && \
             mkdir /opt/erlang && \
             sudo chown default /opt/erlang && \
             sudo chgrp default /opt/erlang && \
             ./kerl install $ERLANG_VERSION /opt/erlang/$ERLANG_VERSION && \
        popd && \
    popd && \
    # cleanup
    pushd erlang-ec2-build && \
        ./cleanup.sh && \
    popd && \
    rm -rf /tmp/erlang-build && \
    rm -rf /opt/app/.kerl

WORKDIR ${HOME}

CMD ["/bin/bash"]
