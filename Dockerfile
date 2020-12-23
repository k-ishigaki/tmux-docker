FROM alpine as builder

RUN apk add --no-cache fish bash tmux git

COPY .tmux.conf /root/.tmux.conf
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
    tmux start-server && \
    tmux new-session -d && \
    # wait for tmux server launch
    sleep 1 && \
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh

RUN find ${HOME} | xargs -n 50 -P 4 chmod o+rwx

FROM alpine
LABEL maintainer="Kazuki Ishigaki<k-ishigaki@frontier.hokudai.ac.jp>"

RUN apk add --no-cache bash fish tmux shadow sudo

COPY --from=builder /root /root

RUN echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/developer && \
    chmod u+s `which groupadd` `which useradd` && \
    { \
    echo '#!/bin/sh -e'; \
    echo 'getent group `id -g` || groupadd --gid `id -g` developer'; \
    echo 'getent passwd `id -u` || useradd --uid `id -u` --gid `id -g` --home-dir /root developer'; \
    echo 'sudo find /root -maxdepth 1 | xargs sudo chown `id -u`:`id -g`'; \
    echo 'exec "$@"'; \
    } > /entrypoint && chmod +x /entrypoint
ENTRYPOINT [ "/entrypoint" ]
ENV HOME=/root

CMD [ "tmux", "-2" ]
