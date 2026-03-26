E-commerce Amazonas

▸	Diseñar una base de datos completa de un e-commerce para el análisis. Dicha base de datos está creada  en MySQL, que representa la operación de una tienda en línea, incluyendo información sobre ventas, productos, clientes y transacciones.
▸	Diseñar y construir un modelo de datos en arquitectura Bronze–Silver–Gold que soporte analítica descriptiva y diagnóstica.
▸	Analizar el desempeño de ventas a nivel de productos, clientes, categorías y canales comerciales.
▸	Evaluar el impacto de descuentos, costos de envío y medios de pago en la rentabilidad.
▸	Analizar el desempeño logístico por canales de envío y órdenes.
▸	Desarrollar un dashboard en Power BI para monitoreo de KPIs clave de negocio.

Se adopta una arquitectura tipo medallion (Bronze, Silver, Gold) para el pipeline ETL, siguiendo buenas prácticas de ingeniería de datos.

▸	Archivo CSV de ventas: unicorncsv.csv  (Origen ChatGPT)
▸	Archivo CSV de ventas definitivo: unicorncsv2.csv (Se usó unicorncsv.csv como archivo maestro para extender el dataset de 50,000 a 500,000 entradas).

Power BI 
El modelo estrella se importa desde la base de datos (capa Silver/Gold) hacia Power BI para construir la capa de visualización.
