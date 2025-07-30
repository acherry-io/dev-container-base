#!/bin/sh

echo "USERNAME: $USERNAME"
echo "uid:gid: $USER_UID:$USER_GID"
echo "chown-ing /home/$USERNAME"

chown -R $USER_UID:$USER_GID /home/$USERNAME
exec "$@"

