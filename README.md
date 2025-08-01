# Dev Container Base

## Purpose

To create a foundation to easily spin up a development environment that I can install libraries, packages, etc. in to that will not pollute the host machine and also keep dependencies separate between projects. Implemented in Podman using a root (not rootless) machine.

## Host Dependencies

* Set up for macOS since that is my host machine, but modifications could be made to work with WSL or Linux
* Podman (could easily be ported to Docker), but I wanted to run containers in a rootless environment.
* Neovim configuration
* Oh My Zsh configuration
  * Assumes that any custom items shared between the host and the dev container are stored in ~/.zshrc_shared

* ssh keys to use for access to this container and ssh keys to use for access to GitHub

> [!IMPORTANT]
>
> I originally wanted to do this with a rootless machine, however when logging in as a non-root user I could not get the bind mounts to be writable by that user. Using a root machine allows for control over ownership when running which makes it easier to sync between the host and the container.

## Implementation

### Containerfile

#### Arguments

- **USERNAME** - user that is logged in on the host
- **USER_UID** - uid of logged in user
- **USER_GID** - gid to use to create group inside of image for user

Uses a Debian as a base to create an image that will represent our development environment. An OpenSSH server is installed and configured as the route to access the development environment. A handful of packages are installed as a base offerings of the image. When the container is started, sshd is the foreground process that will keep the container alive.

The dev user is created with passed in **USER_UID** and assigned a new group with the passed in **USER_GID** which will become relevant when building the home directory for the container. The **USER** passed in will be the name used for the create account and the home directory

### compose.yaml

To start the environment there are two services:

#### Environment Variables

- **USERNAME** - user that is logged in on the host
- **USER_UID** - uid of user logged in on the host
- **USER_GID** - gid to assign to the home directory in the container.
- **DEV_CONTAINER_BASE_DIR** - base directory to resolve base scripts and files.
- **LOCAL_SSH_ID_FILE** - name. of the ssh id file that will be used to access from the host to the container

#### create-home-dir

##### build_home_dir.sh
This service syncs the home directory from the host to the home directory that will be used on the main dev container. At the end of the creation, home directory is chown'ed to **USER_UID**:**USER_GID**.

> [!NOTE]
>
> The config is set up with AddKeysToAgent = yes. This is to allow Neovim to be able to install plugins over an authenicated connection.

* On first load Oh My Zsh is installed and the .zshrc file is appended to

  * A copy of ~/.zshrc_shared is placed in the home volume and is added to be sourced on load of zsh
  * Items for GitHub are hardcoded into the .zshrc file
    * All calls to https://github.com are routed to ssh:git@github.com

#### dev-container

In the compose.yaml itself, at a minimum we'd expect to see the follow for the dev-container service:

```dockerfile
dev-container:
  image: # dev container image
    ports:    
      - "9000:22"
    extra_hosts:
      - "host.docker.internal:host.gateway"
    volumes:
      - ./home:/home
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

