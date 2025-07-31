#!/bin/sh

echo "USERNAME: $USERNAME"
echo "uid:gid: $USER_UID:$USER_GID"
echo "chown-ing /home/$USERNAME"

#sudo chown -R $USER_UID:$USER_GID /home/$USERNAME &> /dev/null

exec "$@"

