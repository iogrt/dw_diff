CREATE OR REPLACE VIEW v_last_iteration_info AS
SELECT
   To_CHAR(e.iteration_key) AS "Iteration",
   s.screen_name AS "Screen",
   s.screen_description AS "Problem",
   e.record_id AS row_with_data_problems
FROM t_tel_error e NATURAL JOIN t_tel_date d
     NATURAL JOIN t_tel_screen s
     NATURAL JOIN t_tel_source so
WHERE iteration_key = (SELECT MAX(iteration_key)
                       FROM t_tel_schedule)
ORDER BY "Screen";


-- Shows where are the data quality problems
CREATE OR REPLACE VIEW v_data_with_problems AS
SELECT 
   'Produtos' AS "Tipo", 'ID: '||p.id||'; Nome: '||p.name AS "Info",
   v."Problem"
FROM t_data_products p, v_last_iteration_info v
WHERE p.rowid = v.row_with_data_problems;