# Linux setup scripts

A set of shell scripts to automate the setup of an Ubuntu 20.04.0x and above server.

## Usage

Clone the repository, and change to the repository directory with:

```
$ git clone https://github.com/papalozarou/linux-setup.git
$ cd ~/linux-setup
```

Run the first script:

```
$ sudo ./01-initialise-setup.sh
```

Once completed, run subsequent scripts following instructions and prompts.

**N.B.**
Script `04-change-username.sh` kills all processes and requires a reconnecting with a temporary user. This is part of the setup.
