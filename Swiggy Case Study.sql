CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    name VARCHAR(20),
    email VARCHAR(50),
    password VARCHAR(20)
);


CREATE TABLE restaurants (
    r_id INTEGER PRIMARY KEY,
    r_name VARCHAR(50),
    cuisine VARCHAR(20),
    rating FLOAT
);

CREATE TABLE food (
    f_id INTEGER PRIMARY KEY,
    f_name VARCHAR(20),
    type VARCHAR(20)
);

CREATE TABLE menu (
    menu_id INTEGER PRIMARY KEY,
    r_id INTEGER,
    f_id INTEGER,
    price INTEGER,
    FOREIGN KEY (r_id)
        REFERENCES restaurants (r_id),
    FOREIGN KEY (f_id)
        REFERENCES food (f_id)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    r_id INTEGER,
    amount INTEGER,
    date DATE,
    FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    FOREIGN KEY (r_id)
        REFERENCES restaurants (r_id)
);

CREATE TABLE order_details (
    id INTEGER PRIMARY KEY,
    order_id INTEGER,
    f_id INTEGER,
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    FOREIGN KEY (f_id)
        REFERENCES food (f_id)
);


select * from users;
select * from restaurants;
select * from orders;
select * from order_details;
select * from menu;
select * from food;


/* 1. Find customers who have never ordered*/

SELECT DISTINCT
    u.name
FROM
    users u
        LEFT JOIN
    orders o ON u.user_id = o.user_id
WHERE
    o.order_id is NULL; 
    
/* 2. Average Price/dish */

SELECT 
    f.f_name, round(AVG(m.price),2) AS avg_price_per_dish
FROM
    menu m,
    food f
WHERE
    m.f_id = f.f_id
GROUP BY f.f_name;


/* 3. Find the top restaurant in terms of the number of orders for a given month */

select x1.mnth, x2.r_name 
from (
	select x.mnth, x.r_id, rank() over(partition by x.mnth order by x.cnt desc) as rnk 
    from
		(select monthname(date) as mnth, r_id, count(1) as cnt 
		from orders group by monthname(date), r_id) x) x1, 
restaurants x2 
where x1.r_id = x2.r_id and x1.rnk = 1;


/* Restaurants with monthly sales > 900 */

SELECT 
    x2.r_name, x1.monthno, x1.total
FROM
    (SELECT 
        r_id, MONTH(date) AS monthno, SUM(amount) AS total
    FROM
        orders
    GROUP BY MONTH(date) , r_id
    ORDER BY r_id , monthno) x1,
    restaurants x2
WHERE
    x1.r_id = x2.r_id AND x1.total > 900;


/* 5. Show all orders with order details for a particular customer in a particular date range */

SELECT 
    u.name, r.r_name, o.amount, f.f_name, o.date
FROM
    orders o
        JOIN
    order_details od ON o.order_id = od.order_id
        JOIN
    users u ON o.user_id = u.user_id
        JOIN
    restaurants r ON o.r_id = r.r_id
        JOIN
    food f ON od.f_id = f.f_id
WHERE
    u.name = 'Nitish'
        AND o.date BETWEEN '2022-05-10' AND '2022-07-10';


/* 6. Find restaurants with max repeated customers */

with temp as 
(SELECT 
    r_id, user_id, COUNT(user_id) AS c
FROM
    orders
GROUP BY r_id , user_id
HAVING c > 1
ORDER BY r_id)
select distinct(r.r_name), sum(temp.c) over(partition by temp.r_id) as n_rep_cust 
from temp
join restaurants r
on temp.r_id = r.r_id
order by n_rep_cust desc limit 1;


/*	7. Month over month revenue growth of swiggy */
with cte as
	(select 
		distinct(monthname(date)) as 'month', 
		sum(amount) over(partition by month(date) order by month(date)) as 'revenue' 
	from orders)
select cte.month, ((lead(cte.revenue) over() - cte.revenue)*100/cte.revenue) as 'm-o-m revenue growth'
from cte;

/* 8. Customer - favorite food */
SELECT 
    f.f_name, COUNT(o.f_id) AS cnt
FROM
    order_details o
        JOIN
    food f ON o.f_id = f.f_id
GROUP BY o.f_id
ORDER BY cnt DESC
LIMIT 1;




