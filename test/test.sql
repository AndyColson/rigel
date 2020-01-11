-- dbext:profile=sqlite:conn_parms=dbname=stars.sqlite

create table catalog(
	catid integer primary key,
	name text not null
);
create index catalog_name on catalog(name);

create table star(
	starid integer primary key,
	ra float,
	dec float,
	type text,
	plx float,
	pmra float,
	pmdec float,
	radial float,
	redshift float,
	spec text,
	bmag float,
	vmag float
);
create index star_ra on star(ra);
create index star_dec on star(dec);

create table lookup(
	starid integer,
	catid integer,
	id text
);
-- create index lookup_id on lookup(id);
create index lookup_id on lookup(catid, id);
create index lookup_star on lookup(starid);
-- drop index lookup_catid
-- create index lookup_catid on lookup(catid);

drop view v_star;

create view v_star as
select catalog.catid as catid, catalog.name as catalog, lookup.id, star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid


pragma optimize;

----------------
select catalog, count(*)
from v_star
group by catalog
order by 2 desc

select count(*) from (
select catid, id, count(*)
from lookup
where catid <> 78
group by catid, id
having count(*) > 1
)

select catalog.catid, catalog.name, tmpx.id
from catalog
inner join (
	select catid, id, count(*)
	from lookup
	group by catid, id
	having count(*) > 1
	limit 1
) as tmpx on tmpx.catid = catalog.catid


-- dup catalog names
select name, count(*)
from catalog
group by name
having count(*) > 1

select * from catalog
where name like '% %'
where catid = 4

select count(*) from catalog where catid = 45
delete  from lookup where catid = 45 and id = '50 2716'

select * from lookup where catid = 4 and id not like '+%'
update lookup set id = '+' || id where catid = 4 and id not like '+%'

select *
from v_star
where catalog = '**'
and id = 'H 151'

select distinct name from catalog order by name

select max(starid) from star

select * from v_star where starid = 5245350;
select * from catalog where name like '[GPH2009%'
update lookup set catid = 1976, id = 'D634-03-01' where starid = 5245350
delete from catalog where catid = 8670
select * from lookup where starid = 5245350

--- move cat's
select * from catalog where name like '%+%'
select * from v_star where catalog = 'CSI+05-18379'

drop table tmpx
create table tmpx(starid integer, catid integer, nn text);
create index tmpx_pk on tmpx(starid, catid);
delete from tmpx


insert into tmpx
select starid, lookup.catid, substr(name,3) || ' ' || id
from lookup
inner join catalog on lookup.catid = catalog.catid
where name like 'BD+%'

select * from tmpx
select count(*) from tmpx

select * from catalog where name = 'BD'

update catalog set name = 'ZTF' where catid = 5502

update lookup set catid = 4, id = (select nn from tmpx where tmpx.starid = lookup.starid and tmpx.catid = lookup.catid)
where exists(select nn from tmpx where tmpx.starid = lookup.starid and tmpx.catid = lookup.catid)

--------------------
-- --   null star name
drop table tmpx
create table tmpx(starid integer, catid integer, nn text, junk text);
create index tmpx_pk on tmpx(starid, catid);
delete from tmpx

insert into tmpx
select starid, lookup.catid, substr(name, 4), name
from lookup
inner join catalog on lookup.catid = catalog.catid
where id is null
and name like 'PS1%'

select * from tmpx
delete from lookup where starid in (select starid from tmpx)
delete from star where starid in (select starid from tmpx)

select * from catalog where name = 'PS1'

update catalog set name = 'ZTF' where catid = 5502

update lookup set catid = 1886, id = (select nn from tmpx where tmpx.starid = lookup.starid and tmpx.catid = lookup.catid)
where exists(select nn from tmpx where tmpx.starid = lookup.starid and tmpx.catid = lookup.catid)
-------------------



select * from catalog where name like 'CSI%'

select *, substr(name, 4)
from lookup
inner join catalog on lookup.catid = catalog.catid
where id is null
and catalog.name not like 'OGLE%'
and catalog.name not like 'ZTF%'
and catalog.name not like 'DES%'
and catalog.name not like 'SPIRITS%'



select * from v_star where starid in (
	select starid
	from lookup
	where catid = 1 and id = 'J00051718-3011599'
)

select * from catalog order by name

select round(0.6325863046, 4)

select round(ra, 1) as ra, count(*)
from star
where ra between 0 and 10
group by round(ra, 1)


explain query plan
select *
from v_star
where ra between 0.6325863046 and 0.6325863048
and dec between -79.8560423   and -79.8560420

where ra like '0.6325863047%' and dec like '-79.856042221%'

select starid, catalog, id, count(*)
from v_star
group by starid, catalog, id
having count(*) > 1;

select starid, catid, id, count(*)
from lookup
group by starid, catid, id
having count(*) > 1;


select count(*) from lookup
select count(*) from star
select count(*) from catalog;
select count(distinct name) from catalog;

select max(starid) from star
select * from v_star limit 10

select * from v_star where catalog = 'BMB'


select * from catalog where name = 'TYC';
select count(*) from lookup where catid = 14

select *
from v_star
where catalog = 'NGC'
and id = '6820'

select load_extension('/usr/bin/libsqlitefunctions')
select sqrt(square(ra - 266.400214824826) + square(dec - -4.3972132075578)) as dist,
v_star.*
from v_star
where ra between 266.400214824826 - 0.6 and 266.400214824826 + 0.6
and dec between -4.3972132075578 - 0.6 and -4.3972132075578 + 0.6
order by 1


PRAGMA compile_options;
select (2-1)
select square(2)

select min(ra), max(ra) from star
select min(dec), max(dec) from star
select * from star where ra = 'No Coord.'
select * from star where ra - ra <> 0
select * from star where dec - dec <> 0

select count(*) from star where dec between 70.1 and 70.2

select * from v_star where ra like '::err%'

explain query plan
select lookup.id, star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid
where catalog.name = 'NAME' and upper(lookup.id) = 'NUNKI'

select * from lookup where upper(lookup.id) = 'NUNKI'
select * from lookup where upper(lookup.id) = 'POLARIS'
select * from catalog where catid = 41



-- === Delete star
-- does a star have something in the lookup?
delete from star where starid in (
  select star.starid
  from star
  left join lookup on star.starid = lookup.starid
  where lookup.starid is null
)

delete from lookup where starid in (select distinct starid from star where ra = 'No Coord.' )
delete from star where ra = 'No Coord.';
delete from lookup where starid in (select distinct starid from star where ra like '::err%' )
delete from star where ra like '::err%';


delete from catalog where catid in (
  select catalog.catid
  from catalog
  left join lookup on catalog.catid = lookup.catid
  where lookup.catid is null
)
-- =============
-- Delete a catalog
select * from catalog where catid in (2579, 4853)
select * from catalog where name = 'YZ';
select count(*) from lookup where catid = 45
delete from lookup where catid = 45
delete from catalog where name = 'YZ';

--


