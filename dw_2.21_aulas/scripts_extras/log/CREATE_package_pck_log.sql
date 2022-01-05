create or replace PACKAGE PCK_LOG AS

  PROCEDURE clean;
  PROCEDURE rowcount(p_target_table IN VARCHAR2, p_tag VARCHAR2 DEFAULT NULL);
  PROCEDURE write_log(p_log_text1 VARCHAR2 DEFAULT NULL, p_log_text2 VARCHAR2 DEFAULT NULL);
  PROCEDURE write_rollback_msg;
  PROCEDURE write_halt_msg;
  PROCEDURE write_uncomplete_task_msg;

END PCK_LOG;
/

create or replace PACKAGE BODY PCK_LOG AS

  g_current_log_table_name VARCHAR2(30):='t_log_etl';
  g_current_log_id PLS_INTEGER:=1;
  

   -- ******************************************
   -- * CLEANS THE CURRENT LOG TABLE           *
   -- ******************************************
   PROCEDURE clean AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      DELETE FROM t_log_etl;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR (-20901,'Error: could not clean log table ['||sqlerrm||'].');
   END;


   -- ******************************************
   -- * LOGS THE TOTAL ROWS FOUND IN A TABLE   *
   -- ******************************************
   PROCEDURE rowcount(p_target_table IN VARCHAR2, p_tag VARCHAR2 DEFAULT NULL) AS
	  v_count PLS_INTEGER;
	  e_invalid_table_name EXCEPTION;
	  PRAGMA EXCEPTION_INIT (e_invalid_table_name,-00942);
	  p_tag_2 VARCHAR2(80):='    #Rowcount';
   BEGIN
      IF (p_tag IS NOT NULL) THEN
	     p_tag_2 := p_tag_2||'('||SUBSTR(p_tag,1,50)||')';
      END IF;
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||p_target_table INTO v_count;
	  write_log(p_tag_2||': "'||UPPER(p_target_table)||'" --> '||v_count||' rows');
   EXCEPTION
      WHEN e_invalid_table_name THEN
         write_log(p_tag_2||': table "'||UPPER(p_target_table)||'" does not exist');
      WHEN OTHERS THEN
	     write_log(p_tag_2||': unexected error.');
   END;


   -- *******************************************************
   -- * RECORDS A MESSAGE IN THE CURRENT LOG TABLE          *
   -- *******************************************************
	PROCEDURE write_log(p_log_text1 VARCHAR2 DEFAULT NULL, p_log_text2 VARCHAR2 DEFAULT NULL) AS
		PRAGMA AUTONOMOUS_TRANSACTION;
		v_sql VARCHAR2(300);
	BEGIN
		v_sql:='INSERT INTO '||g_current_log_table_name||' (id,log_text,execution_start) VALUES (:1,:2,:3)';
		IF (p_log_text1 IS NOT NULL) THEN
			EXECUTE IMMEDIATE v_sql USING g_current_log_id, p_log_text1, systimestamp;
			g_current_log_id:=g_current_log_id+1;
		END IF;
		IF (p_log_text2 IS NOT NULL) THEN
			EXECUTE IMMEDIATE v_sql USING g_current_log_id, p_log_text2, systimestamp;
			g_current_log_id:=g_current_log_id+1;
		END IF;
		COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
			RAISE_APPLICATION_ERROR (-20900,'Error writting to log table ['||sqlerrm||']');
	END;
   

   PROCEDURE write_rollback_msg IS
   BEGIN
      write_log('    -- ERROR --   All new/updated data rolled back.');
   END;
   
   
   PROCEDURE write_halt_msg IS
   BEGIN
      write_log('    -- ERROR --   the current ETL stage was halted.');
      write_rollback_msg;
   END;

   
   PROCEDURE write_uncomplete_task_msg IS
   BEGIN
      write_log('    -- ERROR --   unable to complete the task ['||sqlerrm||']');
   END;
END;

/