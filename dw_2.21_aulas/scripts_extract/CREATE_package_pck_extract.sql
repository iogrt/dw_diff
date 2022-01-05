CREATE OR REPLACE PACKAGE pck_extract IS
   PROCEDURE main (p_initialize BOOLEAN);
END pck_extract;
/
create or replace PACKAGE BODY pck_extract IS

   e_extraction EXCEPTION;

    -- *************************************************
    -- * CLEARS DATA FROM T_DATA_* AND T_INFO_* TABLES *
    -- *************************************************
    PROCEDURE reset IS
    BEGIN
        pck_log.write_log('Cleaning all T_DATA and T_INFO tables...');
        FOR rec IN (SELECT table_name 
                    FROM user_tables 
                    WHERE REGEXP_LIKE(table_name,'^(T_DATA_|T_INFO)')) LOOP 
            EXECUTE IMMEDIATE 'DELETE FROM '||rec.table_name;
            pck_log.write_log('  '||rec.table_name||': done');
        END LOOP;
        pck_log.write_log('T_DATA and T_INFO tables are now clean.');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pck_log.write_uncomplete_task_msg;
            RAISE e_extraction;
    END;

   -- **********************************************
   -- * INTITALIZES THE t_info_extractions TABLE   *
   -- **********************************************
   PROCEDURE initialize_extractions_table (p_clean_before BOOLEAN) IS
      v_source_table VARCHAR2(100);
   BEGIN
      BEGIN
	     pck_log.write_log('  Initializing data required for extraction ["INITIALIZE_EXTRACTIONS_TABLE"]');
         IF p_clean_before=TRUE THEN
            pck_log.write_log('    Deleting previous data');
            DELETE FROM t_info_extractions;
            pck_log.write_log('      Done!');

            pck_log.write_log('    Deleting %_new and %_old data');
            DELETE FROM t_data_stores_new;
            DELETE FROM t_data_stores_old;
			DELETE FROM t_data_managers_new;
            DELETE FROM t_data_managers_old;
            DELETE FROM t_data_celsius;
            pck_log.write_log('      Done!');
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
			pck_log.write_uncomplete_task_msg;
            RAISE e_extraction;
      END;

      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_clientes@DBLINK_SADSB');
      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_produtos@DBLINK_SADSB');
      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_promocoes@DBLINK_SADSB');
      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_linhasvenda_promocoes@DBLINK_SADSB');	
      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_linhasvenda@DBLINK_SADSB');	  
      INSERT INTO t_info_extractions (last_timestamp,source_table_name) VALUES (NULL,'view_vendas@DBLINK_SADSB');
      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_extraction;
   END;



   -- ********************************************************************
   -- *                     TABLE_EXTRACT                                *
   -- *                                                                  *
   -- * EXTRACT NEW AND CHANGED ROWS FROM SOURCE TABLE                   *
   -- * IN                                                               *
   -- *   p_source_table: the source table/view to use                   *
   -- *   p_attributes_src: list of attributes to extract from           *
   -- *   p_attributes_dest: list of attributes to fill                  *
   -- *   p_dsa_table: name of the t_data_* table to fill                *
   -- ********************************************************************
  PROCEDURE table_extract (p_source_table VARCHAR2, p_attributes_src VARCHAR2, p_attributes_dest VARCHAR2, p_DSA_table VARCHAR2) IS
      v_end_date TIMESTAMP;
      v_start_date t_info_extractions.LAST_TIMESTAMP%TYPE;
      v_sql  VARCHAR2(1000);
   BEGIN 
      pck_log.write_log('  Extracting data ["TABLE_EXTRACT ('||UPPER(p_source_table)||')"]');
	  pck_log.rowcount(p_DSA_table,'Before');    -- Logs how many rows the destination table initially contains

        -- STEP 1: CLEAN DESTINATION TABLE
      -- SOMETHING IS MISSING
      v_sql:='DELETE FROM ' || p_DSA_table;
      pck_log.write_log('    STEP 1: '||v_sql);
      EXECUTE IMMEDIATE v_sql;

         --  STEP 2: find the date of change of the last record extracted in the previous extraction 
         v_sql:='SELECT last_timestamp FROM t_info_extractions WHERE UPPER(source_table_name)='''||UPPER(p_source_table)||'''';
         pck_log.write_log('    STEP 2: '||v_sql);
         EXECUTE IMMEDIATE v_sql INTO v_start_date;

         --    ---------------------
         --   |   FISRT EXTRACTION  |
         --    ---------------------
        IF v_start_date IS NULL THEN

            -- STEP 3: FIND THE DATE OF CHANGE OF THE MOST RECENTLY CHANGED RECORD IN THE SOURCE TABLE
            -- SOMETHING IS MISSING
			   v_sql:='Select max(src_last_changed) FROM '||  p_source_table;
            pck_log.write_log('    STEP 3: '||v_sql);
            EXECUTE IMMEDIATE v_sql INTO v_end_date;


            -- STEP 4: EXTRACT ALL RELEVANT RECORDS FROM THE SOURCE TABLE TO THE DSA
            -- SOMETHING IS MISSING
    v_sql:='INSERT INTO ' || p_DSA_table || ' (' || p_attributes_dest || ') SELECT ' || p_attributes_src || ' FROM ' || p_source_table || ' WHERE SRC_LAST_CHANGED <= :1 OR SRC_LAST_CHANGED IS NULL';
            pck_log.write_log('    STEP 4: '||v_sql);
            EXECUTE IMMEDIATE v_sql USING v_end_date;

            -- STEP 5: UPDATE THE t_info_extractions TABLE
            -- SOMETHING IS MISSING
			 v_sql:='UPDATE t_info_extractions SET LAST_TIMESTAMP = :1 WHERE UPPER(source_table_name)='''||UPPER(p_source_table)||'''';
          pck_log.write_log('    STEP 5: '||v_sql);
            EXECUTE IMMEDIATE v_sql USING NVL(v_end_date, TO_DATE('1950-01-01', 'yyyy-mm-dd'));
         ELSE
         --    -------------------------------------
         --   |  OTHER EXTRACTIONS AFTER THE FIRST  |
         --    -------------------------------------
            -- STEP 3: FIND THE DATE OF CHANGE OF THE MOST RECENTLY CHANGED RECORD IN THE SOURCE TABLE
            -- SOMETHING IS MISSING
            
            v_sql:='SELECT MAX(SRC_LAST_CHANGED) FROM ' || p_source_table || ' WHERE SRC_LAST_CHANGED > :1';
            pck_log.write_log('    STEP 3: '||v_sql);
            EXECUTE IMMEDIATE v_sql INTO v_end_date USING v_start_date;

            IF v_end_date>v_start_date THEN
               -- STEP 4: EXTRACT ALL RELEVANT RECORDS FROM THE SOURCE TABLE TO THE DSA
               -- SOMETHING IS MISSING
               v_sql:='INSERT INTO ' || p_DSA_table || ' (' || p_attributes_dest || ') SELECT ' || p_attributes_src || ' FROM ' || p_source_table || ' WHERE SRC_LAST_CHANGED > :1 AND SRC_LAST_CHANGED <= :2';
               pck_log.write_log('    STEP 4: '||v_sql);
               EXECUTE IMMEDIATE v_sql USING v_start_date, v_end_date;

               -- STEP 5: UPDATE THE t_info_extractions TABLE
               -- SOMETHING IS MISSING
               v_sql:='UPDATE t_info_extractions SET LAST_TIMESTAMP = :1 WHERE UPPER(source_table_name)='''||UPPER(p_source_table)||'''';
               pck_log.write_log('    STEP 5: '||v_sql);
               EXECUTE IMMEDIATE v_sql USING v_end_date;

            END IF;
         END IF;

      pck_log.write_log('    Done!');
      pck_log.rowcount(p_DSA_table,'After');    -- Logs how many rows the destination table now contains
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_extraction;
   END;


   -- **************************************************************
   -- *                       FILE_EXTRACT                         *
   -- *                                                            *
   -- * EXTRACT ROWS FROM SOURCE FILE                              *
   -- * IN                                                         *
   -- *    p_external_table: the external table to use             *
   -- *    p_attributes_src: list of attributes to extract         *
   -- *    p_attributes_dest: list of attributes to fill           *
   -- *    p_dsa_table_new: name of the t_data_*_new table to fill *
   -- *    p_dsa_table_old: name of the t_data_*_old table to fill *
   -- **************************************************************
   PROCEDURE file_extract (p_external_table VARCHAR2, p_attributes_src VARCHAR2, p_attributes_dest VARCHAR2, p_dsa_table_new VARCHAR2, p_dsa_table_old VARCHAR2) IS
      v_sql  VARCHAR2(1000);
   BEGIN
      pck_log.write_log('  Extracting data ["FILE_EXTRACT ('||UPPER(p_external_table)||')"]');      
	  pck_log.rowcount(p_dsa_table_new,'Before');    -- Logs how many rows the destination table initially contains

      -- STEP 1: CLEAN _old TABLE
      v_sql:='DELETE FROM '||p_dsa_table_old;
      pck_log.write_log('    STEP 1: '||v_sql);
      EXECUTE IMMEDIATE v_sql;

      -- STEP 2: SOMETHING IS MISSING. THINK!
      
      v_sql:= 'INSERT INTO ' || p_dsa_table_old || '('|| p_attributes_dest || ') SELECT '|| p_attributes_dest || ' FROM ' || p_dsa_table_new;
      pck_log.write_log('    STEP 2: '||v_sql);
     EXECUTE IMMEDIATE v_sql;
      
      
      -- STEP 3: SOMETHING IS MISSING. THINK HARDER!
      -- ...
      
       v_sql:='DELETE FROM '||p_dsa_table_new;
      pck_log.write_log('    STEP 3: '||v_sql);
      EXECUTE IMMEDIATE v_sql;
      
     

      -- STEP 4: SOMETHING IS MISSING. THINK EVEN HARDER!
      -- ...
       v_sql:='INSERT INTO ' || p_dsa_table_new || ' (' || p_attributes_dest || ') SELECT ' || p_attributes_src || ' FROM ' || p_external_table;
      pck_log.write_log('    STEP 4: '||v_sql);
      EXECUTE IMMEDIATE v_sql;


      -- records the operation's SUCCESSFUL ending
	  pck_log.write_log('    Done!');
      pck_log.rowcount(p_dsa_table_new,'After');    -- Logs how many rows the destination table now contains
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_extraction;
   END;



   -- ********************************************************************
   -- *                TABLE_EXTRACT_NON_INCREMENTAL                     *
   -- *                                                                  *
   -- * EXTRACT ROWS FROM SOURCE TABLE IN NON INCREMENTAL WAY            *
   -- * IN: (same as table_extract)                                      *
   -- ********************************************************************
   PROCEDURE table_extract_non_incremental (p_source_table VARCHAR2, p_DSA_table VARCHAR2, p_attributes_src VARCHAR2, p_attributes_dest VARCHAR2) IS
      v_sql  VARCHAR2(1000);
   BEGIN 
      pck_log.write_log('  Extracting data ["TABLE_EXTRACT_NON_INCREMENTAL ('||UPPER(p_source_table)||')"]');
	  pck_log.rowcount(p_DSA_table,'Before');    -- Logs how many rows the destination table initially contains
      -- LIMPAR A TABELA DESTINO
      EXECUTE IMMEDIATE 'DELETE FROM '||p_DSA_table;

      -- extrair TODOS os registos da tabela fonte para a tabela correspondente na DSA
      v_sql:='INSERT INTO '||p_DSA_table||'('|| p_attributes_dest||',rejected_by_screen) SELECT '||p_attributes_src||',''0'' FROM '||p_source_table;
      EXECUTE IMMEDIATE v_sql;

	  pck_log.write_log('    Done!');	  
	  pck_log.rowcount(p_DSA_table,'After');    -- Logs how many rows the destination table now contains
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_extraction;
   END;


   PROCEDURE web_extract (p_src_link VARCHAR2, p_DSA_table VARCHAR2, p_src_attributes VARCHAR2, p_target_attributes VARCHAR2) IS
      l_data CLOB;

      PROCEDURE store_json_data (p_data VARCHAR2, p_src_attributes VARCHAR2, p_target_attributes VARCHAR2, p_target_table VARCHAR2) IS
         l_pos_inicial PLS_INTEGER;
         l_pos_final PLS_INTEGER;
         l_pos_atual_json PLS_INTEGER;
         l_pos_final_registo PLS_INTEGER;
         l_pos_atributo PLS_INTEGER;
         l_pos_dados_inicial PLS_INTEGER;
         l_pos_dados_final PLS_INTEGER;
         l_registo VARCHAR2(1000);
         l_atributo VARCHAR2(40);
         v_sql VARCHAR2(500);
         l_valores VARCHAR2(100);
         l_pos_virgula  PLS_INTEGER;
         l_string_to_parse	VARCHAR2(500) := p_src_attributes||',';
         l_pos_atual_parse_src PLS_INTEGER;
         l_aux PLS_INTEGER;
      BEGIN
         l_pos_inicial:= instr(l_data, '[');
         l_pos_final:= instr(l_data, ']', l_pos_inicial);
         l_pos_atual_json := l_pos_inicial;
         /* ENQUANTO “]” não atingido FAZ */
         LOOP 
            -- reinicia a lista de valores a inserir
            l_valores:='';
            l_pos_atual_json:=instr(l_data,'{',l_pos_atual_json);
            -- termina quando não houver mais registos json para ler
            EXIT WHEN l_pos_atual_json=0;

            l_pos_final_registo:=instr(l_data,'}',l_pos_atual_json);
            -- lê o registo atual dos dados JSON
            l_registo:=substr(l_data,l_pos_atual_json,l_pos_final_registo-l_pos_atual_json);
            -- lê atributos solicitados, atualmente só 1 permitido
            l_pos_atual_parse_src:=1;
            l_aux:=0;
            LOOP  -- faz o parse dos atributos origem, 1 a um; por cada um lê-o registo JSON
               l_pos_virgula:=INSTR(l_string_to_parse,',',l_pos_atual_parse_src);
               EXIT WHEN l_pos_virgula=0;
               IF (l_aux>0) THEN
                  l_valores:=l_valores||',';
               END IF;
               l_aux:=l_aux+1;
               l_atributo:='"'||SUBSTR(l_string_to_parse,l_pos_atual_parse_src,l_pos_virgula-l_pos_atual_parse_src)||'": ';
               l_pos_atual_parse_src:=l_pos_virgula+1;
               -- procura o atributo dentro do registo JSON
               l_pos_atributo:=instr(l_data,l_atributo,l_pos_atual_json);
               IF (l_pos_atributo>0) THEN
                  l_pos_dados_inicial:=l_pos_atributo+length(l_atributo);
                  l_pos_dados_final:=instr(l_data,',',l_pos_dados_inicial);
                  l_valores:=l_valores||REPLACE(substr(l_data,l_pos_dados_inicial,l_pos_dados_final-l_pos_dados_inicial),'"');
               END IF;
               -- stores the data into the target table          
            END LOOP;   -- fim do parse dos atributos origem
            l_pos_atual_json:=l_pos_final_registo;
            v_sql:='INSERT INTO '||p_target_table||'('||p_target_attributes||') VALUES ('||l_valores||')';
            EXECUTE IMMEDIATE v_sql;
         END LOOP;
      END;

   BEGIN
      pck_log.write_log('  Extracting data ["WEB_EXTRACT ('||UPPER(p_src_link)||')"]');
      pck_log.rowcount(p_DSA_table,'Before');    -- Logs how many rows the destination table initially contains
      -- LIMPAR A TABELA DESTINO
      EXECUTE IMMEDIATE 'DELETE FROM '||p_DSA_table;

      /* read the JSON data from the webpage */
      l_data:=pck_utilities.read_web_data(p_src_link);

      /* parse the data to store the necessary data*/
      store_json_data (l_data, p_src_attributes, p_target_attributes, p_DSA_table);

	  pck_log.write_log('    Done!');	  
	  pck_log.rowcount(p_DSA_table,'After');    -- Logs how many rows the destination table now contains
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_extraction;
   END;

   -- ***************************************************************************************
   -- *                                        MAIN                                         *
   -- *                                                                                     *
   -- * EXECUTES THE EXTRACTION PROCESS                                                     *
   -- * IN                                                                                  *
   -- *     p_initialize: TRUE=t_info_extractions will be cleaned and then filled           *
   -- ***************************************************************************************
   PROCEDURE main (p_initialize BOOLEAN) IS
   BEGIN
      pck_log.clean;
      pck_log.write_log('*****  EXTRACT  EXTRACT  EXTRACT  EXTRACT  EXTRACT  EXTRACT  EXTRACT  *****');      -- DUPLICATES THE LAST ITERATION AND THE CORRESPONDING SCREEN SCHEDULE

      -- INITIALIZE THE EXTRACTION TABLE t_info_extractions
      IF p_initialize = TRUE THEN
         initialize_extractions_table(TRUE);
      END IF;

      -- EXTRACT FROM SOURCE TABLES

      -- SOMETHING IS MISSING: maybe... a table extraction
	  
    --uncomented
      table_extract('view_produtos@dblink_sadsb', 'src_id,src_name,src_brand,src_width,src_height,src_depth,src_pack_type,src_calories_100g,src_liq_weight,src_category_id','id,name,brand,width,height,depth,pack_type,calories_100g,liq_weight,category_id', 't_data_products');
      table_extract('view_promocoes@dblink_sadsb', 'src_id,src_name,src_start_date,src_end_date,src_reduction,src_on_outdoor,src_on_tv','id,name,start_date,end_date,reduction,on_outdoor,on_tv', 't_data_promotions');	  
      table_extract('view_linhasvenda_promocoes@dblink_sadsb', 'src_line_id,src_promo_id','line_id,promo_id', 't_data_linesofsalepromotions');	  
      table_extract('view_linhasvenda@dblink_sadsb', 'src_id,src_sale_id,src_product_id,src_quantity,src_ammount_paid,src_line_date', 'id,sale_id,product_id,quantity,ammount_paid,line_date', 't_data_linesofsale');
      table_extract_non_incremental('view_categorias@dblink_sadsb','t_data_categories', 'src_id,src_name', 'id,name');

      table_extract('view_vendas@dblink_sadsb', 'src_id,src_sale_date,src_store_id,src_customer_id', 'id,sale_date,store_id,customer_id', 't_data_sales');
      table_extract('view_clientes@dblink_sadsb', 'src_id,src_card_number,src_name,src_address,src_location,src_district,src_zip_code,src_phone_nr,src_gender,src_age,src_marital_status', 'id,card_number,name,address,location,district,zip_code,phone_nr,gender,age,marital_status', 't_data_customers');

      -- SOMETHING IS MISSING: maybe... a file extraction
      file_extract ('t_ext_stores', 'name,refer,building,address,zip_code,city,district,phone_nrs,fax_nr,closure_date','name,reference,building,address,zip_code,location,district,telephones,fax,closure_date','t_data_stores_new', 't_data_stores_old');
	  --null;
      file_extract('t_ext_managers','reference,manager_name,manager_since','reference,manager_name,manager_since','t_data_managers_new','t_data_managers_old');

      -- now, get the IPMA data from the web
      web_extract('http://api.ipma.pt/open-data/forecast/meteorology/cities/daily/hp-daily-forecast-day0.json','t_data_celsius','globalIdLocal,tMax,tMin','id_local,t_max,t_min');
    
      COMMIT;
      pck_log.write_log('  All extracted data commited to database.');
   EXCEPTION
      WHEN e_extraction THEN
         pck_log.write_halt_msg;
         ROLLBACK;
      WHEN OTHERS THEN
         ROLLBACK;
         pck_log.write_uncomplete_task_msg;
         pck_log.write_halt_msg;
   END;

END pck_extract;
