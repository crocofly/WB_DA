-- Задание Sorting and grouping

--Часть 1

-- Вспомогательный код

--drop table if exists users;
--create table users (
--    id bigint,
--    gender text,
--    age integer,
--    education text,
--    city text
--);

--drop table if exists products;
--create table products (
--    id bigint,
--    name text,
--    category text,
--    price numeric
--);



-- Часть 1, задание 1
-- версия 1
select city, age,
count(*) as count_p 		-- Количество покупателей определенного возраста в каждом городе 
							-- (на тестовых данных выдает 100 строк с количеством покупателей 1)
							-- (всего 100 строк в массиве, двое из покупателей живут в одном городе,
							-- но попадают в разную возрастную категорию)
from users
group by city, age
--Сортировка по названию города и убыванию количества покупателей в возрастной категории (конкретный возраст)
order by city, count_p desc;


-- Часть 1, задание 1
-- версия 2, по возрастным группам

select city, age_category,
count(*) as count_p							-- Количество покупателей определенной возрастной группы в каждом городе 
from (
select city, case
	when age < 21 then 'young' 				-- возрастная группай до 21
	when age > 20 and age < 50 then 'adult' -- возрастная группа людей от 21 до 49
	else 'old'  							-- возрастная группа людей после 50
end as age_category
from users) t1
group by city, age_category
order by city, count_p desc, age_category;	-- группировка по возрастной группе, в городе, 
											-- где живут 2 покупателя adult, отображается count_p = 2


-- Часть 1, задание 2
select to_char(
				round(avg(price), 2) 		-- берем среднее, округляем до 2х знаков после запятой
				, '9999D00') as avg_price, 	-- записываем текстом в нужном формате (чтобы строго отражалось 2 разряда в дробной части)
				category
from products
where lower(name) like '%hair%' 			-- поиск совпадений hair в названии, без учета регистра
	or lower(name) like '%home%'			-- поиск совпадений home в названии, без учета регистра
group by category;




-- Часть 2

-- Вспомогательный код

--drop table if exists sellers;
--create table sellers (
--    seller_id bigint,
--    category text,
--    date_reg date,
--    date date,
--    revenue numeric,
--    rating integer,
--    delivery_days integer
--);


-- Часть 2, задание 1

select seller_id, 
	total_categ, 
	avg_rating, 
	total_revenue, 
	case when total_revenue < 50000 then 'poor' -- определение poor и rich
		else 'rich'
	end as seller_type
from ( 											-- вложенный запрос
	select seller_id,
	count(distinct category) as total_categ,	-- категории товара, которыми торгует селлер
	avg(rating) as avg_rating, 					-- средний рейтинг
	sum(revenue) as total_revenue				-- сумма выручки по селлеру
	from sellers
	where category != 'Bedding' 				-- Исключаем категорию из примечания
	group by 1
) as s
where total_categ > 1							-- Фильтрация по количеству категория товара
order by seller_id;


-- Часть 2, задание 2

with all_sellers as ( 							-- определяем CTE
	select seller_id,
	count(distinct category) as total_categ,
	sum(revenue) as total_revenue,
	extract(day 								-- считаем количество прошедших дней от самой ранней даты регистрации до текущей даты
		from current_date - min(date_reg)::timestamp) as date_reg,
	min(delivery_days) as min_del,				-- Самая быстрая доставка селлера
	max(delivery_days) as max_del				-- Самая долгая доставка селлера
	from sellers
	where category != 'Bedding'					-- Исключаем категорию из примечания
	group by 1									-- Группируем по селлеру
)
select seller_id, 
    floor(date_reg::numeric / 30::numeric) 		-- считаем количество полных месяцев
    as month_from_registration, 
	max(max_del) over() - min(min_del) 			-- ищем самую быструю и самую долгую доставку по всем 
		over() as max_delivery_difference		-- селлерам категории poor
from all_sellers
where 1=1
    and total_categ > 1							-- фильтр на количество категорий
	and total_revenue < 50000					-- фильтр на категорию poor
order by seller_id
;
	

-- Часть 2, задание 3

with sellers_cat as (							-- определяем CTE
	select seller_id , 
		category as cat, 
		count(category) 						-- Считаем количество категорий селлера
			over(partition by 
			seller_id) as cn_cat, 
		sum(revenue) 							-- Считаем сумму выручки селлера
			over(partition by 
			seller_id) as sum_sel
	from sellers s
	where date_reg >= '2022-01-01'::date		-- Селлер зарегистрирован не ранее 2022 года
	group by seller_id, cat, revenue 
	order by seller_id, cat						-- Сортировка категорий по селлерам в алфавитном порядке
)
select seller_id, 
	string_agg (cat, ' - ') as category_pair	-- Объединение категорий в строку
from sellers_cat
where 1=1
	and cn_cat = 2								-- Количество категорий = 2
	and sum_sel > 75000							-- Сумма выручки более 75 000
group by seller_id
;