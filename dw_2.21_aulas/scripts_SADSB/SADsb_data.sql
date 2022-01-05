
INSERT INTO t_clientes VALUES (1,'1234567891234','José Teixeira','Rua Direita 43 4D','Coimbra','Coimbra','Coimbra','Centro','3000-146',239123456,'M',34,'C',NULL);
INSERT INTO t_clientes VALUES (2,'1234567892345','Maria Violeta','Rua de Cima Lote 8','Castelo Viegas','Coimbra','Coimbra','Centro','3040-750',239123123,'F',23,'S',NULL);
INSERT INTO t_clientes VALUES (3,'1234567893456','Antónia Teles','Rua da Ladeira 128 2C','Leiria','Leiria','Leiria','Centro','2400-075',239654321,'F',28,'S',NULL);
INSERT INTO t_clientes VALUES (4,'1234567894567','João Vasconcelos','Travessa de Santana 58 1E','Cantanhede','Cantanhede','Coimbra','Centro','3000-146',239123456,'M',32,'D',NULL);
INSERT INTO t_clientes VALUES (5,'1234567895678','Joana Crava','Rua da Liberdade 4','Cartaxo','Cartaxo','Santarém','Lisboa e Vale do Tejo','2070-040',243123321,'F',52,'C',NULL);

-- v2.21.0
--ano de 2020 por 2021
INSERT INTO t_promocoes VALUES (1, 'Leve 2 pague 1','Leva dois produtos e paga apenas 1', TO_DATE('2020-10-01','yyyy-mm-dd'),TO_DATE('2020-10-31','yyyy-mm-dd'),4,6,0.5, 1, 0,NULL);
INSERT INTO t_promocoes VALUES (2, '5+5','5% de desconto nas compras+5% em talão de combustível',TO_DATE('2020-11-01','yyyy-mm-dd'),TO_DATE('2021-5-31','yyyy-mm-dd'),6,2,0.2, 1, 1,NULL);

INSERT INTO t_produtos VALUES (1,'Bacalhau Graúdo',450, 5.8, NULL, NULL, NULL, 'Organico', 'caixa', 120, NULL, NULL, 4.2, 'Riberalves', 560400487669,'PEIXE',NULL);
INSERT INTO t_produtos VALUES (2,'Maçã',247,0.67, NULL, NULL, NULL, 'Orgânico', NULL, 20, NULL, NULL, 0.39, 'Cãpina', 560411098997,'FRUTA',NULL);
INSERT INTO t_produtos VALUES (3,'Pêra',291,0.68, NULL, NULL, NULL, 'Organic', 'Saco', 30, 2, 2, 0.40, 'Canpina', 560476988544,'FRUTA',NULL);
INSERT INTO t_produtos VALUES (4,'Pescada em postas',220,7.80, 0.3, 0.15, 0.10, 'Orgânico', 'Saco', 80, 0.8, 0.8, 5.49,'Pescanova', 560410328374,'PEIXE',NULL);
INSERT INTO t_produtos VALUES (5,'Maçã',247,0.67, NULL, NULL, NULL, 'Orgânico', 'Saco', 20, 2, NULL, 0.39, 'Campina', 560411085445,'FRUTA',NULL);

-- v2.21.0
--10/10/2019, 5ª feira, por 08/10/2020, 5ª feira
--21/10/2019, 2ª feira, por 19/10/2020, 2ª feira
--02/11/2019, sábado, por 31/10/2020, sábado
INSERT INTO t_vendas VALUES (1, TO_DATE('2020-10-08','yyyy-mm-dd'), 43, 43544, 'SB-CBR',1,NULL);
INSERT INTO t_vendas VALUES (2, TO_DATE('2020-10-08','yyyy-mm-dd'), 1, 43120, 'SB-CBR',4,NULL);
INSERT INTO t_vendas VALUES (3, TO_DATE('2020-10-19','yyyy-mm-dd'), 41, 43544, 'SB-CBR',1,NULL);
INSERT INTO t_vendas VALUES (4, TO_DATE('2020-10-31','yyyy-mm-dd'), 31, 223, 'SB-LEI',3,NULL);

-- v2.21.0
--10/10/2019, 5ª feira, por 08/10/2020, 5ª feira
--21/10/2019, 2ª feira, por 19/10/2020, 2ª feira
--02/11/2019, sábado, por 31/10/2020, sábado
-- 1ª venda
INSERT INTO t_linhasvenda VALUES (1001, 1, 3, TO_DATE('2020-10-08 13:12:03','yyyy-mm-dd hh24:mi:ss'), 2.56, 0.64, 1.64,NULL,NULL);
INSERT INTO t_linhasvenda VALUES (1002, 1, 2, TO_DATE('2020-10-08 13:12:34','yyyy-mm-dd hh24:mi:ss'), 1.80, 0.63, 1.13,NULL,NULL);
-- 2ª venda
INSERT INTO t_linhasvenda VALUES (2001, 2, 1, TO_DATE('2020-10-08 13:12:08','yyyy-mm-dd hh24:mi:ss'), 4.203, 5.5, 23.12,NULL,NULL);
INSERT INTO t_linhasvenda VALUES (2002, 2, 4, TO_DATE('2020-10-08 13:12:18','yyyy-mm-dd hh24:mi:ss'), 2, 7.8, 7.8,NULL,NULL);
INSERT INTO t_linhasVenda_promocoes VALUES (2002, 1,NULL);
-- 3ª venda
INSERT INTO t_linhasvenda VALUES (3001, 3, 4, TO_DATE('2020-10-19 11:09:18','yyyy-mm-dd hh24:mi:ss'),4, 7.8, 15.6,NULL,NULL);
INSERT INTO t_linhasVenda_promocoes VALUES (3001, 1,NULL);
-- 4ª venda
INSERT INTO t_linhasvenda VALUES (4001, 4, 4, TO_DATE('2020-10-31 14:15:01','yyyy-mm-dd hh24:mi:ss'),3, 7.2, 20.52,NULL,NULL);
INSERT INTO t_linhasVenda_promocoes VALUES (4001, 2,NULL);


INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao) VALUES ('FRESC','FRESCOS',NULL,SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('CONGE','CONGELADOS',NULL,SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('PEIXE','PEIXARIA','Peixe e mariscos frescos/cozidos frescos',SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('CHARC','CHARCUTARIA','Queijos e enchidos',SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('BAZAR','BAZAR',NULL,SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('AUTOM','AUTOMÓVEL',NULL,SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('DESPO','DESPORTO',NULL,SYSDATE);
INSERT INTO t_categ (cod_categoria,nome,obs,data_criacao)  VALUES ('FRUTA','FRUTAS E LEGUMES',NULL,SYSDATE);

COMMIT;


