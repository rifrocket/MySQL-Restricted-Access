#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: install_auto_prefix_db_plugin.sh
# Description: Automates the installation and registration of the AutoPrefixDB
#              plugin for phpMyAdmin.
# Usage: sudo ./install_auto_prefix_db_plugin.sh
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables (Modify these according to your system if necessary)
PHPMYADMIN_DIR="/usr/share/phpmyadmin"
CONFIG_FILE="/etc/phpmyadmin/config.inc.php"
BACKUP_CONFIG="/etc/phpmyadmin/config.inc.php.bak_$(date +%F_%T)"

# Function to check if phpMyAdmin is installed
check_phpmyadmin_installed() {
    if [ ! -d "${PHPMYADMIN_DIR}" ]; then
        echo "Error: phpMyAdmin directory (${PHPMYADMIN_DIR}) does not exist."
        echo "Please install phpMyAdmin before running this script."
        exit 1
    fi
}


# Function to backup the existing phpMyAdmin config file
backup_config() {
    echo "Backing up the existing phpMyAdmin configuration file..."
    sudo cp "${CONFIG_FILE}" "${BACKUP_CONFIG}"
    echo "Backup created at ${BACKUP_CONFIG}"
}


# Function to Add AllowUserDropDatabase to phpMyAdmin's configuration
enable_allow_user_drop_database() {
    echo "Ensuring AllowUserDropDatabase is set to true in phpMyAdmin's configuration..."

    if grep -q "\$cfg\['AllowUserDropDatabase'\] *= *true;" "${CONFIG_FILE}"; then
        echo "AllowUserDropDatabase is already set to true."
    else
        if grep -q "\$cfg\['AllowUserDropDatabase'\]" "${CONFIG_FILE}"; then
            sudo sed -i "s/\$cfg\['AllowUserDropDatabase'\] *= *.*/\$cfg['AllowUserDropDatabase'] = true;/" "${CONFIG_FILE}"
            echo "Updated AllowUserDropDatabase to true in ${CONFIG_FILE}."
        else
            sudo sed -i "/^\$cfg\['Plugins'\]/a \$cfg['AllowUserDropDatabase'] = true;" "${CONFIG_FILE}"
            echo "Added AllowUserDropDatabase = true to ${CONFIG_FILE}."
        fi
    fi
}

# Function to validate the installation
validate_installation() {
    echo "Validating the plugin installation..."

    if grep -q "\$cfg\['AllowUserDropDatabase'\] *= *true;" "${CONFIG_FILE}"; then
        echo "AllowUserDropDatabase is successfully registered in ${CONFIG_FILE}."
    else
        echo "Error: AllowUserDropDatabase is not registered in ${CONFIG_FILE}."
        exit 1
    fi
}

# Function to display final instructions
final_instructions() {
    echo ""
    echo "=============================================="
    echo " AllowUserDropDatabase Installation Complete!"
    echo "=============================================="
    echo ""
}

# Main Execution Flow
main() {
    check_phpmyadmin_installed  
    backup_config
    enable_allow_user_drop_database
    validate_installation
    final_instructions
}

# Run the main function
main