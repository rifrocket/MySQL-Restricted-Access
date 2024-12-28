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
PLUGIN_NAME="AutoPrefixDB"
PLUGIN_DIR="${PHPMYADMIN_DIR}/libraries/plugins/${PLUGIN_NAME}"
CONFIG_FILE="/etc/phpmyadmin/config.inc.php"
BACKUP_CONFIG="/etc/phpmyadmin/config.inc.php.bak_$(date +%F_%T)"
PLUGIN_FILE="${PLUGIN_NAME}.php"

# Function to check if phpMyAdmin is installed
check_phpmyadmin_installed() {
    if [ ! -d "${PHPMYADMIN_DIR}" ]; then
        echo "Error: phpMyAdmin directory (${PHPMYADMIN_DIR}) does not exist."
        echo "Please install phpMyAdmin before running this script."
        exit 1
    fi
}

# Function to create the plugin file
create_plugin_file() {
    echo "Creating the AutoPrefixDB plugin file..."

    cat << 'EOF' > "${PLUGIN_FILE}"
<?php
/**
 * AutoPrefixDB Plugin for phpMyAdmin
 * Automatically prefixes database names with the username upon creation.
 */

namespace PhpMyAdmin\Plugins\AutoPrefixDB;

use PhpMyAdmin\Plugins\BasePlugin;

class AutoPrefixDB extends BasePlugin
{
    public function __construct()
    {
        // Register the hook
        $this->registerHooks();
    }

    private function registerHooks()
    {
        // Hook into the 'InsertDB' event, which is triggered when a new database is created
        $this->registerHook('InsertDB', [$this, 'autoPrefixDatabase']);
    }

    /**
     * Automatically prefix the database name with the username.
     *
     * @param array $params Parameters passed by the hook.
     */
    public function autoPrefixDatabase(&$params)
    {
        // Check if the user is root; if so, do not prefix
        if ($this->isRootUser()) {
            return;
        }

        // Get the current username
        if (!isset($_SESSION['user'])) {
            // Unable to retrieve username; abort prefixing
            return;
        }

        $userFull = $_SESSION['user'];
        $username = explode('@', $userFull)[0];
        $prefix = $username . '_';

        // Check if the database name already has the prefix
        if (strpos($params['db'], $prefix) !== 0) {
            // Prepend the prefix
            $params['db'] = $prefix . $params['db'];
        }
    }

    /**
     * Determine if the current user is root.
     *
     * @return bool True if root user, false otherwise.
     */
    private function isRootUser()
    {
        if (!isset($_SESSION['user'])) {
            return false;
        }

        $userFull = $_SESSION['user'];
        $username = explode('@', $userFull)[0];

        return strtolower($username) === 'root';
    }
}
?>
EOF

    echo "Plugin file '${PLUGIN_FILE}' created successfully."
}

# Function to copy the plugin to phpMyAdmin's plugin directory
copy_plugin() {
    echo "Copying the plugin to phpMyAdmin's plugin directory..."

    # Create the plugin directory if it doesn't exist
    if [ ! -d "${PLUGIN_DIR}" ]; then
        sudo mkdir -p "${PLUGIN_DIR}"
        echo "Created plugin directory: ${PLUGIN_DIR}"
    fi

    # Move the plugin file to the plugin directory
    sudo mv "${PLUGIN_FILE}" "${PLUGIN_DIR}/"
    echo "Plugin file moved to ${PLUGIN_DIR}/"
}

# Function to backup the existing phpMyAdmin config file
backup_config() {
    echo "Backing up the existing phpMyAdmin configuration file..."
    sudo cp "${CONFIG_FILE}" "${BACKUP_CONFIG}"
    echo "Backup created at ${BACKUP_CONFIG}"
}

# Function to register the plugin in phpMyAdmin's config.inc.php
register_plugin() {
    echo "Registering the AutoPrefixDB plugin in phpMyAdmin's configuration..."

    # Check if the plugin is already registered
    if grep -q "['\"]${PLUGIN_NAME}['\"]" "${CONFIG_FILE}"; then
        echo "Plugin '${PLUGIN_NAME}' is already registered in ${CONFIG_FILE}."
    else
        # Add the plugin to the Plugins array
        sudo sed -i "/^\$cfg\['Plugins'\]/a \$cfg['Plugins'][] = '${PLUGIN_NAME}';" "${CONFIG_FILE}"
        echo "Plugin '${PLUGIN_NAME}' has been added to ${CONFIG_FILE}."
    fi
}

# Function to set appropriate permissions
set_permissions() {
    echo "Setting appropriate permissions for the plugin files..."

    sudo chown -R www-data:www-data "${PLUGIN_DIR}"
    sudo chmod -R 755 "${PLUGIN_DIR}"
    echo "Permissions set for ${PLUGIN_DIR}."
}

# Function to validate the installation
validate_installation() {
    echo "Validating the plugin installation..."

    if [ -f "${PLUGIN_DIR}/${PLUGIN_FILE}" ]; then
        echo "Plugin file exists in ${PLUGIN_DIR}."
    else
        echo "Error: Plugin file not found in ${PLUGIN_DIR}."
        exit 1
    fi

    if grep -q "['\"]${PLUGIN_NAME}['\"]" "${CONFIG_FILE}"; then
        echo "Plugin '${PLUGIN_NAME}' is successfully registered in ${CONFIG_FILE}."
    else
        echo "Error: Plugin '${PLUGIN_NAME}' is not registered in ${CONFIG_FILE}."
        exit 1
    fi
}

# Function to display final instructions
final_instructions() {
    echo ""
    echo "=============================================="
    echo "AutoPrefixDB Plugin Installation Complete!"
    echo "=============================================="
    echo ""
    echo "Next Steps:"
    echo "1. Restart your web server to apply changes."
    echo "   - For Apache:"
    echo "       sudo systemctl restart apache2"
    echo "   - For Nginx:"
    echo "       sudo systemctl restart nginx"
    echo ""
    echo "2. Log in to phpMyAdmin as a non-root user."
    echo "   - When creating a new database, it should automatically be prefixed with your username."
    echo ""
    echo "3. Verify Database Visibility:"
    echo "   - Users should only see databases with their specific prefixes."
    echo "   - Root user can see all databases without prefixes."
    echo ""
    echo "4. (Optional) Enhance Security:"
    echo "   - Implement input validation in the stored procedure."
    echo "   - Regularly audit user privileges and database access."
    echo ""
    echo "For any issues or further customization, refer to the plugin documentation or contact support."
}

# Main Execution Flow
main() {
    check_phpmyadmin_installed
    create_plugin_file
    copy_plugin
    backup_config
    register_plugin
    set_permissions
    validate_installation
    final_instructions
}

# Run the main function
main 