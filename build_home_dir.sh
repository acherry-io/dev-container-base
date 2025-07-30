#!/bin/sh

if [ -z "$USERNAME" ] ; then
  echo "\$USERNAME is not set"
  exit 1
fi

if [ -z "$LOCAL_SSH_ID_FILE" ] ; then
  echo "\$LOCAL_SSH_ID_FILE is not set"
  exit 3
fi

if [ -z "$GITHUB_SSH_ID_FILE" ] ; then
  echo "\$GITHUB_SSH_ID_FILE is not set"
  exit 4
fi

echo "USERNAME: $USERNAME"
echo "LOCAL SSH ID FILE: $LOCAL_SSH_ID_FILE"
echo "GITHUB SSH ID FILE: $GITHUB_SSH_ID_FILE"

### Create home dir
if [ ! -d /home/$USERNAME ]; then
  echo "Creating home dir: /home/$USERNAME"
  mkdir -p /home/$USERNAME
  chmod 755 /home/$USERNAME
fi


### SSH setup
echo "Setting up .ssh"
if [ ! -d /home/$USERNAME/.ssh ]; then
  echo "Creating .ssh directory"
  mkdir -p /home/$USERNAME/.ssh
  chmod 700 /home/$USERNAME/.ssh
else
  echo ".ssh already exists"
fi

# Add pubkey to authorized_keys so we can log in
touch /home/$USERNAME/.ssh/authorized_keys
cat /home/.host/$USERNAME/.ssh/$LOCAL_SSH_ID_FILE.pub > /home/$USERNAME/.ssh/authorized_keys

# Add private key for github
cp /home/.host/$USERNAME/.ssh/$GITHUB_SSH_ID_FILE /home/$USERNAME/.ssh/
chmod 600 /home/$USERNAME/.ssh/$GITHUB_SSH_ID_FILE

cat > /home/$USERNAME/.ssh/config <<EOF
Host github.com
  IdentityFile ~/.ssh/$GITHUB_SSH_ID_FILE 
  AddKeysToAgent yes
EOF

### nvim setup
echo "Setting up nvim"
if [ ! -d /home/$USERNAME/.config/nvim ] ; then
  echo "Creating .config/nvim"
  mkdir -p /home/$USERNAME/.config/nvim
fi

# do this step everytime because this might change often
cp -R /home/.host/$USERNAME/.config/nvim/. /home/$USERNAME/.config/nvim


### ohmyzsh
if [ ! -d /home/$USERNAME/.oh-my-zsh ]; then
  echo "Setting oh my zsh! to install on first login"

  touch /home/$USERNAME/.zshrc
  chmod 755 /home/$USERNAME/.zshrc

  cat > /home/$USERNAME/.zshrc <<EOF
echo "Installing oh my zsh!"
sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


cat >> /home/$USERNAME/.zshrc <<EOS

source /home/$USERNAME/.zshrc_shared

git config --global url."git@github.com:".insteadOf "https://github.com/"

# Add passphrase to ssh-agent for github for session or else nvim syncs will fail
echo "Testing github connection..."
ssh -T git@github.com

EOS

exec zsh

EOF
fi

cp /home/.host/$USERNAME/.zshrc_shared /home/$USERNAME/


