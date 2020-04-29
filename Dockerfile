ARG EXTRA_PACKAGES="bash"

FROM alpine as builder

RUN apk add --no-cache bash tmux git

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

ARG EXTRA_PACKAGES

RUN apk add --no-cache tmux su-exec ${EXTRA_PACKAGES}
COPY --from=builder /root /root
RUN chmod o+rwx /root

ENV USER_ID 0
ENV GROUP_ID 0
RUN { \
	echo '#!/bin/bash -e'; \
	echo 'if [ ${USER_ID} -ne 0 ]; then'; \
	echo '    addgroup -g ${GROUP_ID} -S group'; \
	echo '    adduser -h /root -G group -S -D -H -u ${USER_ID} user'; \
	echo 'fi'; \
	echo 'exec su-exec ${USER_ID}:${GROUP_ID} "$@"'; \
	} > /entrypoint && chmod +x /entrypoint
SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "/entrypoint" ]
CMD [ "tmux", "-2" ]