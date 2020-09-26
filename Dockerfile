FROM alpine:3.11 as builder

RUN apk add --no-cache fish bash tmux git

COPY .tmux.conf /root/.tmux.conf
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
    tmux start-server && \
    tmux new-session -d && \
    # wait for tmux server launch
    sleep 1 && \
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh

RUN find ${HOME} | xargs -n 50 -P 4 chmod o+rwx

FROM alpine:3.11
LABEL maintainer="Kazuki Ishigaki<k-ishigaki@frontier.hokudai.ac.jp>"

RUN apk add --no-cache bash fish tmux su-exec
COPY --from=builder /root /root
RUN chmod o+rwx /root

ENV USER_ID 0
ENV GROUP_ID 0
RUN { \
    echo '#!/bin/sh -e'; \
    echo 'getent group ${GROUP_ID} || addgroup --gid ${GROUP_ID} group'; \
    echo 'getent passwd ${USER_ID} || adduser --uid ${USER_ID} --disabled-password --ingroup `getent group ${GROUP_ID} | cut -d: -f1` --home /root user'; \
    echo 'exec su-exec ${USER_ID}:${GROUP_ID} "$@"'; \
    } > /entrypoint && chmod +x /entrypoint
SHELL [ "/usr/bin/fish", "-c" ]
ENTRYPOINT [ "/entrypoint" ]
CMD [ "tmux", "-2" ]
