#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: mysql-ristrected-access.sh
# Description: Creates a MySQL user with restricted privileges and sets up a
#              stored procedure for controlled database creation with a specific prefix.
# Usage: sudo ./mysql-ristrected-access.sh <action> [parameters]
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage
usage() {
    echo "Usage: sudo $0 <action> [parameters]"
    echo "Actions:"
    echo "  create <username> <password> [db_prefix] - Create a new MySQL user"
    echo "  delete <username> - Delete an existing MySQL user and revoke all privileges"
    exit 1
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    usage
fi

# Check for correct number of arguments
if [ "$#" -lt 2 ]; then
    usage
fi

ACTION="$1"

case "$ACTION" in
    create)
        USERNAME="$2"
        PASSWORD="$3"
        DB_PREFIX="${4:-${USERNAME}_}"

        # MySQL administrative database to store the stored procedure
        ADMIN_DB="admin"

        # Prompt for MySQL root password
        echo "Please enter the MySQL root password:"
        read -s MYSQL_ROOT_PASSWORD
        echo

        # Create a temporary MySQL option file
        TEMP_MY_CNF=$(mktemp)
        chmod 600 "$TEMP_MY_CNF"

        cat > "$TEMP_MY_CNF" <<EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF

        # Function to execute MySQL commands using the temporary option file
        mysql_exec() {
            mysql --defaults-extra-file="$TEMP_MY_CNF" "$@"
        }

        # Create the admin database if it doesn't exist
        mysql_exec -e "CREATE DATABASE IF NOT EXISTS \`${ADMIN_DB}\`;"

        # Create the stored procedure in the admin database
        mysql_exec -D "${ADMIN_DB}" <<'EOF'
DELIMITER $$

-- Drop the procedure if it already exists
DROP PROCEDURE IF EXISTS create_prefixed_db$$
DROP PROCEDURE IF EXISTS delete_prefixed_db$$

-- Create the stored procedure
CREATE PROCEDURE create_prefixed_db(IN db_name VARCHAR(64))
BEGIN
    DECLARE prefix VARCHAR(64);
    DECLARE prefixed_db VARCHAR(128);
    DECLARE stmt TEXT;
    DECLARE grant_stmt TEXT;

    -- Extract the username from CURRENT_USER()
    SET prefix = CONCAT(SUBSTRING_INDEX(CURRENT_USER(), '@', 1), '_');

    -- Create the prefixed database name
    SET prefixed_db = CONCAT(prefix, db_name);

    -- Prepare and execute the CREATE DATABASE statement
    SET @stmt = CONCAT('CREATE DATABASE `', prefixed_db, '`');
    PREPARE stmt FROM @stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Grant all privileges on the new database to the user
    SET @grant_stmt = CONCAT('GRANT ALL PRIVILEGES ON `', prefixed_db, '`.* TO \'', SUBSTRING_INDEX(CURRENT_USER(), '@', 1), '\'@\'localhost\'');
    PREPARE grant_stmt FROM @grant_stmt;
    EXECUTE grant_stmt;
    DEALLOCATE PREPARE grant_stmt;
END$$

-- Create the delete_prefixed_db stored procedure
CREATE PROCEDURE delete_prefixed_db(IN db_name VARCHAR(64))
BEGIN
    DECLARE prefix VARCHAR(64);
    DECLARE prefixed_db VARCHAR(128);
    DECLARE stmt TEXT;

    -- Extract the username from CURRENT_USER()
    SET prefix = CONCAT(SUBSTRING_INDEX(CURRENT_USER(), '@', 1), '_');

    -- Create the prefixed database name
    SET prefixed_db = CONCAT(prefix, db_name);

    -- Prepare and execute the DROP DATABASE statement
    SET @stmt = CONCAT('DROP DATABASE IF EXISTS `', prefixed_db, '`');
    PREPARE stmt FROM @stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;
EOF

        echo "Stored procedures 'create_prefixed_db' and 'delete_prefixed_db' created in database '${ADMIN_DB}'."

        # Create the MySQL user with no global privileges
        mysql_exec -e "CREATE USER IF NOT EXISTS '${USERNAME}'@'localhost' IDENTIFIED BY '${PASSWORD}';"

        echo "MySQL user '${USERNAME}'@'localhost' created."

        # Grant execute privilege on the stored procedure to the user
        mysql_exec -e "GRANT EXECUTE ON PROCEDURE \`${ADMIN_DB}\`.create_prefixed_db TO '${USERNAME}'@'localhost';"
        mysql_exec -e "GRANT EXECUTE ON PROCEDURE \`${ADMIN_DB}\`.delete_prefixed_db TO '${USERNAME}'@'localhost';"

        echo "Granted EXECUTE privilege on 'create_prefixed_db' and 'delete_prefixed_db' to '${USERNAME}'@'localhost'."

        # Revoke any global privileges the user might have
        mysql_exec -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${USERNAME}'@'localhost';"

        echo "Revoked any existing global privileges from '${USERNAME}'@'localhost'."

        # Grant privileges on databases with the specific prefix
        mysql_exec -e "GRANT ALL PRIVILEGES ON \`${DB_PREFIX}%\`.* TO '${USERNAME}'@'localhost';"

        echo "Granted ALL PRIVILEGES on databases with prefix '${DB_PREFIX}' to '${USERNAME}'@'localhost'."

        # Revoke the CREATE privilege to prevent direct database creation
        mysql_exec -e "REVOKE CREATE ON *.* FROM '${USERNAME}'@'localhost';"

        echo "Revoked CREATE privilege from '${USERNAME}'@'localhost'."

        # Flush privileges to apply changes
        mysql_exec -e "FLUSH PRIVILEGES;"

        echo "Privileges flushed."

        # Remove the temporary MySQL option file
        rm -f "$TEMP_MY_CNF"

        # Final Instructions
        echo ""
        echo "User '${USERNAME}' has been successfully created with restricted privileges."
        echo "To create a new database, the user must call the 'create_prefixed_db' stored procedure."
        echo "Example usage from MySQL shell:"
        echo "CALL \`${ADMIN_DB}\`.create_prefixed_db('newdatabase');"
        echo ""
        echo "To delete a database, the user must call the 'delete_prefixed_db' stored procedure."
        echo "Example usage from MySQL shell:"
        echo "CALL \`${ADMIN_DB}\`.delete_prefixed_db('newdatabase');"
        echo ""
        echo "Ensure that phpMyAdmin users execute the stored procedures for creating and deleting databases."
        ;;
    delete)
        USERNAME="$2"
        
        # Prompt for MySQL root password
        echo "Please enter the MySQL root password:"
        read -s MYSQL_ROOT_PASSWORD
        echo

        # Create a temporary MySQL option file
        TEMP_MY_CNF=$(mktemp)
        chmod 600 "$TEMP_MY_CNF"

        cat > "$TEMP_MY_CNF" <<EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF

        # Function to execute MySQL commands using the temporary option file
        mysql_exec() {
            mysql --defaults-extra-file="$TEMP_MY_CNF" "$@"
        }

        # Revoke all privileges and delete the user
        mysql_exec -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${USERNAME}'@'localhost';"
        echo "Revoked all privileges from '${USERNAME}'@'localhost'."

        mysql_exec -e "DROP USER IF EXISTS '${USERNAME}'@'localhost';"
        echo "Deleted user '${USERNAME}'@'localhost'."

        # Flush privileges to apply changes
        mysql_exec -e "FLUSH PRIVILEGES;"
        echo "Privileges flushed."

        # Remove the temporary MySQL option file
        rm -f "$TEMP_MY_CNF"
        ;;
    *)
        usage
        ;;
esac
