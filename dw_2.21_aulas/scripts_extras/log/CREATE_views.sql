CREATE OR REPLACE VIEW v_log_etl AS
	SELECT log_text	AS log_entry
	FROM t_log_etl
	ORDER BY execution_start, id;
