--whenever sqlerror exit sql.sqlcode;
accept password_sys char prompt 'Enter SYS password: '
accept password_sb_tables char prompt 'Enter SB_TABLES and SB_READONLY password: '
accept password_sb_tables_original char prompt 'Enter SB_TABLES_ORIGINAL password: '

CONN sys@orcl_dei/&password_sys as sysdba

-- Database link
DROP PUBLIC DATABASE LINK dblink_sadsb;
CREATE PUBLIC DATABASE LINK dblink_sadsb
CONNECT TO sb_readonly IDENTIFIED BY &password_sb_tables 
USING 'bdados';

-- drop users
DROP USER sb_readonly CASCADE;
DROP USER sb_tables CASCADE;
DROP USER sb_tables_original CASCADE;

-- create users
CREATE USER sb_readonly IDENTIFIED BY &password_sb_tables QUOTA 1024K ON users;
CREATE USER sb_tables IDENTIFIED BY &password_sb_tables QUOTA 1024K ON users;

-- conta com os dados originais, necessária para repor após alterações aos dados feitas durante as aulas. Evita o uso de scripts para fazer esta reposição, podendo cada professor pedir a reposição através da sua conta pessoal
CREATE USER sb_tables_original IDENTIFIED BY &password_sb_tables_original QUOTA 1024K ON users;

-- grant privileges
GRANT CONNECT, CREATE VIEW TO sb_readonly;
GRANT CONNECT, CREATE TABLE, CREATE TRIGGER, CREATE PROCEDURE TO sb_tables;
GRANT CONNECT, CREATE TABLE, CREATE TRIGGER TO sb_tables_original;

-- instalar os objetos das fontes de dados
CONN sb_tables_original@orcl_dei/&password_sb_tables_original
@@sadsb_drops.sql
@@sadsb_tables.sql
@@sadsb_data.sql
@@sadsb_triggers.sql


-- permitir que a conta SB_TABLES possa ver as tabelas da SB_TABLES_ORIGINAL, para o processo de clonagem
GRANT SELECT ON t_linhasVenda_promocoes TO sb_tables;
GRANT SELECT ON t_linhasVenda TO sb_tables;
GRANT SELECT ON t_vendas TO sb_tables;
GRANT SELECT ON t_promocoes TO sb_tables;
GRANT SELECT ON t_produtos TO sb_tables;
GRANT SELECT ON t_categ TO sb_tables;
GRANT SELECT ON t_clientes TO sb_tables;

CONN sb_tables@orcl_dei/&password_sb_tables
@@sadsb_drops.sql
@@sadsb_tables.sql
@@sadsb_triggers.sql
@@sadsb_procedures.sql
@@sadsb_grants.sql
exec reset_dados('1');


-- criar as vistas que darão acesso aos dados fonte da sb_tables
conn sb_readonly@orcl_dei/&password_sb_tables;
@@sadsb_views.sql

