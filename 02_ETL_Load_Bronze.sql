-- Configuración previa
USE bronze_unicorn;
SET GLOBAL local_infile = 1;

-- Carga del archivo (ETL)
LOAD DATA LOCAL INFILE '/Users/briancallejas/Downloads/unicorncsv.csv'
INTO TABLE ventas_raw
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES

(order_id, item_id, order_date, order_status, sales_channel, customer_id, 
 customer_type, customer_country, customer_city, product_id, product_name, 
 product_category, product_brand, unit_price, product_cost, quantity, 
 gross_amount, discount_rate, net_amount, shipping_method, shipping_cost, 
 shipping_status, delivery_days, payment_method, installments_count, _rescued_data);
 
 -- Mapeamos ya que al hacer trazabilidad agregamos 2 columnas adicionales
 -- Nuestra tabla pasa a 26 col, pero nuestro csv tiene 24
 
