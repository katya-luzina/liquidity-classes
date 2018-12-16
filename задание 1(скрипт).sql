#создание базы данных
CREATE DATABASE orders;
USE orders;

#создание таблицы для загрузки справочника типов ценных бумаг
CREATE TABLE security_type
(
	id INT NOT NULL auto_increment,
    instrument_type VARCHAR(40) NOT NULL DEFAULT ' ',
    seccode VARCHAR(40) NOT NULL DEFAULT ' ',
    PRIMARY KEY (id)
);

DESCRIBE security_type;

#скрипт для наполнения справочника типов ценных бумаг через файл, который был выгружен с сайта moex.com и обработан в Excel (удалены лишние столбцы, удалены типы инструментов, которые не нужны для данного задания)
LOAD DATA
	INFILE '/Users/ekaterina/Desktop/w/IT/SecurityList.txt'
    INTO TABLE security_type
	FIELDS TERMINATED by '\t'
    LINES TERMINATED by '\r\n';

#создание таблицы для первичной загрузки данных из orderlog
CREATE TABLE orders (
    id BIGINT NOT NULL,
    seccode VARCHAR(40) NOT NULL DEFAULT ' ',
    buysell CHAR(1) NOT NULL DEFAULT ' ',
    ordertime INT NOT NULL,
    orderno BIGINT NOT NULL,
    orderstatus INT NOT NULL,
    price FLOAT NOT NULL,
    volume INT NOT NULL,
    tradeno BIGINT,
    tradeprice FLOAT,
    PRIMARY KEY (id)
);

#загрузка orderlog в таблицу
LOAD DATA INFILE '/Users/ekaterina/Desktop/w/IT/OrderLog20150901/OrderLog20150901.txt' 
	INTO TABLE orders
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

 #создание таблицы для загрузки в нее данных из orderlog по заявкам по обыкновенным акциям
 CREATE TABLE orders_ordinary_shares
 (
	id BIGINT NOT NULL AUTO_INCREMENT,
	seccode VARCHAR(30),
	buysell CHAR(1),
	ordertime BIGINT,
	orderno BIGINT,
	action ENUM('0', '1', '2'),
	price FLOAT,
	volume BIGINT,
	tradeno BIGINT,
	tradeprice FLOAT,
	PRIMARY KEY (id)
);

#заполнение таблицы заявок по обыкновенным акциям на основе orderlog и справочника типов инструментов
INSERT INTO orders_ordinary_shares
SELECT a1.*
FROM orders a1
	JOIN security_type a2
	ON a1.seccode = a2.seccode
WHERE a2. instrument_type = 'ordinary share';

#добавление индексов в таблицу заявок по обыкновенным акциям
CREATE INDEX ioseccode ON orders_ordinary_shares(seccode);
CREATE INDEX ioordertime ON orders_ordinary_shares(ordertime);
CREATE INDEX ioaction ON orders_ordinary_shares(action);
CREATE INDEX ioprice ON orders_ordinary_shares(price);
CREATE INDEX iovolume ON orders_ordinary_shares(volume);

SELECT * FROM orders_ordinary_shares
LIMIT 10;

#создание таблицы для загрузки в нее данных из orderlog по заявкам по привилегированным акциям
CREATE TABLE orders_preference_shares
 (
	id BIGINT NOT NULL AUTO_INCREMENT,
	seccode VARCHAR(30),
	buysell CHAR(1),
	ordertime BIGINT,
	orderno BIGINT,
	action ENUM('0', '1', '2'),
	price FLOAT,
	volume BIGINT,
	tradeno BIGINT,
	tradeprice FLOAT,
	PRIMARY KEY (id)
);

#заполнение таблицы заявок по привилегированным облигациям на основе orderlog и справочника типов инструментов
INSERT INTO orders_preference_shares
SELECT a1.*
FROM orders a1
	JOIN security_type a2
	ON a1.seccode = a2.seccode
WHERE a2. instrument_type = 'preferred share';

#добавление индексов в таблицу заявок по привилегированным акциям
CREATE INDEX ipseccode ON orders_preferred_shares(seccode);
CREATE INDEX ipordertime ON orders_preferred_shares(ordertime);
CREATE INDEX ipaction ON orders_preferred_shares(action);
CREATE INDEX ipprice ON orders_preferred_shares(price);
CREATE INDEX ipvolume ON orders_preferred_shares(volume);

SELECT * FROM orders_preference_shares LIMIT 10;

#создание таблицы для загрузки данных из orderlog по заявкам по облигациям
CREATE TABLE orders_bonds
 (
	id BIGINT NOT NULL AUTO_INCREMENT,
	seccode VARCHAR(30),
	buysell CHAR(1),
	ordertime BIGINT,
	orderno BIGINT,
	action ENUM('0', '1', '2'),
	price FLOAT,
	volume BIGINT,
	tradeno BIGINT,
	tradeprice FLOAT,
	PRIMARY KEY (id)
);

#заполнение таблицы заявок по корпоративным облигациям на основе orderlog и справочника типов инструментов
INSERT INTO orders_bonds
SELECT a1.*
FROM orders a1
	JOIN security_type a2
	ON a1.seccode = a2.seccode
WHERE a2. instrument_type = 'bond';

#добавление индексов в таблицу заявок по облигациям
CREATE INDEX ipseccode ON orders_preferred_shares(seccode);
CREATE INDEX ipordertime ON orders_preferred_shares(ordertime);
CREATE INDEX ipaction ON orders_preferred_shares(action);
CREATE INDEX ipprice ON orders_preferred_shares(price);
CREATE INDEX ipvolume ON orders_preferred_shares(volume);

SELECT * FROM orders_bonds LIMIT 10;

#проверка на наличие в orderlog инструментов, которые не указаны в справочнике. В случае отсутствия данных по типу одного из инструментов, в правом столбце таблицы будет выведено NULL
SELECT a1.seccode, a2.instrument_type
	FROM orders a1
    LEFT OUTER JOIN security_type a2
    ON a1.seccode=a2.seccode
    ORDER BY a1.seccode;
    
#поиск инструмента, по которому было совершено наибольшее количество сделок
SELECT seccode, orderno, COUNT(*) 
	FROM orders_ordinary_shares
    WHERE tradeno IS NOT NULL 
    GROUP BY seccode, orderno
    ORDER BY COUNT(*) DESC
    LIMIT 1;
