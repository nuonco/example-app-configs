---
apiVersion: v1
kind: ConfigMap
metadata:
  name: temporal-init
  namespace: temporal
data:
  init_temporal_db.sh: |
    #!/bin/sh
    # already in env: SQL_HOST, SQL_PORT, SQL_USER, SQL_PASSWORD, SQL_PLUGIN
    temporal-sql-tool --db temporal create;
    temporal-sql-tool --db temporal setup-schema -v 0.0;
    temporal-sql-tool --db temporal update-schema -d ./schema/postgresql/v12/temporal/versioned/;
  init_visibility_db.sh: |
    #!/bin/sh
    # already in env: SQL_HOST, SQL_PORT, SQL_USER, SQL_PASSWORD, SQL_PLUGIN
    temporal-sql-tool --db temporal_visibility create;
    temporal-sql-tool --db temporal_visibility setup-schema -v 0.0;
    temporal-sql-tool --db temporal_visibility update-schema -d ./schema/postgresql/v12/visibility/versioned/;
  create_db_users.sh: |
    #!/bin/bash
    # idempotent script for the creation of a dedicated DB user for temporal

    # Configuration
    DATABASE="$1"
    USERNAME="$2"
    PASSWORD="$3"

    # Function to print colored output
    print_status() {
        echo -e "[INFO] $1"
    }

    print_warning() {
        echo -e "[WARNING] $1"
    }

    print_error() {
        echo -e "[ERROR] $1"
    }

    # Function to check if PostgreSQL is running
    check_postgres() {
        if ! pg_isready -q; then
            print_error "PostgreSQL is not running or not accessible"
            exit 1
        fi
        print_status "PostgreSQL is running"
    }

    # Function to check if user exists
    user_exists() {
        local user_count=$(psql -t -c "SELECT COUNT(*) FROM pg_user WHERE usename='$USERNAME';" 2>/dev/null | xargs)
        if [[ "$user_count" == "1" ]]; then
            return 0
        else
            return 1
        fi
    }

    # Function to check if database exists
    database_exists() {
        local db_count=$(psql -t -c "SELECT COUNT(*) FROM pg_database WHERE datname='$DATABASE';" 2>/dev/null | xargs)
        if [[ "$db_count" == "1" ]]; then
            return 0
        else
            return 1
        fi
    }

    # Function to create user
    create_user() {
        if user_exists; then
            print_warning "User '$USERNAME' already exists"
            # Update password in case it changed
            psql -c "ALTER USER $USERNAME WITH PASSWORD '$PASSWORD';" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                print_status "Password updated for user '$USERNAME'"
            else
                print_error "Failed to update password for user '$USERNAME'"
                return 1
            fi
        else
            print_status "Creating user '$USERNAME'"
            psql -c "CREATE USER $USERNAME WITH LOGIN PASSWORD '$PASSWORD';" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                print_status "User '$USERNAME' created successfully"
            else
                print_error "Failed to create user '$USERNAME'"
                return 1
            fi
        fi
        return 0
    }

    # Function to create database
    create_database() {
        if database_exists; then
            print_warning "Database '$DATABASE' already exists"
        else
            print_status "Creating database '$DATABASE'"
            psql -c "CREATE DATABASE $DATABASE;" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                print_status "Database '$DATABASE' created successfully"
            else
                print_error "Failed to create database '$DATABASE'"
                return 1
            fi
        fi
        return 0
    }

    # Function to grant privileges
    grant_privileges() {
        print_status "Granting privileges to user '$USERNAME' on database '$DATABASE'"

        # Grant connect privilege
        psql -c "GRANT CONNECT ON DATABASE $DATABASE TO $USERNAME;" > /dev/null 2>&1

        # Grant usage on schema public
        psql -d "$DATABASE" -c "GRANT USAGE ON SCHEMA public TO $USERNAME;" > /dev/null 2>&1

        # Grant create on schema public
        psql -d "$DATABASE" -c "GRANT CREATE ON SCHEMA public TO $USERNAME;" > /dev/null 2>&1

        # Grant all privileges on all tables in public schema
        psql -d "$DATABASE" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $USERNAME;" > /dev/null 2>&1

        # Grant all privileges on all sequences in public schema
        psql -d "$DATABASE" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $USERNAME;" > /dev/null 2>&1

        # Grant default privileges for future tables
        psql -d "$DATABASE" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $USERNAME;" > /dev/null 2>&1

        # Grant default privileges for future sequences
        psql -d "$DATABASE" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $USERNAME;" > /dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            print_status "Privileges granted successfully"
        else
            print_error "Failed to grant some privileges"
            return 1
        fi

        return 0
    }

    # Function to verify setup
    verify_setup() {
        print_status "Verifying setup..."

        # Test connection as the new user
        PGPASSWORD="$PASSWORD" PGUSER="$USERNAME" psql -d "$DATABASE" -c "select 1;" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            print_status "✓ User '$USERNAME' can connect to database '$DATABASE'"
        else
            print_error "✗ User '$USERNAME' cannot connect to database '$DATABASE'"
            return 1
        fi

        return 0
    }

    # Main execution
    main() {
        print_status "Starting PostgreSQL user and database setup"
        print_status "Username: $USERNAME"
        print_status "Database: $DATABASE"

        # Check PostgreSQL availability
        check_postgres || exit 1

        # Create user
        create_user || exit 1

        # Create database
        create_database || exit 1

        # Grant privileges
        grant_privileges || exit 1

        # Verify setup
        verify_setup || exit 1

        print_status "Setup completed successfully!"
    }

    # Run main function
    main "$@"
