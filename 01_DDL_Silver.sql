-- Hacemos la creacion de nuestro nuevo schema silver
CREATE SCHEMA IF NOT EXISTS silver_unicorn;

USE silver_unicorn;

-- Vamos a definir Facts y Dims
-- Empezamos con Dims

-- Clientes
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    customer_type VARCHAR(50),
    customer_country VARCHAR(100),
    customer_city VARCHAR(100)
);

-- Productos
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    product_category VARCHAR(100),
    product_brand VARCHAR(100)
);

-- Ordenes
CREATE TABLE dim_orders (
    order_id INT PRIMARY KEY,
    order_status VARCHAR(50),
    sales_channel VARCHAR(50)
);

-- Envios
CREATE TABLE dim_shipping (
    shipping_id INT AUTO_INCREMENT PRIMARY KEY, -- Generamos id nuevo ya que debemos conectar a facts en nuestro modelo star
    shipping_method VARCHAR(100),
    shipping_status VARCHAR(50)
);
-- Luego haremos el llamadado FK (shipping_id) en Facts 

-- Pagos
CREATE TABLE dim_payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY, -- igual a shipping_id
    payment_method VARCHAR(100),
    installments_count INT 
);
-- Luego haremos el llamadado FK (payment_id) en Facts


-- Tabla de Facts (La que conecta todo)
CREATE TABLE fact_sales (
    item_id VARCHAR(50) PRIMARY KEY, -- PK original en bronze
    order_id INT,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    unit_price DECIMAL(15,2),
    product_cost DECIMAL(15,2),
    gross_amount DECIMAL(15,2),
    discount_rate DECIMAL(10,4),
    net_amount DECIMAL(15,2),
    shipping_cost DECIMAL(15,2),
    delivery_days INT
);

-- conexion de nuestras tablas, fk tmb en las 2 nuevas columnas
ALTER TABLE silver_unicorn.fact_sales 

    ADD FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    ADD FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    ADD FOREIGN KEY (order_id) REFERENCES dim_orders(order_id),
    ADD FOREIGN KEY (shipping_id) REFERENCES dim_shipping(shipping_id),
    ADD FOREIGN KEY (payment_id) REFERENCES dim_payments(payment_id);
    


CREATE TABLE IF NOT EXIST ventas_import (
    order_id INT,
    item_id VARCHAR(50),
    order_date DATE,
    order_status VARCHAR(50),
    sales_channel VARCHAR(50),
    customer_id INT,
    customer_type VARCHAR(50),
    customer_country VARCHAR(100),
    customer_city VARCHAR(100),
    product_id INT,
    product_name VARCHAR(255),
    product_category VARCHAR(100),
    product_brand VARCHAR(100),
    unit_price DECIMAL(10,2),
    product_cost DECIMAL(10,2),
    quantity INT,
    gross_amount DECIMAL(15,2),
    discount_rate DECIMAL(10,4),
    net_amount DECIMAL(15,2),
    shipping_method VARCHAR(100),
    shipping_cost DECIMAL(10,2),
    shipping_status VARCHAR(50),
    delivery_days DECIMAL(5,1),
    payment_method VARCHAR(50),
	installments_count INT;