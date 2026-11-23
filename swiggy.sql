use Swiggy
select	* from swiggy_data
--data validation &cleaning
--Null Check
select 
	SUM(CASE when State is null then 1 else 0 end)as null_state,
	SUM(CASE when City is null then 1 else 0 end)as null_city,
	SUM(CASE when Order_Date is null then 1 else 0 end)as null_order_date,
	SUM(CASE when Restaurant_Name is null then 1 else 0 end)as null_restaurant_name,
	SUM(CASE when Location is null then 1 else 0 end)as null_location,
	SUM(CASE when Category is null then 1 else 0 end)as null_category,
	SUM(CASE when Dish_name is null then 1 else 0 end)as null_Dish_name,
	SUM(CASE when Price_INR is null then 1 else 0 end)as null_price_inr,
	SUM(CASE when Rating is null then 1 else 0 end)as null_rating,
	SUM(CASE when Rating_Count is null then 1 else 0 end)as null_rating_count
from swiggy_data;

--blank or empty strings
select * 
from swiggy_data
where 
State = '' or City='' or Restaurant_Name='' or Location='' or Category='' or Dish_name=''

--Duplicate detection
select
State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_name,Price_INR,Rating,Rating_Count,count(*) as CNT
from swiggy_data
group by
State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_name,Price_INR,Rating,Rating_Count
having count(*) >1

--deleting duplication
with cte as(
select* ,row_number() over(
	partition by State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_name,Price_INR,Rating,Rating_Count
order by (select null)
) as rn
from swiggy_data
)
delete from cte where rn>1
select *from swiggy_data

--Create schema
--dimenstion tables

--data table

create table dim_date(
	Date_id int identity(1,1) primary key,
	Full_date date,
	Year int,
	Month int,
	Month_name varchar(20),
	quarter int,day int,
	week int)

--dim location
create table dim_location(
	location_id int identity (1,1) primary key,
	State varchar(100),
	City varchar(100),
	Location varchar(200))

--dim restaurant
create table dim_restaurant(
	restaurant_id int identity (1,1) primary key,
	Restaurant_Name varchar(200))

--dim category
create table dim_category(
	category_id int identity (1,1) primary key,
	Category varchar(200))

--dim dish 
create table dim_dish(
	dish_id int identity (1,1) primary key,
	Dish_name varchar(200))

--Fact table
create table fact_swiggy_orders(
	order_id int identity (1,1) primary key,

	Date_id int,
	Price_INR decimal(10,2),
	Rating decimal(4,2),
	Rating_count int,

	location_id int,
	restaurant_id int,
	category_id int,
	dish_id int,

	foreign key (Date_id) references dim_date(Date_id),
	foreign key (location_id) references dim_location(location_id),
	foreign key (restaurant_id) references dim_restaurant(restaurant_id),
	foreign key (category_id) references dim_category(category_id),
	foreign key (dish_id) references dim_dish(dish_id)
	)

select*from fact_swiggy_orders


--insert data in tabels

--dim date
insert into dim_date(Full_date,Year,Month,Month_name,quarter,day,week)
select distinct Order_Date,Year(Order_Date),Month(Order_Date),datename(month,Order_Date),
datepart(quarter,Order_Date),day(Order_Date),datepart(week,Order_Date)
from swiggy_data
where order_date is not null

select *from dim_date

--dim location
insert into dim_location(State,City,Location)
select distinct State,City,Location from swiggy_data

select *from dim_location

--dim restaurant
insert into dim_restaurant(Restaurant_Name)
select distinct Restaurant_Name from swiggy_data

select *from dim_restaurant


--dim category
insert into dim_category(Category)
select distinct Category from swiggy_data

select *from dim_category

--dim dish
insert into dim_dish(Dish_name)
select distinct Dish_name from swiggy_data

select *from dim_dish

--fact table
insert into fact_swiggy_orders
(
	Date_id,
	Price_INR,
	Rating,
	Rating_count,
	location_id,
	restaurant_id,
	category_id,
	dish_id
)
select
	dd.Date_id,
	s.Price_INR,
	s.Rating,
	s.Rating_count,

	d1.location_id,
	dr.restaurant_id,
	dc.category_id,
	dsh.dish_id
from swiggy_data s

join dim_date dd
	on dd.Full_Date=s.Order_Date

join dim_location d1
	on d1.State=s.State
	and d1.City=s.City
	and d1.Location=s.Location

join dim_restaurant dr
	on dr.Restaurant_Name=s.Restaurant_Name

