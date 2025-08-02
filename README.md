# Dev Container Base

## Purpose

To create a foundation to easily spin up a development environment that I can install libraries, packages, etc. in to that will not pollute the host machine and also keep dependencies separate between projects. Implemented in Podman using a root (not rootless) machine.

## Host Dependencies

* Set up for macOS since that is my host machine, but modifications could be made to work with WSL or Linux.
* Podman (could easily be ported to Docker).
* Neovim configuration
* Oh My Zsh configuration
  * Assumes that any custom items shared between the host and the dev container are stored in ~/.zshrc_shared

* ssh keys to use for access to the container.

> [!IMPORTANT]
>
> I originally wanted to do this with a rootless machine, however when logging in as a non-root user I could not get the bind mounts to be writable by that user. Using a machine with root allows for control over ownership when running which makes it easier to sync between the host and the container.

## Implementation

### Containerfile

#### Environment Variables

- **USERNAME** - user that is logged in on the host
- **USER_UID** - uid of logged in user
- **USER_GID** - gid to use to create group inside of image for user

Uses a Debian as a base to create an image that will represent our development environment. An OpenSSH server is installed and configured as the route to access the development environment. A handful of packages are installed as a base offerings of the image. When the container is started, sshd is the foreground process that will keep the container alive. Development is assumed to be done with Neovim.

The dev user is created with passed in **USER_UID** and assigned a new group with the passed in **USER_GID** which will become relevant when building the home directory for the container. The **USERNAME** passed in will be the name used for the create account and the home directory

The following bind mounts help build the home directory for the container:

* {location to store home on host}:/home
* {local public ssh key to be added to authorization keys}:/home/.host/${USERNAME}/ssh/local.pub
* {nvim config directory to be copied}:/home/.host/nvim/.config/
* {zshrc_shared location to be copied}:/home/.host/zshrc/.zshrc_shared

The script to build the home directory is run on load. At the end of the creation, home directory is chown'ed to **USER_UID**:**USER_GID**.

> [!NOTE]
>
> The config is set up with AddKeysToAgent = yes. This is to allow Neovim to be able to install plugins over an authenticated connection.

* On first load Oh My Zsh is installed and the .zshrc file is appended to

  * A copy of ~/.zshrc_shared is placed in the home volume and is added to be sourced on load of zsh
  * Items for GitHub are hardcoded into the .zshrc file
    * All calls to https://github.com are routed to ssh:git@github.com

### compose.yaml

In the compose.yaml itself, at a minimum we'd expect to see the follow for the dev-container service:

```dockerfile
dev-container:
  image: # dev container image
    env_file:
    	- .env
    ports:    
      - "9000:22"
    volumes:
      - {location to store home on host}:/home
			- {local public ssh key to be added to authorization keys}:/home/.host/${USERNAME}/ssh/local.pub
			- {nvim config directory to be copied}:/home/.host/nvim/.config/
			- {zshrc_shared location to be copied}:/home/.host/zshrc/.zshrc_shared
      - # mount source
    depends_on:
      - create-home-dir
```

### Neovim setup

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

