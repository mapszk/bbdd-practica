SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS `ropa_siempre_limpia`;

CREATE DATABASE `ropa_siempre_limpia`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';

USE `ropa_siempre_limpia`;

#
# Structure for the `clientes` table : 
#

DROP TABLE IF EXISTS `clientes`;

CREATE TABLE `clientes` (
  `tipo_doc` varchar(4) NOT NULL,
  `nro_doc` int(11) NOT NULL,
  `nom_ape` varchar(50) NOT NULL,
  `tel` varchar(20) default NULL,
  `dir` varchar(50) default NULL,
  `ciudad` varchar(30) default NULL,
  PRIMARY KEY  (`tipo_doc`,`nro_doc`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `empleados` table : 
#

DROP TABLE IF EXISTS `empleados`;

CREATE TABLE `empleados` (
  `cuil` varchar(20) NOT NULL,
  `nom_ape` varchar(50) NOT NULL,
  PRIMARY KEY  (`cuil`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `maquinas` table : 
#

DROP TABLE IF EXISTS `maquinas`;

CREATE TABLE `maquinas` (
  `nro_maquina` int(11) NOT NULL,
  `desc_maquina` varchar(20) NOT NULL,
  PRIMARY KEY  (`nro_maquina`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `procesos` table : 
#

DROP TABLE IF EXISTS `procesos`;

CREATE TABLE `procesos` (
  `cod_proceso` int(11) NOT NULL,
  `desc_proceso` varchar(50) NOT NULL,
  `precauciones` varchar(100) default NULL,
  PRIMARY KEY  (`cod_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `tratamientos` table : 
#

DROP TABLE IF EXISTS `tratamientos`;

CREATE TABLE `tratamientos` (
  `cod_tratamiento` int(11) NOT NULL,
  `desc_tratamiento` varchar(50) NOT NULL,
  `nro_maquina_utiliza` int(11) default NULL,
  PRIMARY KEY  (`cod_tratamiento`),
  KEY `nro_maquina_utiliza` (`nro_maquina_utiliza`),
  CONSTRAINT `tratamientos_fk` FOREIGN KEY (`nro_maquina_utiliza`) REFERENCES `maquinas` (`nro_maquina`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `tratamiento_limpieza` table : 
#

DROP TABLE IF EXISTS `tratamiento_limpieza`;

CREATE TABLE `tratamiento_limpieza` (
  `nro_servicio` int(11) NOT NULL,
  `cod_tratamiento` int(11) NOT NULL,
  `orden` int(11) NOT NULL,
  `obs_tratamiento_limpieza` varchar(100) default NULL,
  PRIMARY KEY  (`nro_servicio`,`orden`),
  KEY `tratamiento_limpieza_fk1` (`cod_tratamiento`),
  CONSTRAINT `tratamiento_limpieza_fk` FOREIGN KEY (`cod_tratamiento`) REFERENCES `tratamientos` (`cod_tratamiento`) ON UPDATE CASCADE,
  CONSTRAINT `tratamiento_limpieza_fk1` FOREIGN KEY (`cod_tratamiento`) REFERENCES `tratamientos` (`cod_tratamiento`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `procesos_realizados` table : 
#

DROP TABLE IF EXISTS `procesos_realizados`;

CREATE TABLE `procesos_realizados` (
  `nro_servicio` int(11) NOT NULL,
  `orden` int(11) NOT NULL,
  `cod_proceso` int(11) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `hora_inicio` time NOT NULL,
  `cuil_empleado` varchar(20) NOT NULL,
  `fecha_fin` date default NULL,
  `hora_fin` time default NULL,
  `resultado_proceso` varchar(20) default NULL,
  PRIMARY KEY  (`nro_servicio`,`orden`,`fecha_inicio`,`hora_inicio`),
  KEY `procesos_realizados_fk1` (`cod_proceso`),
  KEY `procesos_realizados_fk2` (`cuil_empleado`),
  CONSTRAINT `procesos_realizados_fk` FOREIGN KEY (`nro_servicio`, `orden`) REFERENCES `tratamiento_limpieza` (`nro_servicio`, `orden`) ON UPDATE CASCADE,
  CONSTRAINT `procesos_realizados_fk1` FOREIGN KEY (`cod_proceso`) REFERENCES `procesos` (`cod_proceso`) ON UPDATE CASCADE,
  CONSTRAINT `procesos_realizados_fk2` FOREIGN KEY (`cuil_empleado`) REFERENCES `empleados` (`cuil`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `servicios_limpieza` table : 
#

DROP TABLE IF EXISTS `servicios_limpieza`;

CREATE TABLE `servicios_limpieza` (
  `nro_servicio` int(11) NOT NULL,
  `fecha_entrega` date NOT NULL,
  `fecha_dev_est` date NOT NULL,
  `fecha_dev_real` date default NULL,
  `prenda` varchar(50) NOT NULL,
  `estado_entrega` varchar(20) default NULL,
  `obs_cli` varchar(100) default NULL,
  `obs_internas` varchar(100) default NULL,
  `estado_dev` varchar(20) default NULL,
  `tipo_doc` varchar(4) NOT NULL,
  `nro_doc` int(11) NOT NULL,
  PRIMARY KEY  (`nro_servicio`),
  KEY `servicios_limpieza_fk` (`tipo_doc`,`nro_doc`),
  CONSTRAINT `servicios_limpieza_fk` FOREIGN KEY (`tipo_doc`, `nro_doc`) REFERENCES `clientes` (`tipo_doc`, `nro_doc`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `tratamientos_procesos` table : 
#

DROP TABLE IF EXISTS `tratamientos_procesos`;

CREATE TABLE `tratamientos_procesos` (
  `cod_tratamiento` int(11) NOT NULL,
  `cod_proceso` int(11) NOT NULL,
  `orden` int(11) NOT NULL,
  PRIMARY KEY  (`cod_tratamiento`,`cod_proceso`,`orden`),
  KEY `tratamientos_procesos_procesos_fk` (`cod_proceso`),
  CONSTRAINT `tratamientos_procesos_procesos_fk` FOREIGN KEY (`cod_proceso`) REFERENCES `procesos` (`cod_proceso`) ON UPDATE CASCADE,
  CONSTRAINT `tratamientos_procesos_tratamientos_fk` FOREIGN KEY (`cod_tratamiento`) REFERENCES `tratamientos` (`cod_tratamiento`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `valores_tratamientos` table : 
#

DROP TABLE IF EXISTS `valores_tratamientos`;

CREATE TABLE `valores_tratamientos` (
  `cod_tratamiento` int(11) NOT NULL,
  `fecha_desde` date NOT NULL,
  `valor` decimal(9,3) default NULL,
  PRIMARY KEY  (`cod_tratamiento`,`fecha_desde`),
  CONSTRAINT `valores_tratamientos_fk` FOREIGN KEY (`cod_tratamiento`) REFERENCES `tratamientos` (`cod_tratamiento`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Data for the `clientes` table  (LIMIT 0,500)
#

INSERT INTO `clientes` (`tipo_doc`, `nro_doc`, `nom_ape`, `tel`, `dir`, `ciudad`) VALUES 
  ('dni',11111111,'James Dewar','1111111','Lavalle 1111','Rosario'),
  ('dni',22222222,'Mary Quant','2222222','Córdoba 2222','Rosario'),
  ('dni',33333333,'King Camp Gillette','3333333','Lima 333','Perez'),
  ('dni',44444444,'Alexis Duchateau','4444444','Pasco 4444','Perez'),
  ('dni',55555555,'John Logie Baird','5555555','Paso de patos  55','Rosario');

COMMIT;

#
# Data for the `empleados` table  (LIMIT 0,500)
#

INSERT INTO `empleados` (`cuil`, `nom_ape`) VALUES 
  ('10-10101010-1','Rene Favaloro'),
  ('66-66666666-6','Jean-Baptiste Denis'),
  ('77-77777777-7','Edward Jenner'),
  ('88-88888888-8','Sir Alexander Fleming'),
  ('99-99999999-9','Felix Hoffman');

COMMIT;

#
# Data for the `maquinas` table  (LIMIT 0,500)
#

INSERT INTO `maquinas` (`nro_maquina`, `desc_maquina`) VALUES 
  (1,'Plancha Automática'),
  (2,'Maquina de Teñir'),
  (3,'Lavadora-Secadora'),
  (4,'Lavadora en Seco');

COMMIT;

#
# Data for the `procesos` table  (LIMIT 0,500)
#

INSERT INTO `procesos` (`cod_proceso`, `desc_proceso`, `precauciones`) VALUES 
  (1,'Lavado','No mezclar ropa blanca con ropa de color'),
  (2,'Teñido','Usar mascara para gases y guantes'),
  (3,'Limpieza','Usar mascara para gases y guantes'),
  (4,'Secado',NULL),
  (5,'Quitar pelusa',NULL),
  (6,'Realzar color','Usar mascara para gases y guantes'),
  (7,'Aplicar quitamanchas','Usar guantes'),
  (8,'Quitar quitamanchas','Usar guantes'),
  (9,'Planchar','Regular temperatura para el tipo de tela y revisar carga de agua'),
  (10,'Decoloracion','Usar mascara para gases y guantes'),
  (11,'Limpieza térmica','No en nylon, algodon 100% ni lanas');

COMMIT;

#
# Data for the `tratamientos` table  (LIMIT 0,500)
#

INSERT INTO `tratamientos` (`cod_tratamiento`, `desc_tratamiento`, `nro_maquina_utiliza`) VALUES 
  (1,'Tintura a color mas oscuro',2),
  (2,'Tintura a color mas claro',2),
  (3,'Lavado en seco',4),
  (4,'Lavado comun',3),
  (5,'Planchado',1),
  (6,'Remocion de manchas',NULL),
  (7,'Restauracion lana',NULL);

COMMIT;

#
# Data for the `tratamiento_limpieza` table  (LIMIT 0,500)
#

INSERT INTO `tratamiento_limpieza` (`nro_servicio`, `cod_tratamiento`, `orden`, `obs_tratamiento_limpieza`) VALUES 
  (1,1,1,'teñir de negro'),
  (1,5,2,NULL),
  (2,6,1,NULL),
  (2,4,2,NULL),
  (2,5,3,NULL),
  (3,3,1,NULL),
  (3,5,2,NULL),
  (4,5,1,NULL),
  (5,2,1,'teñir de fucsia'),
  (5,5,2,NULL),
  (6,6,1,NULL),
  (6,5,2,NULL),
  (7,4,1,NULL),
  (7,7,2,NULL),
  (8,7,1,NULL),
  (9,2,1,'teñir de verde lima'),
  (9,5,2,NULL),
  (10,6,1,'manchas de grasa'),
  (10,3,2,NULL),
  (10,6,3,'manchas de grasa'),
  (10,7,4,NULL),
  (10,5,5,NULL),
  (11,2,1,'teñir de azul francia'),
  (12,6,1,NULL),
  (12,4,2,NULL),
  (12,3,3,NULL),
  (13,6,1,NULL),
  (13,4,2,NULL),
  (14,6,1,'mancha de humedad'),
  (15,4,1,NULL),
  (15,7,2,NULL),
  (15,4,3,NULL),
  (15,5,4,NULL);

COMMIT;

#
# Data for the `procesos_realizados` table  (LIMIT 0,500)
#

INSERT INTO `procesos_realizados` (`nro_servicio`, `orden`, `cod_proceso`, `fecha_inicio`, `hora_inicio`, `cuil_empleado`, `fecha_fin`, `hora_fin`, `resultado_proceso`) VALUES 
  (1,1,1,'2008-08-05','09:00:01','66-66666666-6','2008-08-05','09:18:01','Satisfactorio'),
  (1,1,2,'2008-08-05','09:36:02','66-66666666-6','2008-08-05','09:54:02','Satisfactorio'),
  (1,1,3,'2008-08-06','10:08:03','66-66666666-6','2008-08-06','10:26:03','Satisfactorio'),
  (1,2,9,'2008-08-06','10:08:09','66-66666666-6','2008-08-06','10:26:09','Satisfactorio'),
  (2,1,7,'2008-08-10','09:00:07','77-77777777-7','2008-08-10','09:18:07','Satisfactorio'),
  (2,1,8,'2008-08-10','09:36:08','66-66666666-6','2008-08-10','09:54:08','Satisfactorio'),
  (2,2,1,'2008-08-11','10:08:01','77-77777777-7','2008-08-11','10:26:01','Satisfactorio'),
  (2,2,4,'2008-08-11','10:44:04','77-77777777-7','2008-08-11','11:02:04','Satisfactorio'),
  (2,3,9,'2008-08-12','11:16:09','66-66666666-6','2008-08-12','11:34:09','Satisfactorio'),
  (3,1,11,'2008-08-18','09:00:11','66-66666666-6','2008-08-18','09:18:11','Satisfactorio'),
  (3,2,9,'2008-08-19','10:08:09','77-77777777-7','2008-08-19','10:26:09','Satisfactorio'),
  (4,1,9,'2008-08-20','09:00:09','77-77777777-7','2008-08-20','09:18:09','Satisfactorio'),
  (5,1,1,'2008-08-20','09:00:01','88-88888888-8','2008-08-20','09:18:01','Satisfactorio'),
  (5,1,10,'2008-08-20','09:36:10','77-77777777-7','2008-08-20','09:54:10','Satisfactorio'),
  (5,1,2,'2008-08-21','10:08:02','88-88888888-8','2008-08-21','10:26:02','Satisfactorio'),
  (5,1,3,'2008-08-21','10:44:03','88-88888888-8','2008-08-21','11:02:03','Satisfactorio'),
  (5,2,9,'2008-08-21','10:08:09','77-77777777-7','2008-08-21','10:26:09','Satisfactorio'),
  (6,1,7,'2008-08-25','09:00:07','99-99999999-9','2008-08-25','09:18:07','Satisfactorio'),
  (6,1,8,'2008-08-25','09:36:08','99-99999999-9','2008-08-25','09:54:08','Satisfactorio'),
  (6,2,9,'2008-08-26','10:08:09','99-99999999-9','2008-08-26','10:26:09','Insatisfactorio'),
  (6,2,9,'2008-08-26','10:55:00','77-77777777-7','2008-08-26','11:25:00','Satisfactorio'),
  (7,1,1,'2008-08-29','09:00:01','66-66666666-6','2008-08-29','09:18:01','Satisfactorio'),
  (7,1,4,'2008-08-29','09:36:04','99-99999999-9','2008-08-29','09:54:04','Satisfactorio'),
  (7,2,11,'2008-08-30','10:08:11','66-66666666-6','2008-08-30','10:26:11','Satisfactorio'),
  (7,2,5,'2008-08-30','10:44:05','66-66666666-6','2008-08-30','11:02:05','Satisfactorio'),
  (7,2,6,'2008-08-31','11:16:06','66-66666666-6','2008-08-31','11:34:06','Satisfactorio'),
  (8,1,11,'2008-08-30','09:00:11','77-77777777-7','2008-08-30','09:18:11','Satisfactorio'),
  (8,1,5,'2008-08-30','09:36:05','77-77777777-7','2008-08-30','09:54:05','Satisfactorio'),
  (8,1,6,'2008-08-31','10:08:06','88-88888888-8','2008-08-31','10:26:06','Satisfactorio'),
  (9,1,1,'2008-09-03','09:00:01','77-77777777-7','2008-09-03','09:18:01','Satisfactorio'),
  (9,1,10,'2008-09-03','09:36:10','77-77777777-7','2008-09-03','09:54:10','Satisfactorio'),
  (9,1,2,'2008-09-04','10:08:02','77-77777777-7','2008-09-04','10:26:02','Satisfactorio'),
  (9,1,3,'2008-09-04','10:44:03','88-88888888-8','2008-09-04','11:02:03','Satisfactorio'),
  (9,2,9,'2008-09-04','10:08:09','77-77777777-7','2008-09-04','10:26:09','Satisfactorio'),
  (10,1,7,'2008-09-07','09:00:07','99-99999999-9','2008-09-07','09:18:07','Satisfactorio'),
  (10,1,8,'2008-09-07','09:36:08','99-99999999-9','2008-09-07','09:54:08','Satisfactorio'),
  (10,2,11,'2008-09-08','10:08:11','88-88888888-8','2008-09-08','10:26:11','Satisfactorio'),
  (10,3,7,'2008-09-09','11:16:07','99-99999999-9','2008-09-09','11:34:07','Satisfactorio'),
  (10,3,8,'2008-09-09','11:52:08','99-99999999-9','2008-09-09','12:10:08','Satisfactorio'),
  (10,4,11,'2008-09-10','12:24:11','99-99999999-9','2008-09-10','12:42:11','Satisfactorio'),
  (10,4,5,'2008-09-10','13:00:00','99-99999999-9','2008-09-10','13:18:00','Satisfactorio'),
  (10,4,6,'2008-09-11','13:32:06','99-99999999-9','2008-09-11','13:50:06','Satisfactorio'),
  (10,5,9,'2008-09-11','13:32:09','99-99999999-9','2008-09-11','13:50:09','Satisfactorio'),
  (11,1,1,'2008-09-19','09:00:01','88-88888888-8','2008-09-19','09:18:01','Satisfactorio'),
  (11,1,10,'2008-09-19','09:36:10','88-88888888-8','2008-09-19','09:54:10','Satisfactorio'),
  (12,1,7,'2008-09-19','09:00:07','66-66666666-6','2008-09-19','09:18:07','Satisfactorio'),
  (12,1,8,'2008-09-19','09:36:08','66-66666666-6','2008-09-19','09:54:08','Satisfactorio'),
  (12,2,1,'2008-09-20','09:15:00','66-66666666-6','2008-09-20','09:20:00','Insatisfactorio'),
  (12,2,1,'2008-09-20','10:08:01','66-66666666-6','2008-09-20','10:26:01','Satisfactorio'),
  (13,1,7,'2008-09-19','09:00:07','66-66666666-6','2008-09-19','09:18:07','Satisfactorio'),
  (13,2,4,'2008-09-20','10:44:04','88-88888888-8','2008-09-20','11:02:04','Satisfactorio'),
  (15,1,1,'2008-09-20','09:00:01','77-77777777-7','2008-09-20','09:18:01','Satisfactorio'),
  (15,1,4,'2008-09-20','09:36:04','77-77777777-7','2008-09-20','09:54:04','Satisfactorio'),
  (15,2,11,'2008-09-21','09:30:00','99-99999999-9','2008-09-21','10:02:00','Insatisfactorio'),
  (15,2,11,'2008-09-21','10:08:11','77-77777777-7',NULL,NULL,NULL),
  (15,2,5,'2008-09-21','10:44:05','77-77777777-7',NULL,NULL,NULL);

COMMIT;

#
# Data for the `servicios_limpieza` table  (LIMIT 0,500)
#

INSERT INTO `servicios_limpieza` (`nro_servicio`, `fecha_entrega`, `fecha_dev_est`, `fecha_dev_real`, `prenda`, `estado_entrega`, `obs_cli`, `obs_internas`, `estado_dev`, `tipo_doc`, `nro_doc`) VALUES 
  (1,'2008-08-05','2008-08-10','2008-08-10','pantalon','bueno',NULL,NULL,NULL,'dni',11111111),
  (2,'2008-08-10','2008-08-15','2008-08-17','camisa','muy bueno','no entregar a la esposa','mancha lapiz labial',NULL,'dni',22222222),
  (3,'2008-08-18','2008-08-22','2008-08-22','traje','muy bueno',NULL,NULL,NULL,'dni',33333333),
  (4,'2008-08-20','2008-08-24','2008-08-26','gaban','bueno',NULL,NULL,NULL,'dni',44444444),
  (5,'2008-08-20','2008-08-25','2008-08-25','blusa','bueno',NULL,NULL,NULL,'dni',55555555),
  (6,'2008-08-25','2008-08-30','2008-08-29','vestido de novia','muy bueno','100% seda, muy delicado','ignorar obs del cliente, histeria de la dueña',NULL,'dni',22222222),
  (7,'2008-08-29','2008-09-03','2008-09-03','poncho de lana','bueno',NULL,'no poner con ropa oscura',NULL,'dni',33333333),
  (8,'2008-08-30','2008-09-03','2008-09-03','sweater','malo',NULL,NULL,NULL,'dni',22222222),
  (9,'2008-09-03','2008-09-06','2008-09-05','pantalon','malo','primer lavado, puede desteñir','lavar con ropa negra',NULL,'dni',55555555),
  (10,'2008-09-07','2008-09-11','2008-09-10','sweater','bueno',NULL,NULL,NULL,'dni',22222222),
  (11,'2008-09-19','2008-09-27',NULL,'campera','muy bueno',NULL,NULL,NULL,'dni',11111111),
  (12,'2008-09-19','2008-09-27',NULL,'cortina','bueno',NULL,'quitar los ganchos antes de lavar',NULL,'dni',22222222),
  (13,'2008-09-19','2008-09-27',NULL,'cubrecama','deplorable',NULL,'tiene varios remiendos',NULL,'dni',33333333),
  (14,'2008-09-20','2008-09-28',NULL,'campera nylon','malo',NULL,'manchas pero sin daño en la tela',NULL,'dni',55555555),
  (15,'2008-09-20','2008-09-28',NULL,'campera lana','malo','quitarle la pelusa',NULL,NULL,'dni',22222222);

COMMIT;

#
# Data for the `tratamientos_procesos` table  (LIMIT 0,500)
#

INSERT INTO `tratamientos_procesos` (`cod_tratamiento`, `cod_proceso`, `orden`) VALUES 
  (1,1,1),
  (2,1,1),
  (4,1,1),
  (1,2,2),
  (2,2,3),
  (1,3,3),
  (2,3,4),
  (4,4,2),
  (7,5,2),
  (7,6,3),
  (6,7,1),
  (6,8,2),
  (5,9,1),
  (2,10,2),
  (3,11,1),
  (7,11,1);

COMMIT;

#
# Data for the `valores_tratamientos` table  (LIMIT 0,500)
#

INSERT INTO `valores_tratamientos` (`cod_tratamiento`, `fecha_desde`, `valor`) VALUES 
  (1,'2008-08-01',100),
  (1,'2008-08-20',120),
  (1,'2008-09-16',138),
  (1,'2008-09-30',165.6),
  (2,'2008-08-01',250),
  (2,'2008-09-30',414),
  (3,'2008-08-01',80.5),
  (3,'2008-08-20',96.6),
  (3,'2008-09-16',111.09),
  (3,'2008-09-30',133.308),
  (4,'2008-08-01',20),
  (4,'2008-08-20',24),
  (4,'2008-09-16',27.6),
  (4,'2008-09-30',33.12),
  (5,'2008-08-01',25),
  (5,'2008-08-20',30),
  (5,'2008-09-16',34.5),
  (5,'2008-09-30',41.4),
  (6,'2008-08-01',75),
  (6,'2008-08-20',90),
  (6,'2008-09-30',124.2),
  (7,'2008-08-01',150),
  (7,'2008-08-20',180);

COMMIT;

