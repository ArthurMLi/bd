use classicmodels;
create table carrinho(
CODIGOCLIENTE INT NOT NULL,
CODIGOPRODUTO VARCHAR(10),
QUANTIDADE INT,
PRECO DECIMAL(10,2),
PRIMARY KEY (CODIGOCLIENTE, CODIGOPRODUTO) ) ENGINE=INNODB;

DELIMITER $
create procedure GERAR_ITEM_PEDIDO (IN PARAM_CODIGOPRODUTO INT, IN PARAM_QUANTIDADE INT, IN PARAM_PRECO INT, IN PARAM_NUMEROPEDIDO INT, IN PARAM_ORDERLINEBNUMBER INT, OUT ERRO VARCHAR(100))
INICIO: BEGIN 
declare produto_existente int default 1;
    SELECT ifnull(PRODUCTCODE, 0) INTO produto_existente FROM PRODUCTS WHERE PRODUCTCODE = PARAM_CODIGOPRODUTO;
	IF produto_existente = 0 THEN
	SET ERRO = "Produto invalido";
        leave INICIO;
    END IF;
    IF (SELECT QUANTITYINSTOCK FROM PRODUCTS WHERE PRODUCTCODE = PARAM_CODIGOPRODUTO) < PARAM_QUANTIDADE THEN
		SET ERRO = concat("Quantidade do produto",  PARAM_CODIGOPRODUTO , "invalida");
		leave INICIO;
    END if;
    
	INSERT INTO ORDERDETAILS 
		VALUES (PARAM_NUMEROPEDIDO, PARAM_CODIGOPRODUTO, PARAM_QUANTIDADE, PARAM_PRECO, PARAM_ORDERLINEBNUMBER);
	SET ERRO = "";
	
    update products set quantityinstock = (quantityinstock - param_quantidade) where productCode = param_codigoproduto;
END$

CREATE PROCEDURE GERAR_PEDIDO (IN PARAM_CLIENTE INT, IN PARAM_VENDEDOR INT, OUT RESULTADO VARCHAR(200))
INICIO: BEGIN
	#Variaveis para conferencia
    DECLARE VAR_EXISTECLIENTE INT DEFAULT 0;
	DECLARE VAR_EXISTEVENDEDOR INT DEFAULT 0;
	DECLARE VAR_COMPROUPRODUTO INT DEFAULT 0;
    #Variaveis do carrinho
    DECLARE VAR_NUMEROPEDIDO INT DEFAULT 0;
    DECLARE VAR_CODIGOPRODUTO INT DEFAULT 0;
    DECLARE VAR_QUANTIDADE INT DEFAULT 0;
    DECLARE VAR_PRECO INT DEFAULT 0;
    
    #Variaveis para o while
	DECLARE cont INT DEFAULT 0;
	declare contador_while int default 0;

	
    SELECT MAX(ORDERNUMBER) + 1 INTO VAR_NUMEROPEDIDO FROM ORDERS;
    
  # Verifica a existencia do cliente
	SELECT IFNULL(CUSTOMERNUMBER,0) INTO VAR_EXISTECLIENTE
	FROM CUSTOMERS
	WHERE CUSTOMERNUMBER = PARAM_CLIENTE;

	IF VAR_EXISTECLIENTE = 0 THEN
		SET RESULTADO = "CLIENTE NÃO ENCONTRADO NA BASE DE DADOS";
		LEAVE INICIO;
	END IF;
    
  # Verifica a existencia do vendedor
  SELECT IFNULL(employeeNUMBER,0) INTO VAR_EXISTEvendedor
	FROM employees
	WHERE employeeNUMBER = PARAM_vendedor;
    IF VAR_EXISTEVENDEDOR = 0 THEN
		SET RESULTADO = "VENDEDOR NÃO ENCONTRADO NA BASE DE DADOS";
		LEAVE INICIO;
	END IF;
    
  # Verifica se o carrinho ja foi comprado
    
	SELECT IFNULL(COUNT(*), 0) INTO VAR_COMPROUPRODUTO
	FROM CARRINHO
	WHERE CODIGOCLIENTE = PARAM_CLIENTE;

	IF VAR_COMPROUPRODUTO = 0 THEN
		SET RESULTADO = 'O CARRINHO ESTÁ VAZIO';
		LEAVE INICIO;
	END IF;
	
  # Verifica o limite de credito do cliente
    IF (select creditLimit from customers where	customerNumber = param_cliente) < 0 then
		SET RESULTADO = 'O CLIENTE NÃO POSSUI LIMITE DE CREDITO';
		LEAVE INICIO;
    END IF;
   
# Conclui a ordem de pedido
     START TRANSACTION;
    INSERT INTO ORDERS (orderNumber, orderdate, requiredDate, shippeddate, status, comments, customernumber)
		VALUES (VAR_NUMEROPEDIDO, CURDATE(), CURDATE() + 7, '', 'processing','', 'param_cliente');
        
# Adiciona os itens
	
    select sum(quantidade) into cont from carrinho where codigocliente = param_cliente;
    
    WHILE contador_while <= cont do
    set @erro = "";
    SELECT CODIGOPRODUTO INTO VAR_CODIGOPRODUTO FROM CARRINHO WHERE CODIGOCLIENTE = PARAM_CLIENTE LIMIT 1 offset CONTADOR_WHILE;
	SELECT QUANTIDADE INTO VAR_QUANTIDADE FROM CARRINHO WHERE CODIGOCLIENTE = PARAM_CLIENTE LIMIT 1 offset CONTADOR_WHILE;
    SELECT PRECO INTO VAR_PRECO FROM CARRINHO WHERE CODIGOCLIENTE = PARAM_CLIENTE LIMIT 1 offset CONTADOR_WHILE;
    
    CALL GERAR_ITEM_PEDIDO (VAR_CODIGOPRODUTO, VAR_QUANTIDADE , VAR_PRECO, VAR_NUMEROPEDIDO, CONTADOR_WHILE + 1, @erro);
		if (@erro != "") then
            rollback;
			set resultado = @erro;
            leave inicio;
		end if;
	set contador_while = contador_while + 1;
    END WHILE;
    update customers set salesRepEmployeeNumber = PARAM_VENDEDOR where customernumber = PARAM_cliente;
    set resultado  =  concat("pedido gerado: ",VAR_NUMEROPEDIDO);
    delete from carrinho where CODIGOCLIENTE = param_cliente;
    COMMIT;
    ROLLBACK;
    
END$
DELIMITER ;
insert into carrinho values(103,"aASDASDAS",10,10);
call GERAR_PEDIDO(103,1002,@resultado);
insert into resultado values(@resultado);
create table resultado(
id varchar(100)
);
select * from resultado;
select * from carrinho;


