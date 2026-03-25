-- creo schema donde va mi data
CREATE SCHEMA bronze_unicorn;
USE bronze_unicorn;
-- schema: bronze_unicorn
CREATE TABLE IF NOT EXISTS bronze_unicorn.ventas_raw (
    -- Trazabilidad (rastreo historico de la metadata)
    _extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- cuando cargo la data y filtrar cargas fallidas
    _source_file VARCHAR(255) DEFAULT 'unicorncsv.csv', -- identificar ingesta de archivos
    
    -- Columnas del CSV como VARCHAR/TEXT para que NO falle el casting
    order_id VARCHAR(255),
    item_id VARCHAR(255),
    order_date VARCHAR(255),         -- Lo cargamos como texto, el DATE se hace en Silver
    order_status VARCHAR(255),
    sales_channel VARCHAR(255),
    customer_id VARCHAR(255),
    customer_type VARCHAR(255),
    customer_country VARCHAR(255),
    customer_city VARCHAR(255),
    product_id VARCHAR(255),
    product_name TEXT,               -- TEXT por si el nombre es muy largo
    product_category VARCHAR(255),
    product_brand VARCHAR(255),
    unit_price VARCHAR(255),         -- No DECIMAL aún
    product_cost VARCHAR(255),
    quantity VARCHAR(255),
    gross_amount VARCHAR(255),
    discount_rate VARCHAR(255),
    net_amount VARCHAR(255),
    shipping_method VARCHAR(255),
    shipping_cost VARCHAR(255),
    shipping_status VARCHAR(255),
    delivery_days VARCHAR(255),
    payment_method VARCHAR(255),
    installments_count VARCHAR(255),
    _rescued_data TEXT
);