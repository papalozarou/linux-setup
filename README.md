# Linux setup scripts

A set of shell scripts to automate the setup of an Ubuntu 20.04.0x and above server, by:

1. Updating and upgrading the fresh install;
3. changing the default user's password;
4. changing the default user's name;
5. setting up ssh keys for remote connection;
6. configuring the ssh server;
7. configuring ufw;
8. configuring fail2ban;
9. configuring the timezone;
10. configuring git;
11. installing docker; and
12. setting some environment variables for docker usage.

## Usage

Clone the repository, and change to the repository directory with:

```
git clone https://github.com/papalozarou/linux-setup.git && \
cd ~/linux-setup
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

This leaves the `.config/linux-setup` directory in place for reference.

### N.B.

Script `03-change-username.sh` kills all processes and requires logging in with a temporary user which is set up as part of the script.

The scripts are not particularly robust in terms of error handling. Soz like.

## Todo
- [x] Fix docker validation
- [x] Move all service installs to using `installRemovePackage` function
- [x] Add timezone and NTP setup
- [ ] Robust error handling