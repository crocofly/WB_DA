-- Задание SQL:join

--Часть 1

-- Вспомогательный код

--drop table if exists customers;
--create table customers (
--    customer_id bigint,
--    name text
--);
--select * from customers c ;
--
--drop table if exists orders;
--create table orders (
--    order_id integer,
--    customer_id bigint,
--    order_date timestamp,
--    shipment_date timestamp,
--    order_ammount integer,
--    order_status text
--);
--select * from orders c ;

-- Часть 1, задание 1
with ords as (
	select *, 
		(shipment_date - order_date)::interval as ord_time -- Интервал доставки заказа
	from orders as o
	where order_status = 'Approved'		-- Выбираем заказы, которые были доставлены
)
select name
from ords
left join customers c 
on c.customer_id =ords.customer_id
where ord_time = (select max(ord_time) from ords)
group by name
order by name
;
-- Все интервалы между доставкой и заказом ровные, исчисляются днями
-- Множество заказов с одинаковым максимкальным интервалом в 10 дней
-- Присоединяем к заказам покупателей, группируем,
-- чтобы покупатель не повторялся,
-- сортируем имена в алфавитном порядке


-- Часть 1, задание 2

with custs as (
	select customer_id, 
		count(*) as count_orders,		-- считаем количество заказов 
		avg((shipment_date - order_date)::interval) as avg_shipment,	-- среднее время доставки заказов покупателя
		sum(order_ammount) as orders_sum 	-- сумма всех заказов покупателя
	from orders o 
	group by customer_id 
)
select name, count_orders,
	avg_shipment, orders_sum
from custs
left join customers using(customer_id)
where count_orders = ( 						-- вложенный запрос, условие максимального количества заказов
	select max(count_orders) from custs
	)
order by orders_sum desc					-- сортируем по убыванию стоимости заказов
;


-- Часть 1, задание 3

with cancel as (	-- cte для расчета отмененных заказов
	select customer_id , 
		count(*) as cancel_ord, 
		sum(order_ammount) as cancel_sum
	from orders o 
	where order_status = 'Cancel'
	group by customer_id 
),
slow as (			-- cte для расчета задержанных заказов
	select customer_id , count(*) as slow_ord, sum(order_ammount) as slow_sum
	from orders o 
	where order_status = 'Approved' and 
		(shipment_date - order_date)::interval > '5 days'::interval		-- Задержка более 5 дней
	group by customer_id 
)
select name, 
	coalesce(slow_ord, 0) as slow_ord,		-- 0, если у покупателя не было задержек заказов
	coalesce(cancel_ord, 0) as cancel_ord,	-- 0, если у покупателя не было отмен заказов
	coalesce(slow_sum, 0) + coalesce(cancel_sum, 0) as sum_ord
from cancel
full join slow using(customer_id)		-- присоединение задержек к отменам
left join customers using(customer_id)	-- добавляем имена заказчиков
order by 4 desc			-- отсортировано по общей сумме заказов в убывающем порядке
;


-- Часть 2

-- Вспомогательный код

--drop table if exists products;
--create table products (
--    product_id bigint,
--    product_name text,
--    product_category text
--);
--select * from products c ;

--drop table if exists orders;
--create table orders (
--    order_date timestamp,
--    order_id integer,
--    product_id integer,
--    order_ammount integer
--);
--select * from orders c ;


with all_products as ( 		-- CTE для нахождения самого дорогого продукта в категории (задание 3)
	select product_category, product_name, sum(order_ammount) as product_amount
		from products p
		left join orders o using(product_id)
		group by product_category, product_name
	order by product_category, product_amount desc
),
arr_cat as (				-- Группируем отсортированные по убыванию стоимости продукты в массив (задание 3)
	select product_category, array_agg(product_name) as prod_arr
	from all_products
	group by product_category
),
category_max as (			-- Берем первый продукт из массива (с максимальным amount) в категории (задание 3)
	select product_category, prod_arr[1] as prod
	from arr_cat
),
prod_cat as (				-- общая сумма продаж для ккаждой категории (задание 1)
	select product_category, sum(order_ammount) as category_amount
	from products p
	left join orders o using(product_id)
	group by product_category
),
prod_best as (				-- Нахождение продукта с наибольшей общей суммой продаж, подзапрос (задание 2)
select *
from prod_cat, (
	select product_category as best_category
	from prod_cat
	where 
		category_amount = (select max(category_amount) from prod_cat)
	) 
)
select * from prod_best		-- Объединяем все три задачи в один запрос
left join category_max using(product_category)
;
