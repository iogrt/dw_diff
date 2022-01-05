DECLARE
	CURSOR c_tabelas IS
		SELECT table_name
		FROM user_tables
		WHERE REGEXP_LIKE(table_name,'^(T_DIM_|T_FACT_)');
BEGIN
	FOR records IN c_tabelas LOOP
		EXECUTE IMMEDIATE 'DROP TABLE '||records.table_name||' CASCADE CONSTRAINTS';
	END LOOP;
END;
/
