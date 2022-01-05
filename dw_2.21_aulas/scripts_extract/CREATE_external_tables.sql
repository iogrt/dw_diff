CREATE TABLE t_ext_stores(
	name		VARCHAR2(100),
	refer		CHAR(6),
	building	VARCHAR2(100),
	address		VARCHAR2(250),
	zip_code	CHAR(8),
	city		VARCHAR2(100),
	district	VARCHAR2(100),
	phone_nrs	VARCHAR2(50),
	fax_nr		VARCHAR2(50),
	closure_date	DATE
)
ORGANIZATION EXTERNAL
(
	TYPE oracle_loader
	DEFAULT DIRECTORY src_files
	ACCESS PARAMETERS
	(
		RECORDS DELIMITED BY newline
		BADFILE 'stores.bad'
		DISCARDFILE 'stores.dis'
		LOGFILE 'stores.log'
		SKIP 6
		FIELDS TERMINATED BY ";" OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
		(
			refer		CHAR(6),
			phone_nrs	CHAR(50),
			fax_nr		CHAR(50),
			name		CHAR(100),
			address		CHAR(250),
			zip_code	CHAR(8),
			city		CHAR(100),
			nr_of_employees	CHAR,
			building	CHAR(250),
			hours		CHAR,
			district	CHAR(100),
			opening_date	DATE 'dd-mm-yyyy',
			closure_date	DATE 'dd-mm-yyyy'
		)
	)
	LOCATION ('stores.csv')
)
REJECT LIMIT UNLIMITED;



CREATE TABLE t_ext_managers(
	store_refer	CHAR(6),
	name		VARCHAR2(100),
	hiring_date	DATE
)
ORGANIZATION EXTERNAL
(
	TYPE oracle_loader	
	DEFAULT DIRECTORY src_files
	ACCESS PARAMETERS
	(
		RECORDS DELIMITED BY newline
		BADFILE 'managers.bad'
		DISCARDFILE 'managers.dis'
		LOGFILE 'managers.log'
		SKIP 7
		FIELDS TERMINATED BY ";" OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
		(
			store_refer	CHAR(6),
			phone_nrs	CHAR(50),
			name		CHAR(50),
			tax_payer_nr	CHAR(100),
			hiring_date	DATE 'yyyy-mm-dd',
			is_first	CHAR(8)
		)
	)
	LOCATION ('managers.csv')
)
REJECT LIMIT UNLIMITED;

