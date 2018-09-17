create table config(app text not null, key text not null, value text, descr text, primary key(app, key));

insert into config(app, key, value) values ('csimc', 'TTY', '/dev/ttyS0');
insert into config(app, key, value) values ('csimc', 'HOST', '127.0.0.1');
insert into config(app, key, value) values ('csimc', 'PORT', '7623');
insert into config(app, key, value) values ('csimc', 'INIT0', 'basic.cmc find.cmc nodeHA.cmc lights.cmc');
insert into config(app, key, value) values ('csimc', 'INIT1', 'basic.cmc find.cmc nodeDec.cmc');

insert into config(app, key, value) values ('home', 'DSTEP', '3608560');
insert into config(app, key, value) values ('home', 'HSTEP', '4798121');


-- HESTEP		12976128		! raw encoder counts/rev
-- DESTEP		12976128		! raw encoder counts/rev

-- "H" refers to the longitudinal axis, ie, ha or az.
-- "D" refers to the latitudinal axis, ie, dec or alt.


-- LADDR		0		! csimc addr for light control, else -1
-- MAXFLINT        3               ! max flat light intensity. 0 for none.
-- csi_w (lfd, "lights(%d);", i);
