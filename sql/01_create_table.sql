CREATE DATABASE IF NOT EXISTS ph_food_prices;
USE ph_food_prices;

CREATE TABLE IF NOT EXISTS prices (
    price_date DATE          NOT NULL,
    year       SMALLINT      NOT NULL,
    month      VARCHAR(10)   NOT NULL,
    location   VARCHAR(30)   NOT NULL,
    commodity  VARCHAR(30)   NOT NULL,
    unit       VARCHAR(15)   NOT NULL,
    price      DECIMAL(10,2) NOT NULL
);