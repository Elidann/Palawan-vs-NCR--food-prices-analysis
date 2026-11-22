USE ph_food_prices;

-- Question1: Latest month: how much more or less does Palawan pay vs NCR
WITH latest AS (SELECT MAX(price_date) AS d FROM prices)
SELECT p.commodity, p.unit,
       MAX(CASE WHEN p.location = 'NCR'     THEN p.price END) AS ncr_price,
       MAX(CASE WHEN p.location = 'Palawan' THEN p.price END) AS palawan_price,
       ROUND(MAX(CASE WHEN p.location = 'Palawan' THEN p.price END)
           - MAX(CASE WHEN p.location = 'NCR' THEN p.price END), 2) AS gap,
       ROUND((MAX(CASE WHEN p.location = 'Palawan' THEN p.price END)
           - MAX(CASE WHEN p.location = 'NCR' THEN p.price END))
           / MAX(CASE WHEN p.location = 'NCR' THEN p.price END) * 100, 1) AS gap_pct
FROM prices p
JOIN latest l ON p.price_date = l.d
GROUP BY p.commodity, p.unit
ORDER BY gap_pct DESC;

-- Question2: of all 46 months is Palawan consistently pricier?
WITH paired AS (
    SELECT commodity, price_date,
           MAX(CASE WHEN location = 'NCR'     THEN price END) AS ncr,
           MAX(CASE WHEN location = 'Palawan' THEN price END) AS pal
    FROM prices
    GROUP BY commodity, price_date
)
SELECT commodity,
       ROUND(AVG(pal - ncr), 2)             AS avg_gap,
       ROUND(AVG((pal - ncr) / ncr * 100), 1) AS avg_gap_pct,
       SUM(pal > ncr)                        AS months_palawan_higher,
       COUNT(*)                              AS total_months
FROM paired
GROUP BY commodity
ORDER BY avg_gap_pct DESC;

-- Question3: Yearly average price and year-over-year % change (2026 = Jan-Oct only)
WITH yearly AS (
    SELECT commodity, location, year, ROUND(AVG(price), 2) AS avg_price
    FROM prices
    GROUP BY commodity, location, year
)
SELECT commodity, location, year, avg_price,
       ROUND((avg_price - LAG(avg_price) OVER w)
             / LAG(avg_price) OVER w * 100, 1) AS yoy_pct
FROM yearly
WINDOW w AS (PARTITION BY commodity, location ORDER BY year)
ORDER BY commodity, location, year;

-- Question4: Which items rose fastest? (Jan 2023 vs latest month)
WITH latest AS (SELECT MAX(price_date) AS d FROM prices),
change_tbl AS (
    SELECT p.commodity, p.location,
           MAX(CASE WHEN p.price_date = '2023-01-01' THEN p.price END) AS jan_2023,
           MAX(CASE WHEN p.price_date = l.d          THEN p.price END) AS latest_price
    FROM prices p CROSS JOIN latest l
    GROUP BY p.commodity, p.location
)
SELECT commodity, location, jan_2023, latest_price,
       ROUND((latest_price - jan_2023) / jan_2023 * 100, 1) AS pct_change
FROM change_tbl
ORDER BY pct_change DESC;

-- Question5: Peak month: when was each item most expensive?
WITH ranked AS (
    SELECT commodity, location, price_date, price,
           ROW_NUMBER() OVER (PARTITION BY commodity, location
                              ORDER BY price DESC) AS rn
    FROM prices
)
SELECT commodity, location, price_date AS peak_month, price AS peak_price
FROM ranked
WHERE rn = 1
ORDER BY commodity, location;