CREATE TABLE t_data_products(
	id		NUMBER(10),
	name		VARCHAR2(30),
	brand		VARCHAR2(30),
	width		NUMBER(5),
	height		NUMBER(5),
	depth   	NUMBER(5),
	pack_type	VARCHAR2(30),
	calories_100g	NUMBER(3),
	liq_weight	NUMBER(8,2),
	category_id	CHAR(5),
	rejected_by_screen CHAR	DEFAULT(0)	-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);

CREATE TABLE t_data_stores_new(
	name		VARCHAR2(100),
	reference	CHAR(6),
	building	VARCHAR2(250),
	address		VARCHAR2(250),
	zip_code	CHAR(8),
	location	VARCHAR2(100),
	district	VARCHAR2(100),
	telephones	VARCHAR2(50),
	fax		VARCHAR2(50),
	closure_date	DATE,
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);

CREATE TABLE t_data_stores_old AS SELECT * FROM t_data_stores_new;


CREATE TABLE t_data_managers_new(
	reference	CHAR(6),
	manager_name	VARCHAR2(100),
	manager_since	DATE,
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);

CREATE TABLE t_data_managers_old AS SELECT * FROM t_data_managers_new;

CREATE TABLE t_data_promotions(
	id		NUMBER(10),
	name		VARCHAR2(100),
	start_date	DATE,
	end_date	DATE,
	reduction	NUMBER(3,2),
	on_outdoor	NUMBER(1),
	on_tv		NUMBER(1),
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);


CREATE TABLE t_data_sales(
	id		NUMBER(10),
	sale_date		DATE,
	store_id   	CHAR(6),
	customer_id	INTEGER,
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);


CREATE TABLE t_data_linesofsale(
	id		NUMBER(14),
	sale_id		NUMBER(10),
	product_id	NUMBER(10),
	quantity	NUMBER(8,2),
	line_date	DATE,
	ammount_paid	NUMBER(11,2),
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);


CREATE TABLE t_data_linesofsalepromotions(
	line_id		NUMBER(10),
	promo_id	NUMBER(10),
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);


CREATE TABLE t_data_categories(
	id		CHAR(5),
	name		VARCHAR2(30),
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);

-- v2.21.0
CREATE TABLE t_data_celsius(
	forecast_date VARCHAR2(10),
	id_local	NUMBER,
	t_min		NUMBER,
	t_max		NUMBER,
	rejected_by_screen CHAR	DEFAULT(0)		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
);


CREATE TABLE t_data_customers(
   id    			INTEGER,
   card_number		VARCHAR2(20),
   name				VARCHAR2(40),
   address			VARCHAR2(60),
   location			VARCHAR2(60),
   district			VARCHAR2(40),
   zip_code			VARCHAR2(8),
   phone_nr			NUMBER(9),
   gender			CHAR(1),
   age				NUMBER(3),	
   marital_status	CHAR(1),
   rejected_by_screen CHAR	DEFAULT(0),		-- {0=not rejected,1=rejected,will not be used on LOAD stage}
   CONSTRAINT pk_customers PRIMARY KEY (id)
);