join dim_category dc
	on dc.Category=s.Category

join dim_dish dsh
	on dsh.Dish_name=s.Dish_name

select *from fact_swiggy_orders

select *from  fact_swiggy_orders f 
join dim_date d on f.Date_id=d.Date_id
join dim_location l on f.location_id=l.location_id
join dim_restaurant r on f.restaurant_id=r.restaurant_id
join dim_category c on f.category_id=c.category_id
join dim_dish di on f.dish_id=di.dish_id

---KPI's
--Total Orders
select count(*) as Total_Orders 
from fact_swiggy_orders

--total revenue(INR million)
select 
format(sum(convert(float,Price_INR))/1000000,'N2')+' INR Million' 
as Total_Revenue
from fact_swiggy_orders

--average dish price
select 
format(avg(convert(float,Price_INR)),'N2')+' INR' 
as Average_price
from fact_swiggy_orders


--Average Rating
select
avg(Rating) as avg_rating
from fact_swiggy_orders

--Deep-Dive Business Analysis

-- Monthly Order Trends
select 
d.year,
d.month,
d.month_name,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,
d.month,
d.month_name
order by count(*) desc


select 
d.year,
d.month,
d.month_name,
sum(Price_INR) as Total_Revenue
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,
d.month,
d.month_name
order by sum(Price_INR) desc

--Quarterly Trend
select 
d.year,
d.quarter,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,
d.quarter
order by count(*) desc

--Yearly Trend
select 
d.year,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year
order by count(*) desc

--Orders by Day of Week(Mon-sun)
select
	datename(weekday,d.Full_date)as day_name,
	count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by datename(weekday,d.Full_date),datepart(weekday,d.Full_date)
order by datepart(weekday,d.Full_date) 

--Top 10 cities by order volume
select top 10
l.city,
count(*) as Total_orders from fact_swiggy_orders f
join dim_location l
	on l.location_id=f.location_id
group by l.city 
order by count(*) desc


select top 10
l.city,
sum(Price_INR) as Total_Revenue from fact_swiggy_orders f
join dim_location l
	on l.location_id=f.location_id
group by l.city 
order by sum(Price_INR)desc



--Revenue Contribution by states
select top 10
l.state,
sum(Price_INR) as Total_Revenue from fact_swiggy_orders f
join dim_location l
	on l.location_id=f.location_id
group by l.state 
order by sum(Price_INR)desc

select
l.state,
sum(Price_INR) as Total_Revenue from fact_swiggy_orders f
join dim_location l
	on l.location_id=f.location_id
group by l.state 
order by sum(Price_INR)desc




--Top 10 restaurant by orders
select top 10
r.Restaurant_Name,
sum(Price_INR) as Total_Revenue from fact_swiggy_orders f
join dim_restaurant r
	on r.restaurant_id=f.restaurant_id
group by r.Restaurant_Name
order by sum(Price_INR)desc


select*from fact_swiggy_orders

--top category by order volume
select
	c.Category,
	count(*) as total_orders
from fact_swiggy_orders f
join dim_category c on f.category_id=c.category_id
group by c.category
order by total_orders desc


--most ordered dishes
select top 10
	d.Dish_name,
	count(*) as order_count
from fact_swiggy_orders f
join dim_dish d on f.dish_id=d.dish_id
group by d.Dish_name
order by order_count desc

--cuisine performance (orders+avg Rating)
select
	c.Category,
	count(*) as total_orders,
	avg(f.rating)as avg_rating
from fact_swiggy_orders f
join dim_category c on f.category_id=c.category_id
group by c.category
order by total_orders desc

--total orders by price range
select
	case
		when convert(float,Price_INR)<100 then 'under 100'
		when convert(float,Price_INR) between 100 and 199 then '100-199'
		when convert(float,Price_INR) between 200 and 299 then '200-299'
		when convert(float,Price_INR) between 300 and 399 then '300-499'
		else '500+'
	end as price_range,
	count(*) as total_orders
from fact_swiggy_orders
group by
	case
		when convert(float,Price_INR)<100 then 'under 100'
		when convert(float,Price_INR) between 100 and 199 then '100-199'
		when convert(float,Price_INR) between 200 and 299 then '200-299'
		when convert(float,Price_INR) between 300 and 399 then '300-499'
		else '500+' 
	end
order by total_orders desc

--rating count distribution(1-5)
select
	Rating,
	count(*) as rating_count
from fact_swiggy_orders
group by Rating
order by count(*) desc
