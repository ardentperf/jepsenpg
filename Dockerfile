#
# this Dockerfile is a simplified version of https://github.com/jepsen-io/jepsen/blob/main/docker/control/Dockerfile
#
#   docker buildx build . -t ardentperf/jepsenpg --platform linux/amd64,linux/arm64  [--push/--load]
#
FROM debian:bookworm-slim

# Jepsen dependencies
#     nb. i'm not sure why we dont use debian's openjdk, but this is what the jepsen dockerfile does. i added ARM
#         support but did not change the approach of pulling this specific version from adoptium's github repo
RUN apt-get -qy update && \
    apt-get -qy install \
    curl dos2unix emacs git gnuplot graphviz htop iputils-ping libjna-java pssh screen vim wget && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        JAVA_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        JAVA_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_${JAVA_ARCH}_linux_hotspot_21.0.8_9.tar.gz | tar -xz --strip-components=1 -C /usr/local/

# clojure language tool - leiningen
RUN wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein && \
    mv lein /usr/bin && \
    chmod +x /usr/bin/lein && \
    lein self-install

# jepsen postgres test harness
COPY postgres /jepsenpg

# trigger pulling clojure dependencies now and include them in the image
RUN cd /jepsenpg && \
    lein run test-all --help

# if people shell into the container, start in the directory with jepsen
RUN echo "cd /jepsenpg" >>/root/.bashrc
