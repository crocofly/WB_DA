-- Задание 3 Window functions

--Часть 1

-- Вспомогательный код

--drop table if exists salary;
--create table salary (
--    id bigint,
--    first_name text,
--    last_name text,
--	salary integer,
--    industry text
--);
--
--select * from salary s ;


-- Часть 1, максимальная зарплата

-- версия без оконной функции
select first_name, last_name, salary, industry;
with max_sal_name as (											-- формируем таблицу людей с самыми высокими зп в отделе
	select s.industry,
		concat(first_name, ' ', last_name) as name_ighest_sal 	-- соединяем имя и фамилию
	from salary s
	inner join (
		select industry, max(salary) as salary					-- ищем максимальные зп в отделе
		from salary s 
		group by industry										-- группируем по отделу
		order by industry
	) as t1
	on t1.industry = s.industry and t1.salary = s.salary		-- ищем имена людей с самыми высокими зп в отделе
) 
select first_name, last_name, salary, industry, name_ighest_sal
from salary
left join max_sal_name using(industry)							-- джоиним к основной таблице
order by industry, salary desc
;


-- версия с оконной функцией
select first_name, last_name, salary, industry,
	concat(															-- соединяем имя и фамилию
		first_value(first_name) over(partition by industry), ' ', 	-- выбираем имя сотрудника с самой высокой зп в отделе
		first_value(last_name) over(partition by industry)			-- выбираем фамилию сотрудника с самой высокой зп в отделе
		) as name_ighest_sal
from (
	select *	
	from salary s 
	order by industry, salary desc
);


-- Часть 1, минимальная зарплата

-- версия без оконной функции
select first_name, last_name, salary, industry;
with max_sal_name as (											-- формируем таблицу людей с самыми низкими зп в отделе
	select s.industry,
		concat(first_name, ' ', last_name) as name_ighest_sal 	-- соединяем имя и фамилию
	from salary s
	inner join (
		select industry, min(salary) as salary					-- ищем минимальные зп в отделе
		from salary s 
		group by industry										-- группируем по отделу
		order by industry
	) as t1
	on t1.industry = s.industry and t1.salary = s.salary		-- ищем имена людей с самыми низкими зп в отделе
) 
select first_name, last_name, salary, industry, name_ighest_sal
from salary
left join max_sal_name using(industry)							-- джоиним к основной таблице
order by industry, salary desc
;

-- версия с оконной функцией
select first_name, last_name, salary, industry,
	concat(															-- соединяем имя и фамилию
		last_value(first_name) over(partition by industry), ' ', 	-- выбираем имя сотрудника с самой низкой зп в отделе
		last_value(last_name) over(partition by industry)			-- выбираем фамилию сотрудника с самой низкой зп в отделе
		) as name_ighest_sal
from (
	select *	
	from salary s 
	order by industry, salary desc
);


-- Часть 2

--drop table if exists goods;
--create table goods (    
--	ID_GOOD bigint,
--    CATEGORY text,
--    GOOD_NAME text,
--	PRICE integer
--);
--
--select * from goods s ;			

--drop table if exists sales;
--create table sales (    
--	DATE date,	
--	SHOPNUMBER integer,
--	ID_GOOD bigint,
--	QTY integer
--);
--
--select * from sales s ;

--drop table if exists shops;
--create table shops (    
--	SHOPNUMBER integer,
--	CITY text,
--	ADDRESS text
--);
--
--select * from shops s ;


-- Часть 2, задание 1

select 
	distinct shopnumber,			-- Уникальные номера магазинов определяют количество строк в выходной таблице
	city,							-- По сути это замена группировки
	ADDRESS,
	sum(qty) over(partition by shopnumber) as SUM_QTY,		-- В таком случае пригождается оконная функция
	sum(qty*price) over(partition by shopnumber) as SUM_QTY_PRICE
from sales s 
left join shops using(shopnumber)
left join goods using(id_good)
where date = '2016-01-02'::date		-- Фильтр на дату по условию задачи
order by shopnumber
;


-- Часть 2, задание 2

select 
	distinct date as date_, city,	-- Уникальное сочетание дат и городов с продажами на эту дату определяет количество строк
	sum(qty * price) over(partition by date, city) as SUM_SALES_REL	-- Расчитываем стоимость всего проданного в городе на дату
from sales s 
left join goods g using(id_good)
left join shops using(shopnumber)
where lower(category) ='чистота'	-- только товары направления "Чистота"
order by date_, city
;


