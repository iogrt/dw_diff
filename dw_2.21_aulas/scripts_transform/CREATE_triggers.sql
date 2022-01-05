CREATE OR REPLACE TRIGGER tri_bi_screen
BEFORE INSERT ON t_tel_screen
FOR EACH ROW
DECLARE
   v_screen_version t_tel_screen.screen_version%TYPE;
   v_screen_key t_tel_screen.screen_key%TYPE;
BEGIN
   -- GENERATES A SEQUENTIAL KEY FOR THE NEW SCREEN
   :NEW.screen_key:=seq_tel_screen.NEXTVAL;

   -- THE NEW SCREEN WILL BE SEEN AS THE LATEST VERSION
   :NEW.screen_expired:='NO';

   SELECT screen_key, screen_version
   INTO v_screen_key, v_screen_version
   FROM t_tel_screen
   WHERE UPPER(screen_name)=UPPER(:NEW.screen_name) AND screen_expired='NO';

   -- THE MOST RECENT VERSION OF THE SCREEN BECOMES NOW EXPIRED
   UPDATE t_tel_screen
   SET screen_expired='YES'
   WHERE screen_key=v_screen_key;

   :NEW.screen_version:=v_screen_version+1;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      :NEW.screen_version:=1;
END;
/

CREATE OR REPLACE TRIGGER tri_bi_iteration
BEFORE INSERT ON t_tel_iteration
FOR EACH ROW
BEGIN
   :NEW.iteration_key:=seq_tel_iteration.NEXTVAL;
END;
/


create or replace TRIGGER tri_bi_source
BEFORE INSERT ON t_tel_source
FOR EACH ROW
BEGIN
   -- GENERATES A SEQUENTIAL KEY FOR THE NEW SOURCE
   :NEW.source_key:=seq_tel_source.NEXTVAL;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      null;
END;
/
