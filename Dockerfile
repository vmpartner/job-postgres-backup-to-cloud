FROM postgres:16-alpine

ENV POSTGRES_DATABASE **None**
ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT **None**
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV RCLONE_DEST **None**
ENV CHECK_URL **None**
ENV LOKI_APP **None**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             0B        buildkit.dockerfile.v0
ENV LOKI_URL **None**
ENV VACUM **None**

RUN apk update && apk add curl coreutils
ADD run.sh /run.sh
RUN chmod +x /run.sh
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cd rclone-*-linux-amd64 && \
    cp rclone /usr/bin/ && \
    chown root:root /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone

USER root

CMD ["sh", "run.sh"]