-- Часть 2, задание 3

with rate_goods as (		-- Формируем рейтинг товаров в магазине на определенную дату
	select date as date_, 
			shopnumber, 
			id_good,		
			-- номер позиции товара, отсортированного по убыванию количества продаж
			row_number() over(partition by date, shopnumber order by sum(qty) desc) as rn
	from sales
	left join goods g using(id_good)
	left join shops using(shopnumber)
	group by date_, shopnumber, id_good
)
select DATE_ , SHOPNUMBER, ID_GOOD
from rate_goods
where rn <=3		-- отбираем только первые 3 товара в магазине на дату из рейтинга
;


-- Часть 2, задание 4

Выведите для каждого магазина и товарного направления сумму продаж в рублях за предыдущую дату. 
Только для магазинов Санкт-Петербурга.

select date as date_,
		SHOPNUMBER,
		CATEGORY,
		lag(sum(qty * price)) 								-- выводим сумму продаж  в рублях за предыдущую дату
			over (partition by SHOPNUMBER, CATEGORY 		-- партиция по номеру магазина и категории, чтобы при отсутствии данных по продажам за предыдущую дату у данного магазина и категории выводило NULL
				order by SHOPNUMBER, CATEGORY, date) 		-- сортировка по номеру магазина, категории и дате,
			as PREV_SALES									-- чтобы значение lag соответствовало предыдущей дате нужного магазина и категории
	from sales
		left join goods g using(id_good)
		left join shops using(shopnumber)
	where lower(city) = 'спб'				-- Только для магазинов Санкт-Петербурга.
	group by date_, SHOPNUMBER, CATEGORY
;



-- Часть 3

drop table if exists query;
create table query (
	searchid integer unique,
	year integer not null check (year >= 2000 and year <= 2024), 
	month integer not null check (month >= 1 and month <= 12), 
	day integer, 
	userid integer, 
	ts time, 
	devicetype text, 
	deviceid integer, 
	query text
);

insert into query (searchid, year, month, day, userid, ts, devicetype, deviceid, query) values 
    (1, 2024, 9, 15, 1, '09:14:00', 'Android', 2, 'купить слона'),			-- 1
	(2, 2024, 9, 15, 3, '18:12:00', 'Apple', 1, 'сколько лететь до'),		-- 1
	(3, 2024, 9, 15, 3, '18:16:00', 'Apple', 1, 'сколько лететь до Марса на ракете'),	-- 1
	(4, 2024, 9, 15, 3, '18:18:00', 'Apple', 1, 'сколько лететь до Марса'),	-- 2
	(5, 2024, 9, 15, 3, '18:18:15', 'Apple', 1, 'сколько лететь до '),		-- 0
	(6, 2024, 9, 15, 3, '18:22:30', 'Apple', 1, 'сколько лететь до '),		-- 1
	(7, 2024, 9, 15, 1, '12:00:00', 'Android', 2, 'узнать СНИЛС'),			-- 2
	(8, 2024, 9, 15, 1, '12:02:00', 'Android', 2, 'узнать ИНН'),			-- 0
	(9, 2024, 9, 15, 1, '12:04:00', 'Android', 2, 'узнать ЕГРН')			-- 1
;

--select * from query;

with next_q as (		-- достаем для нынешнего запроса текс и время следующего запроса (при наличии)
	select 
	year, month, day,
	userid, 
	ts, 
	lead(ts) over(		-- с помощью функции lead
			partition by year, month, day, userid, devicetype, deviceid
			order by ts	-- сортировка по времени, чтобы получился следующий запрос по пользователю и устройству
		) as ts_next
	, devicetype, deviceid,
	query,
	lead(query) over(
			partition by year, month, day, userid, devicetype, deviceid
			order by ts
		) as next_query
	from query
), is_final_def as (	-- определяем параметр is_final
	select *,
		case 
			when next_query is null or (ts_next - ts) > interval '180' then 1
			when length(next_query) < length(query) and (ts_next - ts) > interval '60' then 2
			else 0
		end as is_final
	from next_q
)
select year, month, day,
	userid, ts, devicetype,
	deviceid, query,
	next_query, is_final
from is_final_def
where year = 2024 and month = 9 and day = 15 	-- выбираем определенный день
	and devicetype='Android'					-- устройства только андроид как в условии
	and is_final > 0							-- is_final 1 или 2
;
