#!/usr/bin/env bash

set -e
set -o pipefail
set -u

echo "Starting database activity simulation against RDS..."

# Get credentials from Secrets Manager
echo "[db-activity] Reading credentials from AWS Secrets Manager"
secret=$(aws --region "$REGION" secretsmanager get-secret-value --secret-id="$SECRET_ARN")
DB_USER=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
DB_PASS=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

# Use exampledb namespace
NAMESPACE="exampledb"

# Ensure namespace exists
echo "[db-activity] Ensuring $NAMESPACE namespace exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create a temporary pod to run psql commands
POD_NAME="db-activity-sim-$(date +%s)"

echo "[db-activity] Creating temporary postgres client pod in $NAMESPACE namespace..."
kubectl run "$POD_NAME" \
  --namespace="$NAMESPACE" \
  --image=postgres:15-alpine \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASS" \
  --env="PGHOST=$DB_HOST" \
  --env="PGPORT=$DB_PORT" \
  --env="PGUSER=$DB_USER" \
  --env="PGDATABASE=$DB_NAME" \
  --command -- sleep 1800

echo "[db-activity] Waiting for pod to be ready (up to 120s)..."
if ! kubectl wait --namespace="$NAMESPACE" --for=condition=Ready pod/"$POD_NAME" --timeout=120s; then
    echo "[db-activity] Pod not ready, checking status..."
    kubectl describe pod "$POD_NAME" --namespace="$NAMESPACE"
    kubectl logs "$POD_NAME" --namespace="$NAMESPACE" || true
    exit 1
fi

# Cleanup function
cleanup() {
    echo "[db-activity] Cleaning up temporary pod..."
    kubectl delete pod "$POD_NAME" --namespace="$NAMESPACE" --ignore-not-found=true
}
trap cleanup EXIT

# Check if PostgreSQL is ready
echo "[db-activity] Checking RDS connectivity..."
if ! kubectl exec -n "$NAMESPACE" "$POD_NAME" -- psql -c "SELECT 1" > /dev/null 2>&1; then
    echo "RDS PostgreSQL not ready, exiting..."
    exit 1
fi

echo "[db-activity] Creating schema and seed data..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- psql -c "
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_log(created_at);
"

echo "[db-activity] Inserting seed data..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- psql -c "
-- Insert seed data (10K users, 5K products)
INSERT INTO users (name, email, age, city) 
SELECT 
    'User' || g,
    'user' || g || '@example.com',
    (random() * 60 + 18)::int,
    (ARRAY['NYC', 'LA', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'])[floor(random() * 10 + 1)]
FROM generate_series(1,10000) g
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (name, category, price, stock)
SELECT 
    'Product ' || g,
    (ARRAY['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Beauty', 'Automotive', 'Food'])[floor(random() * 8 + 1)],
    round((random() * 1000 + 10)::numeric, 2),
    floor(random() * 1000)::int
FROM generate_series(1,5000) g;

-- Insert historical orders (50K records)
INSERT INTO orders (user_id, product_id, quantity, amount, status, created_at)
SELECT 
    floor(random() * 10000 + 1)::int,
    floor(random() * 5000 + 1)::int,
    floor(random() * 5 + 1)::int,
    round((random() * 500 + 10)::numeric, 2),
    (ARRAY['pending', 'completed', 'cancelled', 'refunded'])[floor(random() * 4 + 1)],
    NOW() - (random() * interval '30 days')
FROM generate_series(1,50000) g;
"

echo "[db-activity] Running activity bursts..."
for cycle in $(seq 1 25); do
    echo "=== Cycle $cycle/25 ==="
    
    kubectl exec -n "$NAMESPACE" "$POD_NAME" -- psql -c "
    -- Read operations
    SELECT COUNT(*) FROM users WHERE city = 'NYC';
    SELECT * FROM products WHERE stock > 0 ORDER BY price DESC LIMIT 1000;
    SELECT u.name, COUNT(o.id) FROM users u LEFT JOIN orders o ON u.id = o.user_id GROUP BY u.id LIMIT 500;
    
    -- Write operations
    INSERT INTO sessions (user_id, session_token, ip_address) 
    SELECT floor(random() * 10000 + 1)::int, md5(random()::text), ('10.0.' || floor(random() * 255) || '.' || floor(random() * 255))::inet
    FROM generate_series(1, 50);
    
    INSERT INTO orders (user_id, product_id, quantity, amount, status) 
    SELECT floor(random() * 10000 + 1)::int, floor(random() * 5000 + 1)::int, floor(random() * 10 + 1)::int, round((random() * 1000)::numeric, 2), 'pending'
    FROM generate_series(1, 25);
    
    UPDATE products SET stock = stock - 1 WHERE id IN (SELECT id FROM products WHERE stock > 10 ORDER BY random() LIMIT 100);
    DELETE FROM sessions WHERE last_activity < NOW() - interval '2 hours' AND random() < 0.5;
    " > /dev/null 2>&1
    
    sleep 10
done

echo "[db-activity] Activity simulation completed!"
echo "Check your Grafana dashboard to see the database metrics."
