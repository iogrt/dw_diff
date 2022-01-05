CREATE OR REPLACE package pck_load is
   PROCEDURE main (p_load_dates BOOLEAN, p_init_dimensions BOOLEAN);
END;



/


CREATE OR REPLACE package body pck_load is

   e_load EXCEPTION;

   -- ***************************************************
   -- * INITIALIZES DIMENSIONS WITH AN 'INVALID RECORD' *
   -- ***************************************************
   PROCEDURE init_dimensions IS
   BEGIN
      pck_log.write_log('  Initializing all dimensions with "invalid" records');
      -- 'INVALID PRODUCT'
      INSERT INTO t_dim_product (product_key,product_natural_key,product_name,product_brand,product_category,product_size_package,product_type_package,product_diet_type,product_liquid_weight,is_expired_version)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, pck_error_codes.c_load_invalid_dim_record_Nkey,'INVALID PRODUCT',NULL,NULL,NULL,NULL,NULL,NULL,'NO');
      -- 'INVALID PROMOTION'
      INSERT INTO t_dim_promotion (promo_key,promo_natural_key,promo_name,promo_red_price,promo_advertise,promo_board,promo_start_date,promo_end_date)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, pck_error_codes.c_load_invalid_dim_record_Nkey,'INVALID PROMOTION',NULL,NULL,NULL,NULL,NULL);
      -- 'INVALID DATE'
      INSERT INTO t_dim_date (date_key,date_full_date,date_month_full,date_month_name,date_month_short_name,date_month_nr,date_quarter_nr,date_quarter_full,date_semester_nr,date_semester_full,date_event,date_year, date_day_nr,date_is_holiday)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, 'INVALID',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      -- 'INVALID TIME'
      INSERT INTO t_dim_time (time_key,time_full_time,time_period_of_day,time_minutes_after_midnight,time_hour_nr,time_minute_nr,time_second_nr)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, 'INVALID',NULL,NULL,NULL,NULL,NULL);
      -- 'INVALID STORE'
      INSERT INTO t_dim_store (store_key,store_natural_key,store_name,store_full_address,store_location,store_district,store_zip_code,store_main_phone,store_main_phone_old,store_fax,store_fax_old,store_manager_name,store_manager_since,store_state,is_expired_version)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, pck_error_codes.c_load_invalid_dim_record_Nkey, 'INVALID STORE', 'NOT APPLICABLE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO');
      -- 'INVALID CUSTOMER'
      INSERT INTO t_dim_customer (customer_key, customer_natural_key, customer_card_number, customer_name, customer_address, customer_location, customer_district, customer_zip_code, customer_phone_nr, customer_gender, customer_gender_old, customer_age, customer_marital_status, is_expired_version)
      VALUES (pck_error_codes.c_load_invalid_dim_record_key, pck_error_codes.c_load_invalid_dim_record_Nkey, NULL,'INVALID CUSTOMER',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'NO');

      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;



   -- ***********************************
   -- * LOADS THE 'PROMOTION' DIMENSION *
   -- ***********************************
   PROCEDURE load_dim_promotion IS
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_PROMOTIONS"]');
	  pck_log.rowcount('t_dim_promotion','Before');
      -- FOR EACH NEW OR UPDATED SOURCE PROMOTION
      MERGE INTO t_dim_promotion dim
      USING (SELECT id,name,start_date,end_date,reduction,on_street,on_tv
             FROM t_clean_promotions) clean
      ON (dim.promo_natural_key = clean.id)
      WHEN MATCHED THEN UPDATE SET dim.promo_name=clean.name,
                                   dim.promo_red_price=clean.reduction,
                                   dim.promo_advertise=clean.on_tv,
                                   dim.promo_board=clean.on_street,
                                   dim.promo_start_date=clean.start_date,
                                   dim.promo_end_date=clean.end_date
      WHEN NOT MATCHED THEN INSERT (dim.promo_key,dim.promo_natural_key,dim.promo_name,dim.promo_red_Price,dim.promo_advertise,dim.promo_board,dim.promo_start_date,dim.promo_end_date)
                            VALUES (seq_dim_promotion.NEXTVAL,clean.id,clean.name,clean.reduction,clean.on_tv,clean.on_street,clean.start_date,clean.end_date);

      pck_log.rowcount('t_dim_promotion','After');
      pck_log.write_log('    Done!');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;



   -- *********************************
   -- * LOADS THE 'PRODUCT' DIMENSION *
   -- *********************************
   PROCEDURE load_dim_product IS
      CURSOR products_cursor IS
         SELECT id,name,brand,pack_size,pack_type,diet_type,liq_weight,category_name
         FROM t_clean_products;

      -- statistic counters
      i INTEGER:=0;
      v_new_products INTEGER:=0;
      v_new_versions INTEGER:=0;
      v_old_versions INTEGER:=0;
      -- variables for SCD checking
      v_product_key t_dim_product.product_key%TYPE;
      v_size_package t_dim_product.product_size_package%TYPE;
      v_type_package t_dim_product.product_type_package%TYPE;
      v_diet_type t_dim_product.product_diet_type%TYPE;
      v_liquid_weight t_dim_product.product_liquid_weight%TYPE;
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_PRODUCT"]');
	  pck_log.rowcount('t_dim_product','Before');
      FOR rec IN products_cursor LOOP
         -- SEARCHES THE PRODUCT IN THE DIMENSION BY SELECTING SCD2 ATTRIBUTES
         BEGIN
            SELECT product_key, NVL(UPPER(product_size_package),-1),NVL(UPPER(product_type_package),-1),UPPER(product_diet_type),NVL(product_liquid_weight,-1)
            INTO v_product_key,v_size_package,v_type_package,v_diet_type,v_liquid_weight
            FROM t_dim_product
            WHERE product_natural_key=rec.id AND is_expired_version='NO';

            -- IF A RECORD WAS FOUND, THEN THE SOURCE PRODUCT IS IN FACT A NEW VERSION:
            -- I WONDER IF ANY OF THE SCD2 ATTRIBUTES HAVE CHANGED?
            IF NVL(UPPER(rec.pack_size),-1)!=v_size_package OR
               NVL(UPPER(rec.pack_type),-1)!=v_type_package OR
               UPPER(rec.diet_type)!=v_diet_type OR
               rec.liq_weight!=v_liquid_weight THEN

               --  1. UPDATES THE PREVIOUS VERSION OF THE PRODUCT IN THE DIMENSION TO 'EXPIRED'
               UPDATE t_dim_product
               SET is_expired_version='YES'
               WHERE product_key=v_product_key;

               -- 2. INSERTS THE NEW PRODUCT'S VERSION
               INSERT INTO t_dim_product (product_key,PRODUCT_NATURAL_KEY,PRODUCT_NAME,PRODUCT_BRAND,PRODUCT_CATEGORY,PRODUCT_SIZE_PACKAGE,PRODUCT_TYPE_PACKAGE,PRODUCT_DIET_TYPE,PRODUCT_LIQUID_WEIGHT,IS_EXPIRED_VERSION)
               VALUES (seq_dim_product.NEXTVAL, rec.id,rec.name,rec.brand,rec.category_name,rec.pack_size,rec.pack_type,rec.diet_type,rec.liq_weight,'NO');
               v_new_versions:=v_new_versions+1;
            ELSE
               -- NO SCD2 ATTRIBUTES CHANGED? THEN AT LEAST ONE SCD1 ATTRIBUTE MUST BE DIFFERENT
               --  UPDATES THE SCD1 ATTRIBTES OF THE MOST RECENT VERSION OF THE PRODUCT
               UPDATE t_dim_product
               SET product_name=rec.name,product_brand=rec.brand,product_category=rec.category_name
               WHERE product_key=v_product_key;
               v_old_versions:=v_old_versions+1;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               -- IF NOT FOUND, THEN ITS A NEW PRODUCT
               INSERT INTO t_dim_product (product_key,PRODUCT_NATURAL_KEY,PRODUCT_NAME,PRODUCT_BRAND,PRODUCT_CATEGORY,PRODUCT_SIZE_PACKAGE,PRODUCT_TYPE_PACKAGE,PRODUCT_DIET_TYPE,PRODUCT_LIQUID_WEIGHT,IS_EXPIRED_VERSION)
               VALUES (seq_dim_product.NEXTVAL, rec.id,rec.name,rec.brand,rec.category_name,rec.pack_size,rec.pack_type,rec.diet_type,rec.liq_weight,'NO');
               v_new_products:=v_new_products+1;
         END;
      END LOOP;
      -- RECORDS SOME STATISTICS CONCERNING LOADED PRODUCTS
      pck_log.write_log('    '||v_old_versions|| ' old product(s) updated in SCD1 attributes');
      pck_log.write_log('    '||v_new_versions|| ' old product(s) got new version(s) (old have expired)');
      pck_log.write_log('    '||v_new_products|| ' new product(s) found and loaded','    Done!');
	  pck_log.rowcount('t_dim_product','After');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;


   -- *********************************
   -- * LOADS THE 'CUSTOMER' DIMENSION *
   -- *********************************
   PROCEDURE load_dim_customer IS
      CURSOR customers_cursor IS
         SELECT  id, card_number, name, address, location, district, zip_code, phone_nr, gender, age, marital_status
         FROM t_clean_customers;

      -- statistic counters
      i INTEGER:=0;
      v_new_customers INTEGER:=0;
      v_new_versions INTEGER:=0;
      v_old_versions INTEGER:=0;
      -- variables for SCD checking
      v_key t_dim_customer.customer_key%TYPE;
      v_location t_dim_customer.customer_location%TYPE;
      v_district t_dim_customer.customer_district%TYPE;
      v_zip_code t_dim_customer.customer_zip_code%TYPE;
      v_gender t_dim_customer.customer_gender%TYPE;
      v_gender_old v_gender%TYPE;
      v_age t_dim_customer.customer_age%TYPE;
      v_marital_status t_dim_customer.customer_marital_status%TYPE;
  BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_CUSTOMER"]');
      pck_log.rowcount('t_dim_customer');
      FOR rec IN customers_cursor LOOP
         -- SEARCHES THE STORE IN THE DIMENSION BY SELECTING SCD2 AND SCD3 ATTRIBUTES (store_main_phone,store_fax)
         BEGIN
            SELECT customer_key, customer_location, customer_district,customer_zip_code, customer_gender, customer_age, customer_marital_status
            INTO v_key, v_location, v_district, v_zip_code, v_gender, v_age, v_marital_status
            FROM t_dim_customer
            WHERE customer_natural_key=rec.id AND is_expired_version='NO';

            -- IF A RECORD WAS FOUND, THEN THE SOURCE STORE IS IN FACT A NEW CUSTOMER VERSION:
            -- I WONDER IF THE SCD3 ATTRIBUTE (customer_gender) HAS CHANGED?
            v_gender_old:=NULL;
            IF rec.gender<>v_gender THEN
               -- the old gender is kept
               v_gender_old:=v_gender;
            END IF;

            -- WHAT ABOUT SCD2 ATTRIBUTES: HAVE THEY CHANGED?
            IF rec.location!=v_location OR
               rec.district!=v_district OR
               rec.zip_code!=v_zip_code OR 
               rec.age!=v_age OR
               rec.marital_status!=v_marital_status THEN
               --  1. UPDATES THE PREVIOUS VERSION OF THE CUSTOMER IN THE DIMENSION TO THE STATE 'EXPIRED'
               UPDATE t_dim_customer
               SET is_expired_version='YES'
               WHERE customer_key=v_key;

               -- 2. INSERTS THE NEW CUSTOMER'S VERSION
               INSERT INTO t_dim_customer (customer_key, customer_natural_key, customer_card_number, customer_name, customer_address, customer_location, customer_district, customer_zip_code, customer_phone_nr, customer_gender, customer_gender_old, customer_age, customer_marital_status, is_expired_version)
               VALUES (seq_dim_customer.NEXTVAL, rec.id, rec.card_number,rec.name,rec.address,rec.location,rec.district, rec.zip_code,rec.phone_nr,rec.gender,v_gender_old, rec.age, rec.marital_status,'NO');
               v_new_versions:=v_new_versions+1;
            ELSE
               -- NO SCD2 ATTRIBUTES CHANGED? THEN AT LEAST ONE SCD1 OR SCD3 ATTRIBUTE MUST BE DIFFERENT
               -- UPDATES THE SCD1 ATTRIBUTES OF THE MOST RECENT VERSION OF THE CUSTOMER
               UPDATE t_dim_customer
                  -- SCD1
               SET customer_card_number=rec.card_number,
                   customer_name=rec.name,
                   customer_address=rec.address,
                   customer_phone_nr=rec.phone_nr,
                   -- SCD3
                   customer_gender=rec.gender,
                   customer_gender_old=v_gender_old
               WHERE customer_key=v_key;

               v_old_versions:=v_old_versions+1;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               -- IF NOT FOUND, THEN ITS A NEW CUSTOMER
               -- SCD3 _old ATTRIBUTE IS NOT FILLED
               INSERT INTO t_dim_customer (customer_key, customer_natural_key, customer_card_number, customer_name, customer_address, customer_location, customer_district, customer_zip_code, customer_phone_nr, customer_gender, customer_gender_old, customer_age, customer_marital_status, is_expired_version)
               VALUES (seq_dim_customer.NEXTVAL, rec.id, rec.card_number,rec.name,rec.address,rec.location,rec.district, rec.zip_code,rec.phone_nr,rec.gender,NULL, rec.age, rec.marital_status, 'NO');
               v_new_customers:=v_new_customers+1;
         END;
      END LOOP;
      -- RECORDS SOME STATISTICS CONCERNING LOADED PRODUCTS
      pck_log.write_log('    '||v_old_versions|| ' old customer(s) updated in SCD1 attributes','    '||v_new_versions|| ' old customer(s) got new version(s) (old have expired)');
      pck_log.write_log('    '||v_new_customers|| ' new customer(s) found and loaded','    Done!');
	  pck_log.rowcount('t_dim_customer');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;




   -- *******************************
   -- * LOADS THE 'STORE' DIMENSION *
   -- *******************************
   PROCEDURE load_dim_store IS
      CURSOR stores_cursor IS
         SELECT name,reference,address,zip_code,location,district,telephones,fax,status,manager_name,manager_since
         FROM t_clean_stores;

      -- statistic counters
      i INTEGER:=0;
      v_new_stores INTEGER:=0;
      v_new_versions INTEGER:=0;
      v_old_versions INTEGER:=0;
      -- variables for SCD checking
      v_store_key t_dim_store.store_key%TYPE;
      v_store_name t_dim_store.store_name%TYPE;
      v_manager_name t_dim_store.store_manager_name%TYPE;
      v_manager_since t_dim_store.store_manager_since%TYPE;
      v_store_main_phone t_dim_store.store_main_phone%TYPE;
      v_store_fax t_dim_store.store_fax%TYPE;
      v_old_main_phone t_dim_store.store_main_phone%TYPE;
      v_old_fax t_dim_store.store_fax%TYPE;
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_STORE"]');
      pck_log.rowcount('t_dim_store');
      FOR rec IN stores_cursor LOOP
         -- SEARCHES THE STORE IN THE DIMENSION BY SELECTING SCD2 AND SCD3 ATTRIBUTES (store_main_phone,store_fax)
         BEGIN
            SELECT store_key, UPPER(store_name),UPPER(store_manager_name),store_manager_since, store_main_phone,store_fax
            INTO v_store_key,v_store_name,v_manager_name,v_manager_since,v_store_main_phone,v_store_fax
            FROM t_dim_store
            WHERE store_natural_key=rec.reference AND is_expired_version='NO';

            -- IF A RECORD WAS FOUND, THEN THE SOURCE STORE IS IN FACT A NEW STORE VERSION:
            -- I WONDER IF ANY OF THE SCD3 ATTRIBUTES (store_main_phone,store_fax) HAVE CHANGED?
            v_old_main_phone:=NULL;
            IF rec.telephones<>v_store_main_phone THEN
               -- the old phone is kept
               v_old_main_phone:=v_store_main_phone;
            END IF;
            v_old_fax:=NULL;
            IF rec.fax<>v_store_fax THEN
               -- the old fax is kept
               v_old_fax:=v_store_fax;
            END IF;

            -- I WONDER IF ANY OF THE SCD2 ATTRIBUTES HAVE CHANGED?
            IF UPPER(rec.name)!=v_store_name OR
               UPPER(rec.manager_name)!=v_manager_name OR
               rec.manager_since!=v_manager_since THEN
               --  1. UPDATES THE PREVIOUS VERSION OF THE STORE IN THE DIMENSION TO THE STATE 'EXPIRED'
               UPDATE t_dim_store
               SET is_expired_version='YES'
               WHERE store_key=v_store_key;

               -- 2. INSERTS THE NEW STORE'S VERSION
               INSERT INTO t_dim_store (store_key,store_natural_key,store_name,store_full_address,store_location,store_district,store_zip_code,store_main_phone,store_main_phone_old,store_fax,store_fax_old,store_manager_name,store_manager_since,store_state,is_expired_version)
               VALUES (seq_dim_store.NEXTVAL, rec.reference,rec.name,rec.address,rec.location,rec.district,rec.zip_code,rec.telephones,v_old_main_phone,rec.fax,v_old_fax,rec.manager_name,rec.manager_since,rec.status,'NO');
               v_new_versions:=v_new_versions+1;
            ELSE
               -- NO SCD2 ATTRIBUTES CHANGED? THEN AT LEAST ONE SCD1 OR SCD3 ATTRIBUTE MUST BE DIFFERENT
               -- UPDATES THE SCD1 ATTRIBUTES OF THE MOST RECENT VERSION OF THE STORE
               UPDATE t_dim_store
               SET store_full_address=rec.address,
                   store_location=rec.location,
                   store_district=rec.district,
                   store_zip_code=rec.zip_code,
                   store_manager_since=rec.manager_since,
                   store_manager_name=rec.manager_name,
                   -- SCD3 attributes
                   store_main_phone=rec.telephones,
                   store_fax=rec.fax,
                   store_main_phone_old=v_old_main_phone,
                   store_fax_old=v_old_fax
               WHERE store_key=v_store_key;

               v_old_versions:=v_old_versions+1;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               -- IF NOT FOUND, THEN ITS A NEW STORE
               -- SCD3 _old ATTRIBUTES ARE NOT FILLED
               INSERT INTO t_dim_store (store_key,store_natural_key,store_name,store_full_address,store_location,store_district,store_zip_code,store_main_phone,store_main_phone_old,store_fax,store_fax_old,store_manager_name,store_manager_since,store_state,is_expired_version)
               VALUES (seq_dim_store.NEXTVAL, rec.reference,rec.name,rec.address,rec.location,rec.district,rec.zip_code,rec.telephones,NULL,rec.fax,NULL,rec.manager_name,rec.manager_since,rec.status,'NO');
               v_new_stores:=v_new_stores+1;
         END;
      END LOOP;
      -- RECORDS SOME STATISTICS CONCERNING LOADED PRODUCTS
      pck_log.write_log('    '||v_old_versions|| ' old store(s) updated in SCD1 attributes','    '||v_new_versions|| ' old store(s) got new version(s) (old have expired)');
      pck_log.write_log('    '||v_new_stores|| ' new store(s) found and loaded','    Done!');
	  pck_log.rowcount('t_dim_store');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;



   -- ******************************
   -- * LOADS THE 'DATE' DIMENSION *
   -- ******************************
   PROCEDURE load_dim_date(p_load_dates_from_file BOOLEAN) IS
      l_today VARCHAR2(10);   -- today's date
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_DATE"]');
      -- LOAD ALL DATE RECORDS USING THE EXTERNAL TABLE 't_external_date'
      IF (p_load_dates_from_file=TRUE) THEN
         INSERT INTO t_dim_date(date_key,date_full_date,date_month_full,date_month_name,date_month_short_name,date_month_nr,date_quarter_nr,date_quarter_full,date_semester_nr,date_semester_full,date_day_nr,date_is_holiday,date_event,date_year)
            SELECT 	date_key,
            date_full_date,
            date_month_full,
            date_month_name,
            date_month_short_name,
            date_month_nr,
            date_quarter_nr,
            date_quarter_full,
            date_semester_nr,
            date_semester_full,
            date_day_nr,
            date_is_holiday,
            date_event,
            date_year
            FROM t_ext_dates;
      END IF;

      -- RECORDS LOG
      pck_log.write_log('    '||SQL%ROWCOUNT ||' record(s) successfully loaded','    Done!');

      -- find today's date
      l_today:=TO_CHAR(SYSDATE,'dd/mm/yyyy');
      -- UPDATE THE TEMPERATURE STATUS
      UPDATE t_dim_date
      SET date_temperature_status=(SELECT temperature_status
                                   FROM t_clean_celsius
                                   WHERE forecast_date=l_today)
      WHERE date_full_date=l_today;

      -- RECORDS LOG
      pck_log.write_log('    '||SQL%ROWCOUNT ||' temperature row(s) updated','    Done!');

   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;



   -- ******************************
   -- * LOADS THE 'TIME' DIMENSION *
   -- ******************************
   PROCEDURE load_dim_time IS
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_DIM_TIME"]');
      -- LOAD ALL TIME RECORDS USING THE EXTERNAL TABLE 't_external_time'
      INSERT INTO /*+ APPEND */ t_dim_time(time_key,time_full_time,time_period_of_day,time_minutes_after_midnight,time_hour_nr,time_minute_nr,time_second_nr)
         SELECT 	time_key,
                  time_full_time,
                  time_period_of_day,
                  time_minutes_after_00,
                  time_hour_nr,
                  time_minute_nr,
                  time_second_nr
         FROM t_ext_time;

      pck_log.write_log('    '||SQL%ROWCOUNT ||' record(s) successfully loaded','    Done!');
   EXCEPTION
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;



   -- ************************
   -- * LOADS THE FACT TABLE *
   -- ************************
   PROCEDURE load_fact_table IS
      v_source_lines INTEGER;
   BEGIN
      pck_log.write_log('  Loading data ["LOAD_FACT_TABLE"]');
      -- JUST FOR STATISTICS
      SELECT COUNT(*)
      INTO v_source_lines
      FROM t_clean_linesofsale;

      INSERT INTO t_fact_lineofsale (product_key,store_key,promo_key,date_key,time_key,customer_key,sold_quantity,ammount_sold,sale_id_dd)
      SELECT
         product_key,
         store_key,
         promo_key,
         date_key,
         time_key,
         customer_key,
         los.quantity,
         los.ammount_paid,
         los.sale_id
      FROM
         t_dim_product,
         t_dim_store,
         t_dim_promotion,
         t_dim_date,
         t_dim_time,
         t_dim_customer,
         t_clean_linesofsale los,
         t_clean_sales sales
      WHERE
         -- join between the two source tables
         sales.id=los.sale_id AND
         -- joins to get dimension keys using sources' natural keys
         los.product_id = t_dim_product.product_natural_key AND
         NVL(los.promo_id,pck_error_codes.c_load_invalid_dim_record_NKey) = t_dim_promotion.promo_natural_key AND
         sales.store_id = t_dim_store.store_natural_key AND
         sales.customer_id = t_dim_customer.customer_natural_key AND
         TO_CHAR(sales.sale_date,'dd/mm/yyyy') = t_dim_date.date_full_date AND
         TO_CHAR(los.line_date,'hh24:mi:ss')=t_dim_time.time_full_time AND
         -- excludes EXPIRED VERSIONS of product and store dimensions
         t_dim_store.is_expired_version='NO' AND
         t_dim_product.is_expired_version='NO' AND
         t_dim_customer.is_expired_version='NO';

      pck_log.write_log('    '||SQL%ROWCOUNT ||' fact(s) loaded','    Done!');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pck_log.write_log('    No facts generated from '||v_source_lines||' source lines-of-sale');
      WHEN OTHERS THEN
         pck_log.write_uncomplete_task_msg;
         RAISE e_load;
   END;




   -- *****************************************************************************************************
   -- *                                             MAIN                                                  *
   -- *                                                                                                   *
   -- * EXECUTES THE LOADING PROCESS                                                                      *
   -- * IN                                                                                                *
   -- *     p_load_dates: TRUE=t_dim_date dimension will be loaded                                        *
   -- *     p_init_dimensions: TRUE=all dimensions will be filled with an INVALID record                  *
   -- *****************************************************************************************************
   PROCEDURE main (p_load_dates BOOLEAN,
                   p_init_dimensions BOOLEAN) IS
   BEGIN
      pck_log.clean;
      pck_log.write_log(' ','*****  LOAD  LOAD  LOAD  LOAD  LOAD  LOAD  LOAD  LOAD  *****');

      -- LOADS 'DATE' DIMENSIONS
      IF p_load_dates THEN
         load_dim_time;
      END IF;
      load_dim_date(p_load_dates);  -- loads dates from file or just updates weather status

      -- INTIALIZE DIMENSIONS
      IF p_init_dimensions THEN
         init_dimensions;
      END IF;

      -- LOAD DIMENSIONS
      load_dim_customer;
      load_dim_product;
      load_dim_promotion;
      load_dim_store;
      load_fact_table;

      COMMIT;
      pck_log.write_log('  All data loaded and commited to database');
   EXCEPTION
      WHEN e_load THEN
         pck_log.write_halt_msg;
         ROLLBACK;
      WHEN OTHERS THEN
         ROLLBACK;
         pck_log.write_uncomplete_task_msg;
         pck_log.write_halt_msg;
   END;
end pck_load;
/
