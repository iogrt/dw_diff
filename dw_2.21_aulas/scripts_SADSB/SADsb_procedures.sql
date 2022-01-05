create or replace PROCEDURE reset_dados (p_confirm CHAR DEFAULT '0') AS
   e_data_failure EXCEPTION;
   e_other EXCEPTION;
   e_aborted_by_user EXCEPTION;

   -- ATIVA/DESATIVA OS TRIGGERS
   PROCEDURE alterar_triggers (p_valor VARCHAR2) AS
   BEGIN
      FOR rec IN (SELECT trigger_name FROM user_triggers) LOOP
         EXECUTE IMMEDIATE 'ALTER TRIGGER '|| rec.trigger_name ||' '|| p_valor;
      END LOOP;
   END;

   PROCEDURE reset_dados_do_it AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- limpa as tabelas com dados clonados
      DELETE FROM t_linhasVenda_promocoes;
      DELETE FROM t_linhasVenda;
      DELETE FROM t_vendas;
      DELETE FROM t_promocoes;
      DELETE FROM t_produtos;
      DELETE FROM t_categ;
      DELETE FROM t_clientes;

      -- faz a clonagem dos dados
      INSERT INTO t_categ SELECT * FROM sb_tables_original.t_categ;
      INSERT INTO t_clientes SELECT * FROM sb_tables_original.t_clientes;
      INSERT INTO t_produtos SELECT * FROM sb_tables_original.t_produtos;
      INSERT INTO t_promocoes SELECT * FROM sb_tables_original.t_promocoes;
      INSERT INTO t_vendas SELECT * FROM sb_tables_original.t_vendas;
      INSERT INTO t_linhasVenda SELECT * FROM sb_tables_original.t_linhasVenda;
      INSERT INTO t_linhasvenda_promocoes SELECT * FROM sb_tables_original.t_linhasvenda_promocoes;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;

BEGIN
   IF (p_confirm = '1') THEN
       -- desativa os triggers
       alterar_triggers ('DISABLE');
       -- faz a clonagem dos dados; se falhar, a operação é desfeita
       reset_dados_do_it;
       -- ativa os triggers
       alterar_triggers ('ENABLE');
   ELSE
      RAISE e_aborted_by_user;
   END IF;
EXCEPTION
   WHEN e_data_failure THEN
      -- ativa os triggers
      alterar_triggers ('ENABLE');
      RAISE_APPLICATION_ERROR (-20000,'A operação de reset aos dados correu mal e foi cancelada ['||sqlerrm||']');
   WHEN e_aborted_by_user THEN
      RAISE_APPLICATION_ERROR (-20999,'A operação foi cancelada por si. Para fazer reset aos dados, use 1 como parâmetro');
  WHEN OTHERS THEN
     -- tenta ativar os triggers
     alterar_triggers ('ENABLE');
     RAISE_APPLICATION_ERROR (-20000,'Ocorreu um erro não previsto durante a operação de reset dos dados ['||sqlerrm||']');
END;
/



GRANT EXECUTE ON reset_dados TO josevitor, malheiro, profrui;