CREATE OR REPLACE VIEW gold_unicorn.vw_commercial_due_diligence AS
SELECT 
    -- Dimensiones Temporales
    f.order_date,
    YEAR(f.order_date) AS order_year,
    DATE_FORMAT(f.order_date, '%Y-%m') AS order_month,
    -- Dimensiones de Producto
    p.product_name,
    p.product_category,
    p.product_brand,
    -- Dimensiones de Cliente y Venta
    c.customer_id,
    c.customer_type,
    c.customer_country,
    o.order_id,
    o.sales_channel,
    pay.payment_method,
    -- Métricas de Dinero
    f.quantity,
    (f.quantity * f.unit_price) AS revenue_bruto,
    (f.quantity * f.unit_price * (1 - f.discount_rate)) AS revenue_neto,
    (f.product_cost * f.quantity) AS costo_total,
    f.discount_rate,
    f.delivery_days,
    -- Lógica de Negocio Pre-calculada
    CASE WHEN f.discount_rate > 0 THEN 'Con Descuento' ELSE 'Sin Descuento' END AS discount_type,
    ((f.quantity * f.unit_price * (1 - f.discount_rate)) - (f.product_cost * f.quantity)) AS utilidad_neta
FROM silver_unicorn.fact_sales f
JOIN silver_unicorn.dim_products p ON f.product_id = p.product_id
JOIN silver_unicorn.dim_orders o ON f.order_id = o.order_id
JOIN silver_unicorn.dim_customers c ON f.customer_id = c.customer_id
JOIN silver_unicorn.dim_payments pay ON f.payment_id = pay.payment_id;


-- ANALISIS DE NEGOCIO


-- Bloque de Rentabilidad General (Métricas Base)
-- Resumen Ejecutivo: Todo el dinero en una sola consulta
SELECT 
    order_year,
    SUM(revenue_bruto) AS total_revenue,
    SUM(revenue_neto) AS total_revenue_net,
    SUM(costo_total) AS total_cost,
    SUM(revenue_bruto - costo_total) AS gross_profit,
    SUM(utilidad_neta) AS gross_profit_net,
    ROUND((SUM(revenue_bruto - costo_total) / SUM(revenue_bruto)) * 100, 2) AS margin_percentage,
    ROUND((SUM(utilidad_neta) / SUM(revenue_neto)) * 100, 2) AS margin_percentage_net
FROM gold_unicorn.vw_commercial_due_diligence
GROUP BY order_year
ORDER BY order_year;


-- Bloque de Dimensiones (Categoría, Marca, Canal, País, Pago)
-- Se puede cambiar 'product_category' por cualquiera de las dimensiones mencionadas arriba
SELECT 
    product_category, 
    SUM(revenue_neto) AS revenue,
    SUM(utilidad_neta) AS profit,
    ROUND((SUM(utilidad_neta) / SUM(revenue_neto)) * 100, 2) AS margin_pct
FROM gold_unicorn.vw_commercial_due_diligence
GROUP BY product_category
ORDER BY profit DESC;


-- Bloque de Descuentos y Elasticidad
SELECT 
    CASE 
        WHEN discount_rate = 0 THEN 'No Discount'
        WHEN discount_rate <= 0.10 THEN '0-10%'
        WHEN discount_rate <= 0.20 THEN '10-20%'
        ELSE '20%+'
    END AS discount_band,
    SUM(revenue_neto) AS revenue,
    SUM(quantity) AS units_sold
FROM gold_unicorn.vw_commercial_due_diligence
GROUP BY discount_band
ORDER BY revenue DESC;


-- Bloque de Productos y Pareto
-- Top de Productos
SELECT product_name, 
	SUM(quantity) as unidades, 
	SUM(revenue_neto) as revenue
FROM gold_unicorn.vw_commercial_due_diligence
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;


-- Bloque de Clientes y Ticket Promedio
-- Ticket Promedio
WITH orders_total AS (
    SELECT 
        order_id, 
        SUM(revenue_neto) AS total_por_orden
    FROM gold_unicorn.vw_commercial_due_diligence
    GROUP BY order_id
)
SELECT 
    ROUND(AVG(total_por_orden), 2) AS avg_order_value
FROM orders_total;

-- Recurrencia
WITH customer_loyalty AS (
    SELECT 
        customer_id, 
        COUNT(DISTINCT order_id) AS total_pedidos 
    FROM gold_unicorn.vw_commercial_due_diligence 
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_pedidos = 1 THEN 'One-time' 
        ELSE 'Repeat' 
    END AS loyalty_type,
    COUNT(*) AS count_customers
FROM customer_loyalty
GROUP BY loyalty_type;


-- Bloque Logístico-Comercial
SELECT 
    CASE
        WHEN delivery_days <= 3 THEN 'Fast'
        WHEN delivery_days <= 7 THEN 'Normal'
        ELSE 'Slow'
    END AS delivery_speed,
    SUM(revenue_neto) AS revenue,
    SUM(utilidad_neta) AS profit
FROM gold_unicorn.vw_commercial_due_diligence
GROUP BY delivery_speed;








