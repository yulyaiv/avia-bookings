
set search_path to bookings;

--1. Выведите название самолетов, которые имеют менее 50 посадочных мест?

select model, count(s.seat_no) as "seat count"
from aircrafts a
join seats s on s.aircraft_code = a.aircraft_code 
group by 1
having count(seat_no) < 50


--2. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.

select a.model, array_agg(s.fare_conditions)
from aircrafts a
join seats s on s.aircraft_code = a.aircraft_code
group by a.model
having not array['Business'::varchar] <@ array_agg(s.fare_conditions)



--3. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
 --Выведите в результат названия аэропортов и процентное отношение.
 --Решение должно быть через оконную функцию.


select a.airport_name as "departure_airport_name", a2.airport_name as "arrival_airport_name", 
   count(f.flight_no) as "flight_count",
   count(f.flight_no) * 100. / sum(count(f.flight_no)) over () as "percentage"
from flights f
join airports a on a.airport_code = f.departure_airport
join airports a2 on a2.airport_code = f.arrival_airport
group by a.airport_name, a2.airport_name



--4. Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7

select substring(contact_data->>'phone' from 3 for 3) as "operator_code", count(passenger_id) as "passenger_count"
from tickets
group by operator_code

   
--5. Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
 --До 50 млн - low
 --От 50 млн включительно до 150 млн - middle
 --От 150 млн включительно - high
 --Выведите в результат количество маршрутов в каждом полученном классе


select classification, count(*)
from (
	select sum(tf.amount),
	case 
		when  sum(tf.amount) < 50000000 then 'low'
	    when  sum(tf.amount) >= 50000000 and sum(tf.amount) < 150000000 then 'middle'
	    else 'high'
	end classification
	from ticket_flights tf 
	join flights f on f.flight_id = tf.flight_id 
	group by f.departure_airport, f.arrival_airport) 
group by 1

--6. Вычислите медиану стоимости перелетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости перелетов, округленной до сотых


 with cte1 as (
     select percentile_cont(0.5) within group (order by tf.amount) as "median_flight_amount"
     from ticket_flights tf),
cte2 as (
    select percentile_cont(0.5) within group (order by b.total_amount) as "median_booking_amount"
    from bookings b)
select cte1.median_flight_amount, cte2.median_booking_amount,
    round(cte2.median_booking_amount::numeric / cte1.median_flight_amount::numeric, 2) as "ratio"
from cte1
cross join cte2 
    
--7. Найдите значение минимальной стоимости полета 1 км для пассажиров. То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат
  --Для поиска расстояния между двумя точками на поверхности Земли используется модуль earthdistance.
  --Для работы модуля earthdistance необходимо предварительно установить модуль cube.
  --Установка модулей происходит через команду: create extension название_модуля.

create extension cube

create extension earthdistance

select min(tf.amount / (earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(a2.latitude, a2.longitude)) / 1000)) as "min_cost"
from flights f
join airports a on a.airport_code = f.departure_airport
join airports a2 on a2.airport_code = f.arrival_airport
join ticket_flights tf on tf.flight_id = f.flight_id


