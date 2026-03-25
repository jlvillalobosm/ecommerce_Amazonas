
-- ANALISIS DE LA OPERACIÓN

CREATE SCHEMA IF NOT EXISTS gold_unicorn;

CREATE OR REPLACE VIEW gold_unicorn.vw_logistics_performance AS
SELECT 
    o.sales_channel,
    s.shipping_method,
    s.shipping_status,
    c.customer_city,
    c.customer_country,
    DATE_FORMAT(f.order_date, '%Y-%m') AS mes_orden,
    -- Métricas de Volumen
    COUNT(f.item_id) AS volumen_items,
    -- Métricas de Costos
    ROUND(AVG(f.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(SUM(f.shipping_cost), 2) AS total_shipping_cost,
    -- Métricas de Tiempo
    ROUND(AVG(f.delivery_days), 2) AS avg_delivery_days,
    MAX(f.delivery_days) AS max_delivery_days,
    -- Métricas de Calidad (KPIs)
    ROUND(SUM(CASE WHEN f.delivery_days <= 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_sla_cumplimiento,
    ROUND(COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) * 100.0 / COUNT(*), 2) AS tasa_cancelacion_pct,
    ROUND(COUNT(CASE WHEN o.order_status = 'returned' THEN 1 END) * 100.0 / COUNT(*), 2) AS tasa_retorno_pct
FROM silver_unicorn.fact_sales f
JOIN silver_unicorn.dim_orders o ON f.order_id = o.order_id
JOIN silver_unicorn.dim_shipping s ON f.shipping_id = s.shipping_id
JOIN silver_unicorn.dim_customers c ON f.customer_id = c.customer_id
GROUP BY 1, 2, 3, 4, 5, 6;


-- ANALISIS DE NEGOCIO

-- Resumen de costos y tiempos
SELECT 
    ROUND(AVG(avg_shipping_cost), 2) AS costo_promedio_total,
    MAX(max_delivery_days) AS max_espera_registrada,
    ROUND(AVG(avg_delivery_days), 2) AS promedio_dias_envio,
    SUM(volumen_items) AS total_operaciones
FROM gold_unicorn.vw_logistics_performance;


-- Distribución de Estados (Eficiencia de entrega)
SELECT 
    shipping_status,
    SUM(volumen_items) AS cantidad,
    ROUND(SUM(volumen_items) * 100.0 / SUM(SUM(volumen_items)) OVER(), 2) AS porcentaje
FROM gold_unicorn.vw_logistics_performance
GROUP BY shipping_status
ORDER BY porcentaje DESC;


-- Eficiencia Geografica y Customer
SELECT 
    customer_country,
    customer_city,
    shipping_method,
    avg_delivery_days,
    pct_sla_cumplimiento AS porcentaje_exito_3_dias
FROM gold_unicorn.vw_logistics_performance
WHERE avg_delivery_days > 7 -- Enfocarnos en los lentos
ORDER BY avg_delivery_days DESC;


-- Tasa de pérdida por Canal de Venta
SELECT 
    sales_channel,
    SUM(volumen_items) AS total_pedidos,
    ROUND(AVG(tasa_cancelacion_pct), 2) AS avg_cancelacion,
    ROUND(AVG(tasa_retorno_pct), 2) AS avg_retorno
FROM gold_unicorn.vw_logistics_performance
GROUP BY sales_channel
ORDER BY avg_cancelacion DESC;


-- Tendencia Mensual de SLA y Cancelaciones
SELECT 
    mes_orden,
    AVG(pct_sla_cumplimiento) AS cumplimiento_promedio,
    AVG(tasa_cancelacion_pct) AS cancelacion_promedio
FROM gold_unicorn.vw_logistics_performance
GROUP BY mes_orden
ORDER BY mes_orden DESC;