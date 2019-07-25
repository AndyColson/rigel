-- dbext:profile=sqlite:dbname=stars.sqlite

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
select catalog.name as catalog, lookup.id, star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid



----------------
select catalog, count(*)
from v_star
group by catalog
order by 2

select catid, id, count(*)
from lookup
group by catid, id
having count(*) > 1;

select starid
from lookup
where catid = 1 and id = 'J00023184-7951217'

select ra, dec, count(*)
from star
group by ra, dec
having count(*) > 1

select *
from v_star
where ra like '1.13377455%' and dec like '-64.179830%'

select starid, catalog, id, count(*)
from v_star
group by starid, catalog, id
having count(*) > 1;

select starid, catid, id, count(*)
from lookup
group by starid, catid, id
having count(*) > 1;


select * from v_star
where starid in (341890, 344646, 2608076)

select count(*) from lookup
select count(*) from star
select count(distinct name) from catalog;

select max(starid) from star
select * from v_star limit 10

select * from v_star
where ra between 59.980 and 59.982
where starid = 1478741

select * from catalog where name = 'TYC';

select * from lookup where catid = 14 order by id

select sqrt(square(ra - 266.400214824826) + square(dec - -4.3972132075578)) as dist,
v_star.*
from v_star
where ra between 266.400214824826 - 0.6 and 266.400214824826 + 0.6
and dec between -4.3972132075578 - 0.6 and -4.3972132075578 + 0.6
order by 1

and catalog = 'HIP'

PRAGMA compile_options;
select (2-1)
select square(2)

select min(ra), max(ra) from star
select min(dec), max(dec) from star
select * from star where ra = 'No Coord.'
select * from star where ra - ra <> 0
select * from star where dec - dec <> 0

select count(*) from star where dec between 70.1 and 70.2


explain query plan
select * from v_star where catalog = '7.39'

select * from v_star where ra like '::err%'

explain query plan
select star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid
where catalog.name = '7.39'

explain query plan
select * from catalog where catalog.name = '7.39'

explain query plan
select star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid
where catalog.name = 'HD' and lookup.id = '899'

select lookup.id, star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid
where catalog.name = 'NAME' and upper(lookup.id) = 'NUNKI'

select * from lookup where upper(lookup.id) = 'NUNKI'
select * from lookup where upper(lookup.id) = 'POLARIS'
select * from catalog where catid = 41

explain query plan
select star.*
from star
inner join lookup on lookup.starid = star.starid
where lookup.id = '899' and lookup.catid = (select catid from catalog where name = 'HD' )

select * from star where starid = 591239

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

explain query plan
select catid from catalog where name = '2MASS'

explain query plan
select starid from lookup where id = '12' and  catid = 1



drop table grid;
delete from grid;
CREATE VIRTUAL TABLE grid USING rtree(gridid, ramin, ramax, decmin, decmax);
insert into grid values (1, 0, 5, 0, 5)
insert into grid values (2, 5, 10, 5, 10)
explain query plan
select * from grid
where 5.2 between ramin and ramax
and 5 between decmin and decmax

explain query plan
select * from grid where ramin >= 3 and ramax <= 3


drop table demo_index
CREATE VIRTUAL TABLE demo_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY, maxY       -- Minimum and maximum Y coordinate
);
INSERT INTO demo_index VALUES(
    1,                   -- Primary key -- SQLite.org headquarters
    -80.7749, -80.7747,  -- Longitude range
    35.3776, 35.3778     -- Latitude range
);
INSERT INTO demo_index VALUES(
    2,                   -- NC 12th Congressional District in 2010
    -81.0, -79.6,
    35.0, 36.2
);

explain query plan
SELECT id FROM demo_index
 WHERE minX>=-81.08 AND maxX<=-80.58
   AND minY>=35.00  AND maxY<=35.44;

