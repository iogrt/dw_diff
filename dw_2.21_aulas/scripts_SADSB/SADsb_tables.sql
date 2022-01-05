CREATE TABLE t_produtos(
   Cod_Produto    INTEGER,
   Nome           VARCHAR2(30),
   Quant_Stock    INTEGER,
   Preco_unit     NUMBER(6,2),
   Largura        INTEGER,
   Altura         INTEGER,
   Profundidade   INTEGER,
   Composicao	  VARCHAR2(50),
   Tipo_embalagem VARCHAR2(30),
   calorias_100g  INTEGER,
   peso           NUMBER(8,2),
   peso_liq       NUMBER(8,2),
   custo          NUMBER(8,2),
   marca          VARCHAR2(30),
   cod_barras	  CHAR(12),
   cod_categoria  CHAR(5),
   CONSTRAINT pk_produtos PRIMARY KEY (cod_produto)
);


CREATE TABLE t_clientes(
   cod_cliente    	INTEGER,
   numero_Cartao	VARCHAR2(20),
   nome				VARCHAR2(40),
   morada			VARCHAR2(60),
   localidade		VARCHAR2(60),
   concelho			VARCHAR2(40),
   distrito			VARCHAR2(40),
   regiao			VARCHAR2(60),
   codigo_Postal	VARCHAR2(8),
   telefone			NUMBER(9),
   sexo				CHAR(1),
   idade			NUMBER(3),	
   estado_civil		CHAR(1),
   CONSTRAINT pk_clientes PRIMARY KEY (cod_cliente)
);


CREATE TABLE t_promocoes(
   cod_Promo  INTEGER,
   nome       VARCHAR2(30),
   descr      VARCHAR2(100),
   data_inic  DATE,
   data_fim   DATE,
   cttp1      NUMBER(1),
   cttp2	  NUMBER(1),
   reducao    NUMBER(3,2),
   cartaz     NUMBER(1),
   anuncio    NUMBER(1),
   CONSTRAINT pk_promocoes PRIMARY KEY (cod_promo)
);



CREATE TABLE t_vendas(
   cod_venda  INTEGER,
   data       DATE,
   num_caixa  INTEGER,
   num_Func   INTEGER,
   cod_loja   CHAR(6),
   cod_cliente INTEGER,
   CONSTRAINT pk_vendas PRIMARY KEY (cod_venda),
   CONSTRAINT fk_vendas_codCliente FOREIGN KEY (cod_cliente) REFERENCES t_clientes(cod_cliente)
);



CREATE TABLE t_linhasVenda(
   cod_linha    INTEGER,
   cod_venda    INTEGER,
   cod_produto  INTEGER,
   data         DATE,
   quantidade   NUMBER(8,2),
   preco_venda  NUMBER(11,2),
   preco_total  NUMBER(11,2),
   obs	    VARCHAR2(200),
   CONSTRAINT pk_linhasVenda PRIMARY KEY (cod_linha),
   CONSTRAINT fk_linhasVenda_venda FOREIGN KEY (cod_venda) REFERENCES t_vendas(cod_Venda),
   CONSTRAINT fk_linhasVenda_produto FOREIGN KEY (cod_produto) REFERENCES t_produtos(cod_produto)
);


CREATE TABLE t_linhasVenda_promocoes(
   cod_linha    INTEGER,
   cod_promo    INTEGER,
   CONSTRAINT pk_linhasPromocoes PRIMARY KEY (cod_linha),
   CONSTRAINT fk_linhasPromocoes_linhaVenda FOREIGN KEY (cod_linha) REFERENCES t_linhasVenda(cod_linha),
   CONSTRAINT fk_linhasPromocoes_promo FOREIGN KEY (cod_promo) REFERENCES t_promocoes(cod_promo)
);


CREATE TABLE t_categ(
	cod_categoria	CHAR(5),
	nome			VARCHAR2(30),
	obs			VARCHAR2(250),
	data_criacao	DATE
);





ALTER TABLE t_linhasVenda_promocoes ADD (last_changed TIMESTAMP);
ALTER TABLE t_linhasVenda ADD (last_changed TIMESTAMP);
ALTER TABLE t_vendas ADD (last_changed TIMESTAMP);
ALTER TABLE t_promocoes ADD (last_changed TIMESTAMP);
ALTER TABLE t_produtos ADD (last_changed TIMESTAMP);
ALTER TABLE t_categ ADD (last_changed TIMESTAMP);
ALTER TABLE t_clientes ADD (last_changed TIMESTAMP);
