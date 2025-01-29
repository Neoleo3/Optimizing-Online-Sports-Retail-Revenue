-- Task 1 : Count the total number of products, along with the number of non-missing values in description, listing_price and last_visited
select * from finance;
select * from info;
select * from traffic;
select count(product_id) from finance;
select count(description) from info;
select count(i.product_id) as total_rows,count(i.description) as total_descp,  count(f.listing_price) as total_listsPricings, 
count(t.last_visited) from info i
left join finance f on f.product_id=i.product_id
left join traffic t on t.product_id=i.product_id;
-- The query above retreives the count of the above said column data with null rows not counted.

-- Task 2 : Find out how listing price varies between nike and adidas
select * from brands;
select * from finance;
select b.brand,f.listing_price,count(f.listing_price) as distribution from finance f
join brands b on b.product_id=f.product_id
where f.listing_price>0
group by f.listing_price,b.brand
order by f.listing_price asc;
-- How do the price points of Nike and Adidas products differ? 
-- Answering this question can help us build a picture of the company’s stock range and customer market.

-- Task 3 : Create labels for products grouped by price range and brands
select * from brands;
select * from finance;
select b.brand, count(f.product_id) as count_of_products, sum(f.revenue) as total_revenue,
case when listing_price < 42 then 'Budget'
when listing_price >= 42 and listing_price <=72 then 'Avergae'
when listing_price > 72 and listing_price<=126 then 'Expensive'
else 'Elite' end as price_category
from finance f
join brands b on b.product_id=f.product_id
group by b.brand, price_category;


-- Task 4 : calcualte average discount offerred by brands
select b.brand, avg(discount) as avg_discounts from finance f 
join brands b on b.product_id=f.product_id
group by b.brand;

-- Task 5 : Calcualate the correlation between reviews and revenue
select * from reviews;
select * from finance;
select (SUM(r.reviews * f.revenue) - (SUM(r.reviews) * SUM(f.revenue)) / COUNT(*)) / 
    (SQRT(SUM(r.reviews * r.reviews) - (SUM(r.reviews) * SUM(r.reviews)) / COUNT(*)) * 
     SQRT(SUM(f.revenue * f.revenue) - (SUM(f.revenue) * SUM(f.revenue)) / COUNT(*)))  as Correlation_number from reviews r 
join finance f on f.product_id=r.product_id;
-- Mildy strong correlation between reviews and revenues 

-- Task 6 :  Ratings and reviews by product description length
SELECT 
    FLOOR(LENGTH(i.description) / 100) * 100 AS description_length,
    ROUND(AVG(CAST(r.rating AS DECIMAL(10,2))), 2) AS average_rating
FROM info AS i
INNER JOIN reviews AS r 
    ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;
-- The results indicate a relationship between the length of product descriptions (description_length) 
-- and the average product rating (average_rating).


-- Task 7 : Count the number of reviews per brand per month
select * from brands;
select * from reviews;
select * from traffic;
select * from info;
select * from finance;
select b.brand, sum(r.reviews) as Num_reviews, month(t.last_visited) as months
from brands b
left join traffic t on t.product_id=b.product_id
left join reviews r on r.product_id=b.product_id
group by months, b.brand
having b.brand is not null and months is not null
order by months, num_reviews desc;

-- Task 8 : Create the footwear CTE, then calculate the number of products and average revenue from these items.
select * from finance;
select * from info;
WITH footwear AS (
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f ON i.product_id = f.product_id
    WHERE (i.description LIKE '%shoe%'
        OR i.description LIKE '%trainer%'
        OR i.description LIKE '%foot%')  -- Corrected OR/AND logic
        AND i.description IS NOT NULL
),
SortedFootwear AS (
    SELECT revenue, @rownum := @rownum + 1 AS row_num
    FROM footwear, (SELECT @rownum := 0) AS r  -- Initialize row number
    ORDER BY revenue
),
MedianValues AS (
  SELECT
    CASE
      WHEN (SELECT COUNT(*) FROM footwear) % 2 = 0 THEN (
        (SELECT revenue FROM SortedFootwear WHERE row_num = CEIL((SELECT COUNT(*) FROM footwear) / 2)) +
        (SELECT revenue FROM SortedFootwear WHERE row_num = FLOOR((SELECT COUNT(*) FROM footwear) / 2) + 1)
      ) / 2
      ELSE (SELECT revenue FROM SortedFootwear WHERE row_num = CEIL((SELECT COUNT(*) FROM footwear) / 2))
    END AS median_revenue
)
SELECT COUNT(*) AS num_footwear_products, median_revenue
FROM footwear
CROSS JOIN MedianValues;

-- Task 9 : Copy the code used to create footwear then use a filter to return only products that are not in the CTE.
WITH footwear AS (
    SELECT i.description
    FROM info AS i
    INNER JOIN finance AS f ON i.product_id = f.product_id
    WHERE (i.description LIKE '%shoe%' OR i.description LIKE '%trainer%' OR i.description LIKE '%foot%')
      AND i.description IS NOT NULL
),
ClothingRevenue AS (
    SELECT f.revenue
    FROM info AS i
    INNER JOIN finance AS f ON i.product_id = f.product_id
    WHERE i.description NOT IN (SELECT description FROM footwear)
),
SortedClothingRevenue AS (
    SELECT revenue, @rownum := @rownum + 1 AS row_num
    FROM ClothingRevenue, (SELECT @rownum := 0) AS r
    ORDER BY revenue
),
MedianClothingValues AS (
  SELECT
    CASE
      WHEN (SELECT COUNT(*) FROM ClothingRevenue) % 2 = 0 THEN (
        (SELECT revenue FROM SortedClothingRevenue WHERE row_num = CEIL((SELECT COUNT(*) FROM ClothingRevenue) / 2)) +
        (SELECT revenue FROM SortedClothingRevenue WHERE row_num = FLOOR((SELECT COUNT(*) FROM ClothingRevenue) / 2) + 1)
      ) / 2
      ELSE (SELECT revenue FROM SortedClothingRevenue WHERE row_num = CEIL((SELECT COUNT(*) FROM ClothingRevenue) / 2))
    END AS median_revenue
)
SELECT COUNT(i.product_id) AS num_clothing_products, median_revenue
FROM info AS i
INNER JOIN finance AS f ON i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear)
cross JOIN MedianClothingValues;

