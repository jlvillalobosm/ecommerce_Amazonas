-- #############################################################
-- CARGA FACT_SALES
-- #############################################################


INSERT INTO silver_unicorn.fact_sales (
    item_id, order_id, customer_id, product_id, shipping_id, 
    payment_id, order_date, quantity, unit_price, product_cost, 
    discount_rate, shipping_cost, delivery_days
)
WITH sales_raw AS (
    SELECT 
        TRIM(item_id) as clean_item_id,
        CAST(TRIM(order_id) AS UNSIGNED) as clean_order_id,
        CAST(TRIM(customer_id) AS UNSIGNED) as clean_customer_id,
        CAST(TRIM(product_id) AS UNSIGNED) as clean_product_id,
        LOWER(TRIM(shipping_method)) as clean_ship_method,
        LOWER(TRIM(shipping_status)) as clean_ship_status,
        LOWER(TRIM(payment_method)) as clean_pay_method,
        -- Limpieza de Cuotas (Elimina el .0)
        CASE 
            WHEN LOWER(TRIM(payment_method)) IN ('paypal', 'debit_card', 'bank_transfer') THEN 0
            ELSE ROUND(NULLIF(TRIM(installments_count), '')) -- nullif en caso de que haya '' lo tome como null y round no rompa
        END as clean_installments,
        -- Limpieza de Cantidad y Días de Entrega
        ROUND(NULLIF(TRIM(quantity), '')) as clean_quantity,
        ROUND(NULLIF(TRIM(delivery_days), '')) as clean_delivery_days,
        order_date, unit_price, product_cost, discount_rate, shipping_cost
    FROM bronze_unicorn.ventas_raw
    WHERE item_id REGEXP '^IT[0-9]{8}$'
    AND item_id IS NOT NULL
    AND TRIM(item_id) <> ''
)
SELECT 
    sr.clean_item_id,
    sr.clean_order_id,
    sr.clean_customer_id,
    sr.clean_product_id,
    s.shipping_id,
    pay.payment_id,
    STR_TO_DATE(sr.order_date, '%Y-%m-%d'), 
    CAST(sr.clean_quantity AS UNSIGNED),
    CAST(sr.unit_price AS DECIMAL(15,2)),
    CAST(sr.product_cost AS DECIMAL(15,2)),
    CAST(sr.discount_rate AS DECIMAL(10,4)),
    CAST(sr.shipping_cost AS DECIMAL(15,2)),
    CAST(sr.clean_delivery_days AS UNSIGNED) 
FROM sales_raw sr
INNER JOIN silver_unicorn.dim_orders o ON sr.clean_order_id = o.order_id
INNER JOIN silver_unicorn.dim_products p ON sr.clean_product_id = p.product_id
INNER JOIN silver_unicorn.dim_customers c ON sr.clean_customer_id = c.customer_id
INNER JOIN silver_unicorn.dim_shipping s 
    ON sr.clean_ship_method = s.shipping_method 
    AND sr.clean_ship_status = s.shipping_status
INNER JOIN silver_unicorn.dim_payments pay 
    ON sr.clean_pay_method = pay.payment_method 
    AND sr.clean_installments = pay.installments_count;
    

-- Pequeño test

SELECT * from silver_unicorn.fact_sales limit 50;


SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) as total_ventas,
    MIN(f.unit_price) as precio_min, 
    MAX(f.unit_price) as precio_max  
FROM silver_unicorn.fact_sales f
JOIN silver_unicorn.dim_products p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) > 1
LIMIT 10;

use silver_unicorn;

select count(f.item_id), order_status
from fact_sales f
join dim_orders o ON f.order_id = o.order_id
group by o.order_status;

