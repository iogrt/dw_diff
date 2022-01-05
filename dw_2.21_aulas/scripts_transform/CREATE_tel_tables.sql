CREATE TABLE t_tel_date(
	date_key	NUMBER(6),
	date_full	CHAR(10),
	year_nr		NUMBER(4),
	month_nr	NUMBER(2),
	month_name_full	VARCHAR2(9),
	month_name_short	CHAR(3),
	day_nr		NUMBER(2),
	CONSTRAINT pk_telDate_dateKey PRIMARY KEY (date_key)
);


CREATE TABLE t_tel_time(
	time_key	NUMBER(5),
	time_full_time	CHAR(8),
	CONSTRAINT pk_telTime_timeKey PRIMARY KEY (time_key)
);


CREATE TABLE t_tel_iteration(
	iteration_key			NUMBER(10),
	iteration_start_date		DATE,
	iteration_end_date			DATE,
	iteration_duration_real		INTEGER,
	CONSTRAINT pk_telIteration_iterationKey PRIMARY KEY (iteration_key)
);


CREATE TABLE t_tel_source(
	source_key		     NUMBER(5),
	source_file_name     VARCHAR2(20),
	source_database_name VARCHAR2(20),
	source_host_ip       VARCHAR2(15),
	source_host_os       VARCHAR2(100),
	source_description	 VARCHAR2(250),
	CONSTRAINT pk_telSource_sourceKey PRIMARY KEY (source_key)
);


CREATE TABLE t_tel_screen(
	screen_key		NUMBER(5),
	screen_name		VARCHAR2(30),
	screen_class		VARCHAR2(15),		-- COMPLETUDE, CORREÇÃO, COERÊNCIA, CLAREZA
	screen_description	VARCHAR2(200),
	screen_version		VARCHAR2(10),		-- EX: 2.7
	screen_expired		VARCHAR2(3),		-- {YES,NO}
	CONSTRAINT pk_telScreen_screenKey PRIMARY KEY (screen_key)
);


CREATE TABLE t_tel_error(
	date_key	NUMBER(6),
	time_key	NUMBER(5),
	screen_key	NUMBER(5),
	iteration_key	NUMBER(10),
	source_key	NUMBER(5),
	record_id	VARCHAR2(100)	NOT NULL,
	CONSTRAINT pk_telError 		PRIMARY KEY (date_key,time_key,screen_key,iteration_key,source_key,record_id),
	CONSTRAINT fk_telError_dateKey 	FOREIGN KEY (date_key) REFERENCES t_tel_date(date_key),
	CONSTRAINT fk_telError_timeKey 	FOREIGN KEY (time_key) REFERENCES t_tel_time(time_key),
	CONSTRAINT fk_telError_screenKey 	FOREIGN KEY (screen_key) REFERENCES t_tel_screen(screen_key),
	CONSTRAINT fk_telError_iterationKey 	FOREIGN KEY (iteration_key) REFERENCES t_tel_iteration(iteration_key),
	CONSTRAINT fk_telError_sourceKey 	FOREIGN KEY (source_key) REFERENCES t_tel_source(source_key)
);


CREATE TABLE t_tel_schedule(
	screen_key	NUMBER(5),
	iteration_key	NUMBER(10),
	source_key	NUMBER(5),
	screen_order	NUMBER(3),
	CONSTRAINT pk_telSchedule 		PRIMARY KEY (screen_key,iteration_key,source_key),
	CONSTRAINT fk_telSchedule_screenKey 	FOREIGN KEY (screen_key) REFERENCES t_tel_screen(screen_key),
	CONSTRAINT fk_telSchedule_iterationKey FOREIGN KEY (iteration_key) REFERENCES t_tel_iteration(iteration_key),
	CONSTRAINT fk_telSchedule_sourceKey 	FOREIGN KEY (source_key) REFERENCES t_tel_source(source_key)
);



