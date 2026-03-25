-- =============================================
-- 1. CARGA DIM_CUSTOMERS
-- =============================================


INSERT INTO silver_unicorn.dim_customers (customer_id, customer_type, customer_country, customer_city)
WITH customers_raw AS (
    SELECT 
        -- Limpiamos espacios y estandarizamos a minúsculas/mayúsculas
        TRIM(customer_id) AS raw_id,
        LOWER(TRIM(customer_type)) AS clean_type, 
        TRIM(customer_country) AS clean_country,
        TRIM(customer_city) AS clean_city,
        -- Identificamos duplicados en customer_id
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date DESC -- Tomamos la compra más reciente
        ) AS row_num
    FROM bronze_unicorn.ventas_raw
    WHERE customer_id IS NOT NULL
		AND customer_id != ''
		AND customer_id REGEXP '^[0-9]+$' -- Con regexp nos aseguramos que la data sea numerica. Regexp > Like
)
SELECT 
    -- Casteamos, ya tenemos la data normalizada
    CAST(raw_id AS UNSIGNED) AS customer_id,
    clean_type,
    clean_country,
    clean_city
FROM customers_raw
WHERE row_num = 1; -- Nos aseguramos de solo dejar 1 customer_id unico, ya que es PK.


-- =============================================
-- 2. CARGA DIM_PRODUCTS
-- =============================================


INSERT INTO silver_unicorn.dim_products (product_id, product_name, product_category, product_brand)
WITH products_raw AS (
    SELECT 
        TRIM(product_id) AS raw_id,
        
        -- 2. LIMPIEZA DE NOMBRE: "TV Edge 9E72" -> "TV Edge"
        -- Recortamos los últimos 5 caracteres (el espacio y los 4 dígitos)
        CASE 
            WHEN CHAR_LENGTH(TRIM(product_name)) > 5 
            THEN TRIM(LEFT(TRIM(product_name), CHAR_LENGTH(TRIM(product_name)) - 5))
            ELSE TRIM(product_name) 
        END AS clean_product_name,
        LOWER(TRIM(product_category)) AS clean_product_category,
        CASE 
            WHEN TRIM(product_brand) = '' OR product_brand IS NULL THEN 'unbranded'
            ELSE TRIM(product_brand)
        END AS clean_product_brand,
        
        -- 4. DEDUPLICACIÓN POR FECHA: Elegimos la info de la venta más reciente
        ROW_NUMBER() OVER(
            PARTITION BY TRIM(product_id) 
            ORDER BY order_date DESC 
        ) as row_num
    FROM bronze_unicorn.ventas_raw
	WHERE product_id IS NOT NULL 
	AND product_id != ''
	AND product_id REGEXP '^[0-9]+$'
) 
SELECT 
    CAST(raw_id AS UNSIGNED) AS product_id, 
    clean_product_name, 
    clean_product_category, 
    clean_product_brand
FROM products_raw
WHERE row_num = 1;


-- =============================================
-- 3. CARGA DIM_SHIPPING
-- =============================================


INSERT INTO silver_unicorn.dim_shipping (shipping_method, shipping_status)
SELECT 
    LOWER(TRIM(v.shipping_method)) AS method_clean, -- Usamos alias distintos para el SELECT
    LOWER(TRIM(v.shipping_status)) AS status_clean
FROM bronze_unicorn.ventas_raw v -- Le ponemos el alias 'v' a la tabla
WHERE v.shipping_method IS NOT NULL 
  AND TRIM(v.shipping_method) <> '' 
  AND v.shipping_status IS NOT NULL 
  AND TRIM(v.shipping_status) <> ''
GROUP BY method_clean, status_clean; -- Agrupamos por los alias limpios



-- SELECT COUNT(*) FROM silver_unicorn.dim_shipping; // prueba // 
-- =============================================
-- 4. CARGA DIM_ORDERS
-- =============================================


INSERT INTO silver_unicorn.dim_orders (order_id, order_status, sales_channel)
WITH orders_raw AS (
    SELECT 
        TRIM(order_id) AS raw_id,
        LOWER(TRIM(order_status)) AS clean_status, 
        LOWER(TRIM(sales_channel)) AS clean_channel,
        LOWER(TRIM(shipping_status)) AS clean_shipping,
        ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY order_date DESC
        ) AS row_num
    FROM bronze_unicorn.ventas_raw
    WHERE order_id IS NOT NULL
        AND order_id != ''
        AND order_id REGEXP '^[0-9]+$'
)
SELECT 
    CAST(raw_id AS UNSIGNED) AS order_id,
    CASE 
        WHEN clean_status = 'returned' AND clean_shipping IN ('shipped', 'in_transit', 'delayed') 
        THEN 'canceled'
        ELSE clean_status 
    END AS order_status,
    clean_channel
FROM orders_raw
WHERE row_num = 1;


-- =============================================
-- 5. CARGA DIM_PAYMENTS
-- =============================================


INSERT INTO silver_unicorn.dim_payments (payment_method, installments_count)
WITH payments_raw AS (
    SELECT 
        LOWER(TRIM(payment_method)) AS clean_method,
        CASE 
            WHEN LOWER(TRIM(payment_method)) IN ('paypal', 'debit_card', 'bank_transfer') THEN 0
            ELSE ROUND(TRIM(installments_count))
        END AS clean_installments
    FROM bronze_unicorn.ventas_raw
    WHERE payment_method IS NOT NULL
    AND payment_method <> ''
)
SELECT 
	clean_method, 
	CAST(clean_installments AS UNSIGNED) AS installments_count
FROM payments_raw
GROUP BY clean_method, clean_installments;



-- Pequeña prueba

SELECT * FROM silver_unicorn.dim_shipping;
SELECT * FROM silver_unicorn.dim_products;
SELECT * FROM silver_unicorn.dim_payments;
SELECT * FROM silver_unicorn.dim_orders;
SELECT count(*), customer_country, customer_city FROM silver_unicorn.dim_customers group by 2,3;
