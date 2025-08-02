#!/bin/sh
error_message() {
  echo "$1 not set in the environment";
}


if [ -z "$USERNAME" ] ; then 
  echo error_message "USERNAME";
  exit 1;
fi

if [ -z "$USER_UID" ] ; then
  echo error_message "USER_ID";
  exit 2;
fi

if [ -z "$USER_GID" ] ; then
  echo error_message "USER_GID";
  exit 3;
fi


### User setup
# Add user for ssh access
if [ ! $(id -u "$USERNAME") ] ; then
  echo "Creating $USERNAME ($USER_UID:$USER_GID)"
  groupadd -g $USER_GID $USERNAME
  useradd -m -s /bin/zsh -u $USER_UID -g $USER_GID $USERNAME
  echo "$USERNAME:$(head -c 40 /dev/urandom | base64)" | chpasswd
fi


# Create home dir
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
cat /home/.host/$USERNAME/ssh/local.pub > /home/$USERNAME/.ssh/authorized_keys


### nvim setup
echo "Setting up nvim"
if [ ! -d /home/$USERNAME/.config/nvim ] ; then
  echo "Creating .config/nvim"
  mkdir -p /home/$USERNAME/.config/nvim
fi


# do this step everytime because this might change often
cp -R /home/.host/$USERNAME/nvim/.config/. /home/$USERNAME/.config/nvim/


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

EOS

exec zsh

EOF
fi

cp /home/.host/$USERNAME/zshrc/.zshrc_shared /home/$USERNAME/

chown -R $USER_UID:$USER_GID /home/$USERNAME

exec "$@"

