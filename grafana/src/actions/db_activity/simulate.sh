#!/usr/bin/env bash

set -e
set -o pipefail
set -u

echo "Starting INTENSIVE database activity simulation against RDS..."

# Get credentials from Secrets Manager
echo "[db-activity] Reading credentials from AWS Secrets Manager"
secret=$(aws --region "$REGION" secretsmanager get-secret-value --secret-id="$SECRET_ARN")
DB_USER=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
DB_PASS=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

export PGPASSWORD="$DB_PASS"

# Function to run psql command
run_psql() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$1"
}

# Check if PostgreSQL is ready
echo "Checking if RDS PostgreSQL is ready..."
if run_psql "SELECT 1" > /dev/null 2>&1; then
    echo "RDS PostgreSQL is ready, proceeding..."
else
    echo "RDS PostgreSQL not ready, exiting..."
    exit 1
fi

# Create comprehensive schema and large seed data (idempotent)
echo "Creating schema and seed data..."
run_psql "
-- Create comprehensive schema (safe for repeated runs)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    age INTEGER,
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER,
    amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    session_token VARCHAR(100),
    ip_address INET,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    action VARCHAR(20),
    old_data JSONB,
    new_data JSONB,
    user_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance testing (safe for repeated runs)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_log(created_at);

-- Insert substantial seed data (10K users, 5K products)
INSERT INTO users (name, email, age, city) 
SELECT 
    'User' || generate_series(1,10000),
    'user' || generate_series(1,10000) || '@example.com',
    (random() * 60 + 18)::int,
    (ARRAY['NYC', 'LA', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'])[floor(random() * 10 + 1)]
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (name, category, price, stock)
SELECT 
    'Product ' || generate_series(1,5000),
    (ARRAY['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Beauty', 'Automotive', 'Food'])[floor(random() * 8 + 1)],
    round((random() * 1000 + 10)::numeric, 2),
    floor(random() * 1000)::int;

-- Insert historical orders (50K records)
INSERT INTO orders (user_id, product_id, quantity, amount, status, created_at)
SELECT 
    floor(random() * 10000 + 1)::int,
    floor(random() * 5000 + 1)::int,
    floor(random() * 5 + 1)::int,
    round((random() * 500 + 10)::numeric, 2),
    (ARRAY['pending', 'completed', 'cancelled', 'refunded'])[floor(random() * 4 + 1)],
    NOW() - (random() * interval '30 days');
"

echo "Schema created. Starting fluctuating activity..."

# Create a marker to check for stop signal
STOP_MARKER="/tmp/stop_db_simulation_$$"

# Function to run INTENSIVE burst of activity
run_activity_burst() {
    local intensity=$1
    echo "Running INTENSIVE burst with intensity: $intensity"
    
    for i in $(seq 1 $intensity); do
        run_psql "
        -- ROWS OPERATIONS
        SELECT * FROM users ORDER BY id LIMIT 5000;
        SELECT * FROM products WHERE stock > 0 ORDER BY price DESC LIMIT 3000;
        SELECT * FROM orders WHERE created_at >= NOW() - interval '7 days' LIMIT 8000;
        
        -- Complex JOINs
        SELECT u.*, o.*, p.* FROM users u 
        JOIN orders o ON u.id = o.user_id 
        JOIN products p ON o.product_id = p.id 
        WHERE o.created_at >= NOW() - interval '1 day'
        LIMIT 2000;
        
        -- INSERTS
        INSERT INTO sessions (user_id, session_token, ip_address, last_activity) 
        SELECT 
            floor(random() * 10000 + 1)::int,
            md5(random()::text),
            ('10.0.' || floor(random() * 255) || '.' || floor(random() * 255))::inet,
            NOW() - (random() * interval '1 hour')
        FROM generate_series(1, 100);
        
        INSERT INTO orders (user_id, product_id, quantity, amount, status) 
        SELECT 
            floor(random() * 10000 + 1)::int,
            floor(random() * 5000 + 1)::int,
            floor(random() * 10 + 1)::int,
            round((random() * 1000)::numeric, 2),
            (ARRAY['pending','processing','shipped'])[floor(random() * 3 + 1)]
        FROM generate_series(1, 75);
        
        -- UPDATES
        UPDATE products SET stock = stock - floor(random() * 5)::int 
        WHERE id IN (SELECT id FROM products WHERE stock > 10 ORDER BY random() LIMIT 500);
        
        UPDATE users SET updated_at = NOW() 
        WHERE id IN (SELECT id FROM users ORDER BY random() LIMIT 300);
        
        -- DELETES
        DELETE FROM sessions WHERE last_activity < NOW() - interval '4 hours' AND random() < 0.3;
        DELETE FROM audit_log WHERE created_at < NOW() - interval '1 day' AND random() < 0.1;
        
        -- CACHE activity
        SELECT COUNT(*) FROM users WHERE city = 'NYC';
        SELECT COUNT(*) FROM users WHERE city = 'LA';
        SELECT AVG(amount) FROM orders WHERE created_at >= NOW() - interval '1 week';
        " > /dev/null 2>&1 &
        
        sleep 0.1
    done
    
    echo "Burst initiated with $intensity background processes"
}

# Intensive simulation over 25 minutes
echo "Starting 25-minute INTENSIVE fluctuating load simulation..."
echo "This will create significant database load - monitor your dashboards!"

for cycle in $(seq 1 50); do
    # Check for stop signal
    if [ -f "$STOP_MARKER" ]; then
        echo "Stop signal detected, ending simulation..."
        rm -f "$STOP_MARKER"
        break
    fi
    
    echo "=== Cycle $cycle/50 ==="
    
    # Intensity waves
    case $((cycle % 8)) in
        0|1) intensity=5 ;;
        2|3) intensity=10 ;;
        4|5) intensity=20 ;;
        6) intensity=30 ;;
        7) intensity=15 ;;
    esac
    
    # Add random spikes
    if [ $((RANDOM % 10)) -eq 0 ]; then
        intensity=$((intensity + 10))
        echo "*** RANDOM SPIKE: intensity boosted to $intensity ***"
    fi
    
    run_activity_burst $intensity
    
    # Rest period
    rest_time=$((5 + (cycle % 3) * 5))
    echo "Brief rest for ${rest_time}s before next burst..."
    sleep $rest_time
done

echo "Activity simulation completed!"
echo "Check your Grafana dashboard to see the fluctuating database metrics."
