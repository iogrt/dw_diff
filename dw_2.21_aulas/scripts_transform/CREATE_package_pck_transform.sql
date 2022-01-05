CREATE OR REPLACE PACKAGE PCK_TRANSFORM AS

   PROCEDURE main (p_duplicate_last_iteration BOOLEAN);
   PROCEDURE screen_product_dimensions (p_iteration_key t_tel_iteration.iteration_key%TYPE,
										p_source_key t_tel_source.source_key%TYPE,
										p_screen_order t_tel_schedule.screen_order%TYPE);

   PROCEDURE screen_product_brands (p_iteration_key t_tel_iteration.iteration_key%TYPE,
										p_source_key t_tel_source.source_key%TYPE,
										p_screen_order t_tel_schedule.screen_order%TYPE);

   PROCEDURE screen_product_weight (p_iteration_key t_tel_iteration.iteration_key%TYPE,
                                     p_source_key t_tel_source.source_key%TYPE,
                                     p_screen_order t_tel_schedule.screen_order%TYPE);
END PCK_TRANSFORM;



/


CREATE OR REPLACE PACKAGE BODY pck_transform IS

   e_transformation EXCEPTION;

   -- *********************************************
   -- * PUTS AN ERROR IN THE FACT TABLE OF ERRORS *
   -- *********************************************
   PROCEDURE error_log(p_screen_name t_tel_screen.screen_name%TYPE,
                       p_hora_deteccao DATE,
                       p_source_key      t_tel_source.source_key%TYPE,
                       p_iteration_key   t_tel_iteration.iteration_key%TYPE,
                       p_record_id       t_tel_error.record_id%TYPE) IS
      v_date_key t_tel_date.date_key%TYPE;
      v_time_key t_tel_time.time_key%TYPE;
      v_screen_key t_tel_screen.screen_key%TYPE;
   BEGIN
      BEGIN
         -- obtém o id da dimensão T_TEL_DATE referente ao dia em que o erro foi detectado
         SELECT date_key
         INTO v_date_key
         FROM t_tel_date
         WHERE date_full=TO_CHAR(p_hora_deteccao,'DD/MM/YYYY');
         
         -- obtém o id da dimensão T_TEL_TIME referente ao segundo em que o erro foi detectado
         SELECT time_key
         INTO v_time_key
         FROM t_tel_time
         WHERE time_full_time = TO_CHAR(p_hora_deteccao,'HH24:MI:SS');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            pck_log.write_log('    -- ERROR --   could not find key from time dimensions ['||sqlerrm||']');
            RAISE e_transformation;
      END;

      BEGIN
         SELECT screen_key
         INTO v_screen_key
         FROM t_tel_screen
         WHERE UPPER(screen_name)=UPPER(p_screen_name);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            pck_log.write_log('    -- ERROR --   could not find screen key from "t_tel_screen" ['||sqlerrm||']');
            RAISE e_transformation;
      END;

      INSERT INTO t_tel_error (date_key,time_key,screen_key,source_key,iteration_key, record_id) VALUES (v_date_key,v_time_key,v_screen_key,p_source_key,p_iteration_key, p_record_id);
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_log('    -- ERROR --   could not write quality problem to "t_tel_error" fact table ['||sqlerrm||']');
         RAISE e_transformation;
   END;


   -- *******************************************
   -- * DUPLICATES THE LAST SCHEDULED ITERATION *
   -- *******************************************
   PROCEDURE duplicate_last_iteration(p_start_date t_tel_iteration.iteration_start_date%TYPE) IS
      v_last_iteration_key t_tel_iteration.iteration_key%TYPE;
      v_new_iteration_key t_tel_iteration.iteration_key%TYPE;

      -- Descobre, usando a tabela T_TEL_SCHEDULE, quais os screens escalonados para a iteração cujo código passou por parâmetro
      CURSOR c_scheduled_screens(p_iteration_key t_tel_iteration.iteration_key%TYPE) IS
         SELECT s.screen_key as screen_key, screen_name, screen_order, s.source_key
         FROM t_tel_schedule s, t_tel_screen
         WHERE iteration_key=p_iteration_key AND
               s.screen_key = t_tel_screen.screen_key
         ORDER BY screen_order ASC;
   BEGIN
      pck_log.write_log('  Creating new iteration by duplicating the previous one');

      -- FIND THE LAST ITERATIONS'S KEY
      BEGIN
         SELECT MAX(iteration_key)
         INTO v_last_iteration_key
         FROM t_tel_iteration;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            pck_log.write_log('    -- ERROR --   could not find iteration key ['||sqlerrm||']');
            RAISE e_transformation;
      END;

      INSERT INTO t_tel_iteration(iteration_start_date) VALUES (p_start_date) RETURNING iteration_key INTO v_new_iteration_key;
      FOR rec IN c_scheduled_screens(v_last_iteration_key) LOOP
         -- schedule screen
         INSERT INTO t_tel_schedule(screen_key,iteration_key,source_key,screen_order)
         VALUES (rec.screen_key,v_new_iteration_key,rec.source_key,rec.screen_order);
      END LOOP;
      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    -- ERROR --   previous iteration has no screens to reschedule');
         RAISE e_transformation;
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- *************************************************************************************
   -- * GOAL: Detect incorrect data in the size of products                               *
   -- * QUALITY CRITERIUM: "Correção"                                                     *
   -- * PARAMETERS:                                                                       *
   -- *     p_iteration_key: key of the iteration in which the screen will be run         *
   -- *     p_source_key: key of the source system related to the screen's execution      *
   -- *     p_screen_order: order number in which the screen is to be executed            *
   -- *************************************************************************************
   PROCEDURE screen_product_dimensions (p_iteration_key t_tel_iteration.iteration_key%TYPE,
										p_source_key t_tel_source.source_key%TYPE,
										p_screen_order t_tel_schedule.screen_order%TYPE) IS
      -- SEARCH FOR EXTRACTED PRODUCTS CONTAINING PROBLEMS
      CURSOR products_with_problems IS
         SELECT rowid
         FROM t_data_products
         WHERE rejected_by_screen='0'
               AND (((width IS NULL OR height IS NULL OR depth IS NULL) AND UPPER(pack_type) IN (SELECT pack_type
                                                                          FROM t_lookup_pack_dimensions
                                                                          WHERE has_dimensions='1'))
               OR ((width>=0 OR height>=0 OR depth>=0 AND UPPER(pack_type) IN (SELECT pack_type
                                                                               FROM t_lookup_pack_dimensions
                                                                               WHERE has_dimensions='0'))));
      i PLS_INTEGER:=0;
      v_screen_name VARCHAR2(30):='screen_product_dimensions';
   BEGIN
      pck_log.write_log('  Starting SCREEN ["'||UPPER(v_screen_name)||'"] with order #'||p_screen_order||'');
      FOR rec IN products_with_problems LOOP
         -- RECORDS THE ERROR IN THE TRANSFORMATION ERROR LOGGER BUT DOES * NOT REJECT THE LINE *
         error_log(v_screen_name,SYSDATE,p_source_key,p_iteration_key,rec.rowid);
         i:=i+1;
      END LOOP;
      pck_log.write_log('    Data quality problems in '|| i || ' row(s).','    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    No data quality problems found.','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- *************************************************************************************
   -- * GOAL: detect incorrect data in products                                           *
   -- * QUALITY CRITERIUM: "Correção"                                                     *
   -- * PARAMETERS:                                                                       *
   -- *     p_iteration_key: key of the iteration in which the screen will be run         *
   -- *     p_source_key: key of the source system related to the screen's execution      *
   -- *     p_screen_order: order number in which the screen is to be executed            *
   -- *************************************************************************************
   PROCEDURE screen_product_brands (p_iteration_key t_tel_iteration.iteration_key%TYPE,
										p_source_key t_tel_source.source_key%TYPE,
										p_screen_order t_tel_schedule.screen_order%TYPE) IS
      CURSOR products_with_problems IS
         SELECT p.rowid
         FROM t_data_products p JOIN t_lookup_brands b ON p.brand=b.brand_wrong
         WHERE rejected_by_screen='0';

      i PLS_INTEGER:=0;
      v_screen_name VARCHAR2(30):='screen_product_brands';
   BEGIN     
      pck_log.write_log('  Starting SCREEN ["'||UPPER(v_screen_name)||'"] with order #'||p_screen_order||'');
      FOR rec IN products_with_problems LOOP
         -- RECORDS THE ERROR IN THE TRANSFORMATION ERROR LOGGER BUT DOES * NOT REJECT THE LINE *
         error_log(v_screen_name,SYSDATE,p_source_key,p_iteration_key,rec.rowid);
         i:=i+1;
      END LOOP;
      pck_log.write_log('    Data quality problems in '|| i || ' row(s).','    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    No data quality problems found.','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;




   -- *************************************************************************************
   -- * GOAL: detect and reject packed products with an empty liquid weight               *
   -- * QUALITY CRITERIUM: "Completude"                                                   *
   -- * PARAMETERS:                                                                       *
   -- *     p_iteration_key: key of the iteration in which the screen will be run         *
   -- *     p_source_key: key of the source system related to the screen's execution      *
   -- *     p_screen_order: order number in which the screen is to be executed            *
   -- *************************************************************************************
   PROCEDURE screen_product_weight (p_iteration_key t_tel_iteration.iteration_key%TYPE,
                                     p_source_key t_tel_source.source_key%TYPE,
                                     p_screen_order t_tel_schedule.screen_order%TYPE) IS
      -- SEARCH FOR EXTRACTED PRODUCTS CONTAINING PROBLEMS
      CURSOR products_with_problems IS
         SELECT rowid
         FROM t_data_products
         WHERE rejected_by_screen='0' AND
               ((liq_weight IS NULL AND pack_type IS NOT NULL) OR (liq_weight IS NOT NULL AND pack_type IS NULL));

      i PLS_INTEGER:=0;
      v_screen_name VARCHAR2(30):='screen_product_weight';
   BEGIN
      pck_log.write_log('  Starting SCREEN ["'||UPPER(v_screen_name)||'"] with order #'||p_screen_order||'');
      FOR rec IN products_with_problems LOOP
         -- RECORDS THE ERROR IN THE TRANSFORMATION ERROR LOGGER AND * REJECTS THE LINE *
         error_log(v_screen_name,SYSDATE,p_source_key,p_iteration_key,rec.rowid);

		 -- SETS THE SOURCE RECORD AS 'REJECTED'
         UPDATE t_data_products
         SET rejected_by_screen='1'
         WHERE rowid=rec.rowid;

		 i:=i+1;
      END LOOP;
      pck_log.write_log('    Data quality problems in '|| i || ' row(s).','    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    No data quality problems found.','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;



   -- ####################### TRANSFORMATION ROUTINES #######################

   -- *************************************************************
   -- * TRANSFORMATION OF CUSTOMERS ACCORDING TO LOGICAL DATA MAP *
   -- *************************************************************
   PROCEDURE transform_customers IS
   BEGIN
      pck_log.write_log('  Transforming data ["TRANSFORM_CUSTOMERS"]');

      INSERT INTO t_clean_customers(id,card_number,name,address,location,district,zip_code,phone_nr,gender,age,marital_status)
      SELECT id,card_number,name,address,UPPER(location),UPPER(district),zip_code,phone_nr,
             CASE UPPER(gender) WHEN 'M' THEN 'MALE' WHEN 'F' THEN 'FEMALE' ELSE 'OTHER' END,
             age,
             CASE UPPER(marital_status) WHEN 'C' THEN 'MARRIED' WHEN 'S' THEN 'SINGLE' WHEN 'V' THEN 'WIDOW' WHEN 'D' THEN 'DIVORCED' ELSE 'OTHER' END
      FROM t_data_customers
      WHERE rejected_by_screen='0';

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    Found no lines to transform','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- ****************************************************************
   -- * TRANSFORMATION OF PRODUCTS ACCORDING TO THE LOGICAL DATA MAP *
   -- ****************************************************************
	PROCEDURE transform_products IS
	BEGIN
		pck_log.write_log('  Transforming data ["TRANSFORM_PRODUCTS"]');

		INSERT INTO t_clean_products(id,name,brand,pack_size,pack_type,diet_type,liq_weight,category_name)
		SELECT prod.id,prod.name,brand,height||'x'||width||'x'||depth,pack_type,cal.type,liq_weight,categ.name
		FROM t_data_products prod, t_lookup_calories cal, t_data_categories categ
		WHERE 	categ.rejected_by_screen='0'
				AND prod.rejected_by_screen='0'
				AND calories_100g>=cal.min_calories_100g
				AND calories_100g<=cal.max_calories_100g
				AND	categ.id=prod.category_id;

		UPDATE t_clean_products p
		SET brand = (SELECT brand_transformed FROM t_lookup_brands b WHERE p.brand=b.brand_wrong)
		WHERE brand IN (SELECT brand_wrong FROM t_lookup_brands);

		pck_log.write_log('    Done!');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			pck_log.write_log('    Found no lines to transform','    Done!');
		WHEN OTHERS THEN
           pck_log.write_uncomplete_task_msg;
		   RAISE e_transformation;
	END;


   -- ******************************************************************
   -- * TRANSFORMATION OF PROMOTIONS ACCORDING TO THE LOGICAL DATA MAP *
   -- ******************************************************************
   PROCEDURE transform_promotions IS
   BEGIN
      pck_log.write_log('  Transforming data ["TRANSFORM_PROMOTIONS"]');

      INSERT INTO t_clean_promotions(id,name,start_date,end_date,reduction,on_street,on_tv)
      SELECT id,name,start_date,end_date,reduction,CASE on_outdoor WHEN 1 THEN 'YES' ELSE 'NO' END,CASE on_outdoor WHEN 1 THEN 'YES' ELSE 'NO' END
      FROM t_data_promotions
      WHERE rejected_by_screen='0';

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    Found no lines to transform','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;



   -- *********************************************************
   -- * TRANSFORMATION OF FACTS ACCORDING TO LOGICAL DATA MAP *
   -- *********************************************************
   PROCEDURE transform_linesofsale IS
   BEGIN
      pck_log.write_log('  Transforming data ["TRANSFORM_LINESOFSALE"]');

      INSERT INTO t_clean_linesofsale(id,sale_id,product_id,promo_id,quantity,ammount_paid,line_date)
      SELECT los.id,los.sale_id,los.product_id,losp.promo_id,quantity,ammount_paid, los.line_date
      FROM t_data_linesofsale los LEFT JOIN (SELECT line_id,promo_id
                                             FROM t_data_linesofsalepromotions
                                             WHERE rejected_by_screen='0') losp ON los.id=losp.line_id, t_data_sales
      WHERE los.rejected_by_screen='0' AND
            t_data_sales.id=los.sale_id;

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    Found no lines to transform','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- *********************************************************
   -- * TRANSFORMATION OF SALES ACCORDING TO LOGICAL DATA MAP *
   -- *********************************************************
   PROCEDURE transform_sales IS
   BEGIN
      pck_log.write_log('  Transforming data ["TRANSFORM_SALES"]');

      INSERT INTO t_clean_sales(id,sale_date,store_id, customer_id)
      SELECT id,sale_date,store_id, customer_id
      FROM t_data_sales
      WHERE rejected_by_screen='0';

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    Found no lines to transform','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- **************************************************************
   -- * TRANSFORMATION OF STORES ACCORDING TO THE LOGICAL DATA MAP *
   -- **************************************************************
   PROCEDURE transform_stores IS
   BEGIN
      pck_log.write_log('  Transforming data ["TRANSFORM_STORES"]');

	  INSERT INTO t_clean_stores(name,reference,address,zip_code,location,district,telephones,fax,status,manager_name,manager_since)
      SELECT name,s.reference,CASE building WHEN '-' THEN NULL ELSE building||' - ' END || address||' / '||zip_code||', '||location,zip_code,location,district,SUBSTR(REPLACE(REPLACE(telephones,'.',''),' ',''),1,9),fax,CASE WHEN closure_date IS NULL THEN 'ACTIVE' ELSE 'INACTIVE' END, manager_name,manager_since
      FROM (SELECT name,reference,building,address,zip_code,location,district,telephones,fax,closure_date
            FROM t_data_stores_new
            WHERE rejected_by_screen='0'
            MINUS
            SELECT name,reference,building,address,zip_code,location,district,telephones,fax,closure_date
            FROM t_data_stores_old) s, t_data_managers_new d
      WHERE s.reference=d.reference AND
            d.rejected_by_screen='0';

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    Found no lines to transform','    Done!');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_transformation;
   END;


   -- ****************************************************************
   -- * TRANSFORMATION OF CELSIUS ACCORDING TO THE LOGICAL DATA MAP *
   -- ****************************************************************
	PROCEDURE transform_celsius IS
	BEGIN
		pck_log.write_log('  Transforming data ["TRANSFORM_CELSIUS"]');

		INSERT INTO t_clean_celsius(forecast_date, temperature_status)
      SELECT forecast_date,   CASE 
                                 WHEN forecast_value<4 THEN 'COLD'
                                 WHEN forecast_value<10 THEN 'FRESH'
                                 WHEN forecast_value<25 THEN 'NICE'
                                 ELSE 'HOT'
                              END AS forecast_status
      FROM 
         (SELECT TO_CHAR(SYSDATE,'dd/mm/yyyy') AS forecast_date,AVG((t_max+t_min)/2) AS forecast_value
          FROM t_data_celsius);


		pck_log.write_log('    Done!');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			pck_log.write_log('    Found no lines to transform','    Done!');
		WHEN OTHERS THEN
           pck_log.write_uncomplete_task_msg;
		   RAISE e_transformation;
	END;



   -- *****************************************************************************************************
   -- *                                             MAIN                                                  *
   -- *                                                                                                   *
   -- * EXECUTES THE TRANSFORMATION PROCESS                                                               *
   -- * IN                                                                                                *
   -- *     p_duplicate_last_iteration: TRUE=duplicates last iteration and its schedule (FOR TESTS ONLY!) *
   -- *****************************************************************************************************
   PROCEDURE main (p_duplicate_last_iteration BOOLEAN) IS
      -- checks all scheduled screens
      cursor scheduled_screens_cursor(p_iteration_key t_tel_iteration.iteration_key%TYPE) IS
         SELECT UPPER(screen_name) screen_name,source_key,screen_order
         FROM t_tel_schedule, t_tel_screen
         WHERE iteration_key=p_iteration_key AND
              t_tel_schedule.screen_key=t_tel_screen.screen_key;

		v_iteration_key t_tel_iteration.iteration_key%TYPE;
		v_sql VARCHAR2(200);
   BEGIN
      pck_log.clean;
      pck_log.write_log(' ','*****  TRANSFORM  TRANSFORM  TRANSFORM  TRANSFORM  TRANSFORM  TRANSFORM  *****');      -- DUPLICATES THE LAST ITERATION AND THE CORRESPONDING SCREEN SCHEDULE
      IF p_duplicate_last_iteration THEN
         duplicate_last_iteration(SYSDATE);
      END IF;

      -- CLEANS ALL _clean TABLES
      pck_log.write_log('  Deleting old _clean tables');
	  DELETE FROM t_clean_customers;
	  DELETE FROM t_clean_products;
	  DELETE FROM t_clean_promotions;
	  DELETE FROM t_clean_linesofsale;
	  DELETE FROM t_clean_sales;
	  DELETE FROM t_clean_stores;
      DELETE FROM t_clean_celsius;
            
      pck_log.write_log('    Done!');

      -- FINDS THE MOST RECENTLY SCHEDULED ITERATION
      BEGIN
         SELECT MAX(iteration_key)
         INTO v_iteration_key
         FROM t_tel_iteration;
      EXCEPTION
         WHEN OTHERS THEN
            RAISE e_transformation;
      END;

      -- RUNS ALL THE SCHEDULED SCREENS
	  -- versão estática 
    /*  FOR rec IN scheduled_screens_cursor(v_iteration_key) LOOP
         IF UPPER(rec.screen_name)='SCREEN_PRODUCT_DIMENSIONS' THEN
            screen_dimensions(v_iteration_key, rec.source_key, rec.screen_order);
         ELSIF UPPER(rec.screen_name)='SCREEN_NULL_LIQ_WEIGHT' THEN
            screen_null_liq_weight(v_iteration_key, rec.source_key, rec.screen_order);
         END IF;*/

         -- EXECUÇÃO DINÂMICA DE SCREENS
        FOR rec IN scheduled_screens_cursor(v_iteration_key) LOOP
            v_sql:='BEGIN pck_transform.'||rec.screen_name||'('||v_iteration_key||','||rec.source_key||','||rec.screen_order||'); END;';
            pck_log.write_log(v_sql);
            EXECUTE IMMEDIATE v_sql;
        END LOOP;

		-- UPDATES TABLE "T_TEL_ITERATION"
		UPDATE t_tel_iteration
		SET iteration_end_date = SYSDATE,
		    iteration_duration_real=(SYSDATE-iteration_start_date)/86400
		WHERE iteration_key = v_iteration_key;

		pck_log.write_log('  All screens have been run.');

		-- EXECUTES THE TRANSFORMATION ROUTINES
		transform_customers;
		transform_products;
		transform_promotions;
		transform_linesofsale;
		transform_sales;
		transform_stores;
		transform_celsius;

		COMMIT;
		pck_log.write_log('  All transformed data commited to database.');
	EXCEPTION
		WHEN e_transformation THEN
			pck_log.write_halt_msg;
			ROLLBACK;
		WHEN OTHERS THEN
			ROLLBACK;
			pck_log.write_uncomplete_task_msg;
			pck_log.write_halt_msg;
	END;

end pck_transform;
/
