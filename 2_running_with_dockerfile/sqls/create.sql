CREATE DATABASE pracoholicy CHARACTER SET utf8 COLLATE utf8_general_ci;

USE pracoholicy;

CREATE TABLE pracholicy.pracoholicy (
alkoholikID int AUTO_INCREMENT PRIMARY KEY,
first_name varchar(25),
last_name  varchar(25),
department varchar(15),
email  varchar(50)
);