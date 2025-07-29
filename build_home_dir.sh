#!/bin/sh

if [ ! -n "$USER" ] ; then
  echo "\$USER is not set"
  exit 1
fi

if [ ! -n "$LOCAL_SSH_ID_FILE" ] ; then
  echo "\$LOCAL_SSH_ID_FILE is not set"
fi

if [ ! -n "$GITHUB_SSH_ID_FILE" ] ; then
  echo "\$GITHUB_SSH_ID_FILE is not set"
  exit 2
fi

### Create home dir
if [ ! -d /home/$USER ]; then
  echo "Creating home dir: /home/$USER"
  mkdir -p /home/$USER
  chmod 755 /home/$USER
fi


### SSH setup
echo "Setting up .ssh"
if [ ! -d /home/$USER/.ssh ]; then
  echo "Creating .ssh directory"
  mkdir -p /home/$USER/.ssh
  chmod 700 /home/$USER/.ssh
else
  echo ".ssh already exists"
fi

# Add pubkey to authorized_keys so we can log in
touch /home/$USER/.ssh/authorized_keys
cat /home/.host/${USER}/.ssh/$LOCAL_SSH_ID_FILE.pub > /home/$USER/.ssh/authorized_keys

# Add private key for github
cp /home/.host/$USER/.ssh/$GITHUB_SSH_ID_FILE /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/$GITHUB_SSH_ID_FILE

cat > /home/$USER/.ssh/config <<EOF
Host github.com
  IdentityFile ~/.ssh/$GITHUB_SSH_ID_FILE 
  AddKeysToAgent yes
EOF

### nvim setup
echo "Setting up nvim"
if [ ! -d /home/$USER/.config/nvim ] ; then
  echo "Creating .config/nvim"
  mkdir -p /home/$USER/.config/nvim
fi

# do this step everytime because this might change often
cp -R /home/.host/$USER/.config/nvim/. /home/$USER/.config/nvim


### ohmyzsh
if [ ! -d /home/$USER/.oh-my-zsh ]; then
  echo "Setting oh my zsh! to install on first login"

  touch /home/$USER/.zshrc
  chmod 755 /home/$USER/.zshrc

  cat > /home/$USER/.zshrc <<EOF
echo "Installing oh my zsh!"
sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


cat >> /home/$USER/.zshrc <<EOS

source /home/$USER/.zshrc_shared

git config --global url."git@github.com:".insteadOf "https://github.com/"

# Add passphrase to ssh-agent for github for session or else nvim syncs will fail
echo "Testing github connection..."
ssh -T git@github.com

EOS

exec zsh

EOF
fi

cp /home/.host/$USER/.zshrc_shared /home/$USER/

### Setting owner to USER
echo "Setting owner to $USER"
chown -R 9999:9999 /home/$USER

