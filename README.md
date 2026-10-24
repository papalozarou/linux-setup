# Linux setup scripts

A set of shell scripts to automate the setup of an Ubuntu 20.04 or later server, by:

1. updating and upgrading the fresh install;
2. configuring rpi specific settings;
3. changing the default user's password;
4. changing the default user's name;
5. setting up ssh keys for remote connection;
6. configuring the ssh server;
7. configuring ufw;
8. configuring fail2ban;
9. configuring the hostname;
10. configuring the timezone; 
11. configuring git;
12. installing docker; and
13. setting some environment variables for docker usage.

## Usage

Install git if it is not already installed with:

```
sudo apt update && sudo apt upgrade -y && sudo apt install git -y
```

Clone the repository, and submodules, then switch to the repository directory with:

```
git clone --recursive https://github.com/papalozarou/linux-setup.git && \
cd ~/linux-setup
```

If you already cloned the repository without submodules, initialise them with:

```
git submodule update --init --recursive
```

To pull later changes from the tracked `linshafun` `main` branch:

```
git pull && \
git submodule update --init --remote linshafun
```

Run the first script:

```
sudo ./01-initialise-setup.sh
```

Once completed, run subsequent scripts following instructions and prompts.

When all scripts have been executed, it's safe to delete the repo with:

```
sudo rm -R ~/linux-setup
```

This leaves the `.config/linux-setup.conf` file in place for reference.

### N.B.

Script `04-change-username.sh` (`03-change-username.sh` if the host isn't a Raspberry Pi) kills all processes and requires logging in with a temporary user which is set up as part of the script.

If a step fails, the script stops with an error and exits with 1, without recording the step as done in `~/.config/linux-setup.conf`. Fix the problem, then run the same script again.