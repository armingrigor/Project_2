
set search_path to flights;

select count(*) from flights;


drop table if exists flights;
create table flights (
YEAR integer,
MONTH integer,
DAY integer,
DAY_OF_WEEK integer,
AIRLINE varchar(2),
FLIGHT_NUMBER integer,
TAIL_NUMBER varchar(20),
ORIGIN_AIRPORT varchar(30),
DESTINATION_AIRPORT varchar(30),
SCHEDULED_DEPARTURE varchar(4),
DEPARTURE_TIME integer,
DEPARTURE_DELAY integer,
TAXI_OUT integer,
WHEELS_OFF varchar(4), 
SCHEDULED_TIME integer,
ELAPSED_TIME integer,
AIR_TIME integer,
DISTANCE integer,
WHEELS_ON varchar(4),
TAXI_IN integer,
SCHEDULED_ARRIVAL varchar(4),
ARRIVAL_TIME varchar(4),
ARRIVAL_DELAY integer,
DIVERTED integer,
CANCELLED integer,
CANCELLATION_REASON varchar(1),
AIR_SYSTEM_DELAY integer,
SECURITY_DELAY integer,
AIRLINE_DELAY integer,
LATE_AIRCRAFT_DELAY integer,
WEATHER_DELAY integer);
--COPY 5819079

drop table if exists airlines;
create table airlines (
	airline_id serial primary key,
IATA_CODE varchar(2),
	AIRLINE varchar(50)
);
--COPY 14

drop table if exists airports;
create table airports(
airport_id serial primary key,
IATA_CODE varchar(3),
	AIRPORT varchar(100),
	CITY varchar(100),
	STATE varchar(2),
	COUNTRY	varchar(10),
	LATITUDE numeric,
	LONGITUDE numeric
);
--COPY 322


drop table if exists cancellation_reason;
create table cancellation_reason(
reason_id	serial primary key,
reason_class	varchar(1),
reason_name	varchar(50)
);

insert into cancellation_reason (reason_class, reason_name) 
values ('A', 'Airline/Carrier'), ('B', 'Weather'), ('C', 'National Air System'), ('D', 'Security');


drop table if exists weekday;
create table weekday(
weekday_id serial primary key,
weekday_name varchar(20)
);

insert into weekday values ('Monday'), ('Tuesday'), ('Wednsday'), ('Thursday'), ('Friday'), ('Saturday'), ('Sunday');


drop sequence if exists flights_id_seq;
create sequence flights_id_seq;

drop table if exists flights_norm;
create table flights_norm as
select
nextval('flights_id_seq') as flight_id,
YEAR,
MONTH,
DAY,
DAY_OF_WEEK,
flights.airlines.airline_id,
FLIGHT_NUMBER,
TAIL_NUMBER,
origin.airport_id as origin_airport,
destination.airport_id as destination_airport,
SCHEDULED_DEPARTURE,
DEPARTURE_TIME,
DEPARTURE_DELAY,
TAXI_OUT,
WHEELS_OFF,
SCHEDULED_TIME,
ELAPSED_TIME,
AIR_TIME,
DISTANCE,
WHEELS_ON,
TAXI_IN,
SCHEDULED_ARRIVAL,
ARRIVAL_TIME,
ARRIVAL_DELAY,
DIVERTED,
CANCELLED,
CANCELLATION_REASON.reason_id,
AIR_SYSTEM_DELAY,
SECURITY_DELAY,
AIRLINE_DELAY,
LATE_AIRCRAFT_DELAY,
WEATHER_DELAY
from flights
inner join airlines on flights.airline = airlines.iata_code
left join airports origin on flights.origin_airport = origin.iata_code
left join airports destination on flights.destination_airport = destination.iata_code
left join cancellation_reason on cancellation_reason.reason_class = flights.cancellation_reason;


alter table flights_norm add constraint fk_origin_airport foreign key(origin_airport) references airports(airport_id);
alter table flights_norm add constraint fk_departure_airport foreign key(destination_airport) references airports(airport_id);
alter table flights_norm add constraint fk_cancellation_reason foreign key(reason_id) references cancellation_reason(reason_id);
alter table flights_norm add constraint fk_airline foreign key(airline_id) references airlines(airline_id);
alter table flights_norm add constraint fk_weekday foreign key(day_of_week) references weekday(weekday_id);


select count(cancellation_reason), day_of_week from flights_norm
group by day_of_week;

select sum(cancelled), day_of_week from flights_norm
group by day_of_week;



select scheduled_departure, scheduled_time, scheduled_arrival,
case 
		when extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 < 0 
		then extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 + 1440
else extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 end as sch_time
from flights_norm where scheduled_time is null;


update flights_norm set scheduled_time = 
case 
		when extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 < 0 
		then extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 + 1440
else extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 end
where scheduled_time is null;

--updated 6 rows

select sum(cancelled) from flights_norm where cancelled = 1;

select distinct cancelled from flights_norm;

select count(*) from flights_norm where DEPARTURE_TIME is null and cancelled = 0;--0
select count(*) from flights_norm where TAIL_NUMBER is null and cancelled = 0;--0
select count(*) from flights_norm where DEPARTURE_DELAY is null and cancelled = 0;--0
select count(*) from flights_norm where TAXI_OUT is null and cancelled = 0;--0
select count(*) from flights_norm where WHEELS_OFF is null and cancelled = 0;--0
select count(*) from flights_norm where SCHEDULED_TIME is null and cancelled = 0;--to be updated/updated
select count(*) from flights_norm where ELAPSED_TIME is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where AIR_TIME is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where WHEELS_ON is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where TAXI_IN is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where ARRIVAL_TIME is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where ARRIVAL_DELAY is null and cancelled = 0;--to be updated/deleted
select count(*) from flights_norm where reason_id is not null and cancelled = 0;--0
select count(*) from flights_norm where reason_id is null and cancelled = 1;--0

select count(*) from flights_norm where AIR_SYSTEM_DELAY+SECURITY_DELAY+AIRLINE_DELAY+LATE_AIRCRAFT_DELAY+WEATHER_DELAY != arrival_delay;--0


select * from flights_norm where arrival_delay is null and cancelled = 0 limit 50;


select scheduled_departure, scheduled_time, scheduled_arrival, arrival_delay, arrival_time,
case when extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 < 0 then extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 + 1440
else extract(epoch from (to_char(scheduled_arrival::time, 'HH:MI AM')::time - to_char(scheduled_departure::time, 'HH:MI AM')::time))/60 end as sch_time
from flights_norm limit 1000;


select * from flights_norm where scheduled_arrival = arrival_time;


delete from flights_norm where arrival_delay is null and cancelled = 0;
--deleted 15187 rows


select count(*) from flights_norm where ELAPSED_TIME is null and cancelled = 0;--0
select count(*) from flights_norm where AIR_TIME is null and cancelled = 0;--0
select count(*) from flights_norm where WHEELS_ON is null and cancelled = 0;--0
select count(*) from flights_norm where TAXI_IN is null and cancelled = 0;--0
select count(*) from flights_norm where ARRIVAL_TIME is null and cancelled = 0;--0
select count(*) from flights_norm where ARRIVAL_DELAY is null and cancelled = 0;--0

select count(*) from flights_norm;

