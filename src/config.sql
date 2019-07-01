create table config(
	app text not null,
	key text not null,
	value text,
	descr text,
	primary key(app, key)
);

-- insert into config(app, key, value) values ('csimc', 'TTY', '/dev/ttyS0');
-- insert into config(app, key, value) values ('csimc', 'TTY', '/dev/ttyUSB0');
insert into config(app, key, value) values ('csimc', 'HOST', '127.0.0.1');
insert into config(app, key, value) values ('csimc', 'PORT', '7623');
insert into config(app, key, value) values ('csimc', 'INIT0', 'basic.cmc find.cmc nodeHA.cmc lights.cmc');
insert into config(app, key, value) values ('csimc', 'INIT1', 'basic.cmc find.cmc nodeDec.cmc');

insert into config(app, key, value) values ('home', 'DSTEP', '3608560');
insert into config(app, key, value) values ('home', 'HSTEP', '4798121');

-- from home.cfg
-- HSTEP        4798121

-- from telescoped.cfg
-- HESTEP		12976128		! raw encoder counts/rev
-- DESTEP		12976128		! raw encoder counts/rev
-- CGUIDEVEL    0.0016          ! coarse jogging velocity, rads/sec

-- HAXIS		0
-- DAXIS		1

-- "H" refers to the longitudinal axis, ie, ha or az.
-- "D" refers to the latitudinal axis, ie, dec or alt.

-- deg * (pi/180) = rad
-- rad * (180/pi) = deg

