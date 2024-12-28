# MySQL Restricted Access Setup

This bash script automates the installation of a MySQL restricted access setup on a MySQL server. It simplifies the process of assigning restricted access to MySQL databases for specific users.

## Features
- Limit MySQL user access to specific databases.
- Create MySQL users with restricted access.
- Each user will have to use a prefix to create databases.
- Root user will have access to all databases.

## Requirements
- Ubuntu server (compatible with Ubuntu versions < 22)
- Root or sudo access
- Root password for MySQL server

## Installation

Run the following one-liner on your server to automatically download and execute the script:

```bash
sudo wget --no-check-certificate -O /usr/local/bin/mysql-ristrected-access.sh https://raw.githubusercontent.com/rifrocket/MySQL-Ristrected-Access/main/mysql-ristrected-access.sh; sudo bash /usr/local/bin/mysql-ristrected-access.sh
```

Ensure the script is executable and run it with `bash`. You can make the script executable by running:

```bash
sudo chmod +x /usr/local/bin/mysql-ristrected-access.sh
```

## Usage

### Create a User
```bash
sudo /usr/local/bin/mysql-ristrected-access.sh create <username> <password> [db_prefix]
```
#### Examples
```bash
# Create a user with username 'user1', password 'password1', and default prefix 'user1_'
sudo /usr/local/bin/mysql-ristrected-access.sh create user1 password1

# Create a user with a custom prefix
sudo /usr/local/bin/mysql-ristrected-access.sh create user2 password2 customprefix_
```

### Delete a User
```bash
sudo /usr/local/bin/mysql-ristrected-access.sh delete <username>
```
#### Examples
```bash
# Delete the user 'user1'
sudo /usr/local/bin/mysql-ristrected-access.sh delete user1
```



## Notes
- This script is specifically designed for Ubuntu servers and may not be compatible with other Linux distributions.
- Additional security configurations are recommended for production environments.
- Ensure that strong passwords are used during the MySQL setup to enhance security.

## Optional: Add prefix while creating databases using phpMyAdmin

```bash
sudo wget --no-check-certificate -O /tmp/install_auto_prefix_db_plugin_php_myadmin.sh https://raw.githubusercontent.com/rifrocket/MySQL-Restricted-Access/main/install_auto_prefix_db_plugin_php_myadmin.sh; sudo bash /tmp/install_auto_prefix_db_plugin_php_myadmin.sh
```
