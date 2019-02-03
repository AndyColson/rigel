-- dbext:profile=sqlite:dbname=stars.sqlite

select count(*) from lookup
select count(*) from star
select distinct name from catalog order by name;

select * from v_star limit 10

select * from v_star
where ra between 59.980 and 59.982

select min(ra), max(ra) from star
select min(dec), max(dec) from star
select * from star where ra = 'No Coord.'
select * from star where ra - ra <> 0
select * from star where dec - dec <> 0

select count(*) from star where dec between 70.1 and 70.2

drop view v_star;

create view v_star as
select catalog.name as catalog, lookup.id, star.*
from star
inner join lookup on lookup.starid = star.starid
inner join catalog on catalog.catid = lookup.catid

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

explain query plan
select star.*
from star
inner join lookup on lookup.starid = star.starid
where lookup.id = '899' and lookup.catid = (select catid from catalog where name = 'HD' )

create index if not exists lookup_id on lookup(catid, id);
drop index lookup_id;

create index if not exists lookup_id on lookup(id);
create index if not exists lookup_catid on lookup(catid);
create index if not exists catalog_name on catalog(name)

drop index lookup_id;
drop index lookup_catid;
create index lookup_id on lookup(catid, id);

create index star_ra on star(ra);
create index star_dec on star(dec);

-- === Delete star
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

