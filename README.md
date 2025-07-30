# Dev Container Base

## Purpose

To create a foundation to easily spin up a development environment that I can install libraries, packages, etc. in to that will not pollute the host machine and also keep dependencies separate between projects. 

## Host Dependencies

* Set up for macOS since that is my host machine, but modifications could be made to work with WSL or Linux
* Podman (could easily be ported to Docker)
* Neovim configuration
* Oh My Zsh configuration
  * Assumes that any custom items shared between the host and the dev container are stored in ~/.zshrc_shared

* ssh keys to use for access to this container and ssh keys to use for access to GitHub

## Implementation

### Containerfile

#### Arguments

- **USER** - user that is logged in on the host
- **UID** - uid of logged in user
- **GROUP** - group name of user
- **GID** - group id of user
- **DEV_CONTAINER_BASE_DIR** - base directory to resolve base scripts and files. I use a symlink to the base directory in the project root and set it to that link name.

Uses Ubuntu as a base to create an image that will represent our development environment. An OpenSSH server is installed and configured as the route to access the development environment. zsh shell, Neovim, curl, and git are installed as assumed base offerings of the image. When the container is started, sshd is the foreground process that will keep the container alive.

The dev user is created with passed in uid and gid which will become relevant in the compose.yaml file. The **USER** passed in will be the name used for the create account and the home directory

### compose.yaml

To start the environment there are two services:

#### Environment Variables

- **DEV_CONTAINER_BASE_DIR** - base directory to resolve base scripts and files. I use a symlink to the base directory in the project root and set it to that link name.

#### create-home-dir

##### Environment variables

- **USER** - user that is logged in on the host
- **LOCAL_SSH_ID_FILE** - name. of the ssh id file that will be used to access from the host to the container
- **GITHUB_SSH_ID_FILE** - name of the ssh id file that will be used to access GitHub

##### build_home_dir.sh
This service syncs the home directory from the host to the home directory that will be used on the main dev container. A named mount that will be used for the dev container to store the home directory files for the envrionment. 

> [!IMPORTANT]
>
> The home directory needs to be stored in a named mount when using Podman because this allows us to set the same uid and gid of the created use to the home directory (with `chown`) allowing for full read/write access to this folder.

A couple an highlights for how this is setup:

* **LOCAL_SSH_ID_FILE** public key is added to authorized_keys for ssh access

* **GITHUB_SSH_ID_FILE** private key is copied to the .ssh directory. A record in the ssh config is added to use this file for access.

> [!NOTE]
>
> The config is set up with AddKeysToAgent = yes. This is to allow Neovim to be able to install plugins over an authenicated connection.

* On first load Oh My Zsh is installed and the .zshrc file is appended to

  * A copy of ~/.zshrc_shared is placed in the home volume and is added to be sourced on load of zsh
  * Items for GitHub are hardcoded into the .zshrc file
    * All calls to https://github.com are routed to ssh:git@github.com
    * On login to the container, we test the connection to github.com to store our passkey in the running ssh-agent. If the challenge is displayed to Neovim for plugin install, this causes an error to be thrown.

In the compose.yaml itself, at a minimum we'd expect to see the follow for the dev-container service:

```dockerfile
dev-container:
    container_name: #dev container name
    image: # dev container image
    ports:
      # Map 9000 on the host to internal ssh 22
      - "9000:22" 
    extra_hosts:
      # If you want the container to access other services on your machine (like ollama if running on the host)
      - "host.docker.internal:host.gateway" 
    volumes:
      # mount the named volume with the home directory inside to the home of the container
      - home-dir:/home:rw 
```

##### Neovim setup

> [!WARNING]
>
> I made the decision to have all calls to GitHub be over an authenticated connection. Reviewing the [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) of GitHub, an authenticated connection can do far more than an unauthenticated one. I'm not sure if this applies to clones/fetches, but I did it just in case.
>
> Also, when configuring Neovim, I found that certain calls to GitHub would fail if too many were done quickly inside the container. I'm using lazy.vim, so I added the following to my setup which seemed to have solved the issue:
>
> ```lua
> require("lazy").setup({
>   	git = {
>      	throttle = {
>      	enabled = true,
>       	rate = 1,
>       	duration = 1 * 100,
>     	},
>   	spec = {
>     	-- Plugins list
>    	}
>   }
> ```

