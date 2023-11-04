FROM alpine:3.18

RUN apk add --no-cache fish~=3.6 bash~=5.2 tmux~=3.3 git~=2.40

COPY .tmux.conf /root/.tmux.conf
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
    tmux start-server && \
    tmux new-session -d && \
    # wait for tmux server launch
    sleep 1 && \
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
