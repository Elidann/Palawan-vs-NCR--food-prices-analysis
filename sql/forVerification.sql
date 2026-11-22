 --   for verification -- 

USE ph_food_prices;

SELECT commodity, location, COUNT(*) AS months,
       MIN(price) AS min_price, MAX(price) AS max_price
FROM prices
GROUP BY commodity, location
ORDER BY commodity, location;