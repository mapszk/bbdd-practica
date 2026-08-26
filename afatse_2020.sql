SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS `afatse`;

CREATE DATABASE `afatse`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';

USE `afatse`;

#
# Structure for the `alumnos` table :
#

DROP TABLE IF EXISTS `alumnos`;

CREATE TABLE `alumnos` (
  `dni` int(11) NOT NULL,
  `nombre` varchar(20) NOT NULL,
  `apellido` varchar(20) NOT NULL,
  `tel` varchar(20) default NULL,
  `email` varchar(50) default NULL,
  `direccion` varchar(50) default NULL,
  PRIMARY KEY  (`dni`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `plan_capacitacion` table :
#

DROP TABLE IF EXISTS `plan_capacitacion`;

CREATE TABLE `plan_capacitacion` (
  `nom_plan` char(20) NOT NULL,
  `desc_plan` varchar(100) NOT NULL,
  `hs` int(11) NOT NULL,
  `modalidad` varchar(20) NOT NULL,
  PRIMARY KEY  (`nom_plan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `cursos` table :
#

DROP TABLE IF EXISTS `cursos`;

CREATE TABLE `cursos` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `fecha_ini` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `salon` varchar(20) default NULL,
  `cupo` int(11) default NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`),
  CONSTRAINT `cursos_plan_fk` FOREIGN KEY (`nom_plan`) REFERENCES `plan_capacitacion` (`nom_plan`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `inscripciones` table :
#

DROP TABLE IF EXISTS `inscripciones`;

CREATE TABLE `inscripciones` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `dni` int(11) NOT NULL,
  `fecha_inscripcion` date NOT NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`,`dni`),
  KEY `inscripcion_alumnos_fk` (`dni`),
  CONSTRAINT `inscripcion_alumnos_fk` FOREIGN KEY (`dni`) REFERENCES `alumnos` (`dni`) ON UPDATE CASCADE,
  CONSTRAINT `inscripcion_curso_fk` FOREIGN KEY (`nom_plan`, `nro_curso`) REFERENCES `cursos` (`nom_plan`, `nro_curso`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `cuotas` table :
#

DROP TABLE IF EXISTS `cuotas`;

CREATE TABLE `cuotas` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `dni` int(11) NOT NULL,
  `anio` int(11) NOT NULL,
  `mes` int(11) NOT NULL,
  `fecha_emision` date default NULL,
  `fecha_pago` date default NULL,
  `importe_pagado` decimal(9,3) default NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`,`dni`,`anio`,`mes`),
  CONSTRAINT `cuotas_inscripciones_fk` FOREIGN KEY (`nom_plan`, `nro_curso`, `dni`) REFERENCES `inscripciones` (`nom_plan`, `nro_curso`, `dni`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `cursos_horarios` table :
#

DROP TABLE IF EXISTS `cursos_horarios`;

CREATE TABLE `cursos_horarios` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `nro_dia_semana` int(11) NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`,`nro_dia_semana`),
  CONSTRAINT `cursos_horarios_cursos_fk` FOREIGN KEY (`nom_plan`, `nro_curso`) REFERENCES `cursos` (`nom_plan`, `nro_curso`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `instructores` table :
#

DROP TABLE IF EXISTS `instructores`;

CREATE TABLE `instructores` (
  `cuil` char(20) NOT NULL,
  `nombre` varchar(20) NOT NULL,
  `apellido` varchar(20) NOT NULL,
  `tel` varchar(20) default NULL,
  `email` varchar(50) default NULL,
  `direccion` varchar(50) default NULL,
  `cuil_supervisor` char(20) default NULL,
  PRIMARY KEY  (`cuil`),
  KEY `instructores_supervisor_fk` (`cuil_supervisor`),
  CONSTRAINT `instructores_supervisor_fk` FOREIGN KEY (`cuil_supervisor`) REFERENCES `instructores` (`cuil`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `cursos_instructores` table :
#

DROP TABLE IF EXISTS `cursos_instructores`;

CREATE TABLE `cursos_instructores` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `cuil` char(20) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`,`cuil`),
  KEY `cursos_instructores_instructores_fk` (`cuil`),
  CONSTRAINT `cursos_instructores_curso_fk` FOREIGN KEY (`nom_plan`, `nro_curso`) REFERENCES `cursos` (`nom_plan`, `nro_curso`) ON UPDATE CASCADE,
  CONSTRAINT `cursos_instructores_instructores_fk` FOREIGN KEY (`cuil`) REFERENCES `instructores` (`cuil`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `examenes` table :
#

DROP TABLE IF EXISTS `examenes`;

CREATE TABLE `examenes` (
  `nom_plan` char(20) NOT NULL,
  `nro_examen` int(11) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`nro_examen`),
  CONSTRAINT `examenes_plan_fk` FOREIGN KEY (`nom_plan`) REFERENCES `plan_capacitacion` (`nom_plan`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `evaluaciones` table :
#

DROP TABLE IF EXISTS `evaluaciones`;

CREATE TABLE `evaluaciones` (
  `nom_plan` char(20) NOT NULL,
  `nro_curso` int(11) NOT NULL,
  `dni` int(11) NOT NULL,
  `nro_examen` int(11) NOT NULL,
  `cuil` char(20) NOT NULL,
  `fecha_evaluacion` date NOT NULL,
  `nota` decimal(9,3) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`nro_curso`,`dni`,`nro_examen`),
  KEY `evaluaciones_examenes_fk` (`nom_plan`,`nro_examen`),
  KEY `evaluaciones_instructores_fk` (`cuil`),
  CONSTRAINT `evaluaciones_examenes_fk` FOREIGN KEY (`nom_plan`, `nro_examen`) REFERENCES `examenes` (`nom_plan`, `nro_examen`) ON UPDATE CASCADE,
  CONSTRAINT `evaluaciones_inscripciones_fk` FOREIGN KEY (`nom_plan`, `nro_curso`, `dni`) REFERENCES `inscripciones` (`nom_plan`, `nro_curso`, `dni`) ON UPDATE CASCADE,
  CONSTRAINT `evaluaciones_instructores_fk` FOREIGN KEY (`cuil`) REFERENCES `instructores` (`cuil`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `plan_temas` table :
#

DROP TABLE IF EXISTS `plan_temas`;

CREATE TABLE `plan_temas` (
  `nom_plan` char(20) NOT NULL,
  `titulo` char(30) NOT NULL,
  `detalle` varchar(75) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`titulo`),
  CONSTRAINT `plan_temas_plan_fk` FOREIGN KEY (`nom_plan`) REFERENCES `plan_capacitacion` (`nom_plan`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `examenes_temas` table :
#

DROP TABLE IF EXISTS `examenes_temas`;

CREATE TABLE `examenes_temas` (
  `nom_plan` char(20) NOT NULL,
  `titulo` char(30) NOT NULL,
  `nro_examen` int(11) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`titulo`,`nro_examen`),
  KEY `examenes_temas_examenes_fk` (`nom_plan`,`nro_examen`),
  CONSTRAINT `examenes_temas_examenes_fk` FOREIGN KEY (`nom_plan`, `nro_examen`) REFERENCES `examenes` (`nom_plan`, `nro_examen`) ON UPDATE CASCADE,
  CONSTRAINT `examenes_temas_plan_temas_fk` FOREIGN KEY (`nom_plan`, `titulo`) REFERENCES `plan_temas` (`nom_plan`, `titulo`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `materiales` table :
#

DROP TABLE IF EXISTS `materiales`;

CREATE TABLE `materiales` (
  `cod_material` char(6) NOT NULL,
  `desc_material` varchar(50) NOT NULL,
  `url_descarga` varchar(50) default NULL,
  `autores` varchar(50) default NULL,
  `tamanio` decimal(9,3) default NULL,
  `fecha_creacion` date default NULL,
  `cant_disponible` int(11) default NULL,
  `punto_pedido` int(11) default NULL,
  `cantidad_a_pedir` int(11) default NULL,
  PRIMARY KEY  (`cod_material`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `materiales_plan` table :
#

DROP TABLE IF EXISTS `materiales_plan`;

CREATE TABLE `materiales_plan` (
  `nom_plan` char(20) NOT NULL,
  `cod_material` char(6) NOT NULL,
  `cant_entrega` int(11) NOT NULL default '0',
  PRIMARY KEY  (`nom_plan`,`cod_material`),
  KEY `nom_plan` (`nom_plan`),
  KEY `materiales_plan_materiales_fk` (`cod_material`),
  CONSTRAINT `materiales_plan_materiales_fk` FOREIGN KEY (`cod_material`) REFERENCES `materiales` (`cod_material`) ON UPDATE CASCADE,
  CONSTRAINT `materiales_plan_plan_capacitacion_fk` FOREIGN KEY (`nom_plan`) REFERENCES `plan_capacitacion` (`nom_plan`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `proveedores` table :
#

DROP TABLE IF EXISTS `proveedores`;

CREATE TABLE `proveedores` (
  `cuit` char(20) NOT NULL,
  `razon_social` varchar(50) NOT NULL,
  `direccion` varchar(50) default NULL,
  `telefono` varchar(20) default NULL,
  PRIMARY KEY  (`cuit`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `proveedores_materiales` table :
#

DROP TABLE IF EXISTS `proveedores_materiales`;

CREATE TABLE `proveedores_materiales` (
  `cuit` char(20) NOT NULL,
  `cod_material` char(6) NOT NULL,
  PRIMARY KEY  (`cuit`,`cod_material`),
  KEY `proveedores_materiales_materiales_fk` (`cod_material`),
  CONSTRAINT `proveedores_materiales_materiales_fk` FOREIGN KEY (`cod_material`) REFERENCES `materiales` (`cod_material`) ON UPDATE CASCADE,
  CONSTRAINT `proveedores_materiales_proveedores_fk` FOREIGN KEY (`cuit`) REFERENCES `proveedores` (`cuit`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Structure for the `valores_plan` table :
#

DROP TABLE IF EXISTS `valores_plan`;

CREATE TABLE `valores_plan` (
  `nom_plan` varchar(20) NOT NULL,
  `fecha_desde_plan` date NOT NULL,
  `valor_plan` decimal(9,3) NOT NULL,
  PRIMARY KEY  (`nom_plan`,`fecha_desde_plan`),
  CONSTRAINT `valores_plan_plan_fk` FOREIGN KEY (`nom_plan`) REFERENCES `plan_capacitacion` (`nom_plan`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#
# Data for the `alumnos` table  (LIMIT 0,500)
#

INSERT INTO `alumnos` (`dni`, `nombre`, `apellido`, `tel`, `email`, `direccion`) VALUES
  (10101010,'Ruben','Dario','1010101','rdario@gmail.com','Rio de Janeiro 1010'),
  (11111111,'Casimiro','Cegado','1111111','casimirocegado9B@yahoo.com.ar','9 de julio 111 9B'),
  (12121212,'Maria','Asquerino','1212121','masqu@gmail.com','Salta 1212'),
  (13131313,'Antoine de','Saint-Exupery','1313131','anto_saex@gmail.com','Francia 1313'),
  (14141414,'Jose','Echegaray','1414141','joseche@uol.com','Entre Rios 1414'),
  (15151515,'Isabel','Gemio','1515151','igemio@yahoo.com.ar','Garay 1515'),
  (16161616,'Gertrudis','Gomez de Avellaneda','1616161','gertygomez@gmail.com','Rodriguez 1616'),
  (17171717,'Ana Maria','Matute','1717171','ana_m_matute@gmail.com','Salta 1717'),
  (18181818,'Victor','Montenegro','1818181','v_monte_negro@hotmail.com','Lavalle 1818'),
  (19191919,'Blaise','Pascal','1919191','blaise@pascal.com.ar','Entre Rios 1919'),
  (20202020,'Bella','Abzug','2020202','babzug333@yahoo.com','Anchorena 2020'),
  (21212121,'Jorge','Bucay','2121212','totobuca@hotmail.com','Mendoza 2121'),
  (22222222,'Laura','Morante','2222222','lau_morante22@gmail.com','Italia 2222'),
  (23232323,'Victor','Hugo','2323232','vichugo@gmail.com','Pellegrini 2323'),
  (24242424,'José','Ortega y Gasset','2424242','pepe_oys@hotmail.com','Francia 2424');

COMMIT;

#
# Data for the `plan_capacitacion` table  (LIMIT 0,500)
#

INSERT INTO `plan_capacitacion` (`nom_plan`, `desc_plan`, `hs`, `modalidad`) VALUES
  ('Marketing 1','Dar a conocer su empresa, crear la imagen deseada, difusion en medios adecuados',100,'A Distancia'),
  ('Marketing 2','Seleccion del sector de mercado. Matriz FODA.',150,'Semipresencial'),
  ('Marketing 3','Competencia Desleal',180,'Semiresencial'),
  ('Reparac PC Avanzada','Configuración de SO Linux/Windows y de red. Herramientas de diagnostico especializadas y reparacion',240,'Presencial'),
  ('Reparacion PC','Identidifar componentes de una pc, diagnosticar problemas y reemplazo de partes dañadas',100,'Presencial');

COMMIT;

#
# Data for the `cursos` table  (LIMIT 0,500)
#

INSERT INTO `cursos` (`nom_plan`, `nro_curso`, `fecha_ini`, `fecha_fin`, `salon`, `cupo`) VALUES
  ('Marketing 1',1,'2013-04-01','2013-10-01',NULL,100),
  ('Marketing 1',2,'2014-04-01','2014-10-01',NULL,100),
  ('Marketing 1',3,'2015-04-01','2015-10-01',NULL,100),
  ('Marketing 2',1,'2014-04-01','2014-11-01','1',20),
  ('Marketing 2',2,'2014-04-01','2014-11-01','1',20),
  ('Marketing 2',3,'2015-04-01','2015-11-01','1',20),
  ('Marketing 3',1,'2015-04-01','2015-12-15','2',3),
  ('Reparac PC Avanzada',1,'2014-03-01','2014-12-15','3',10),
  ('Reparac PC Avanzada',2,'2015-03-01','2015-12-15','3',10),
  ('Reparacion PC',1,'2013-05-01','2013-11-01','3',10),
  ('Reparacion PC',2,'2014-05-01','2014-11-01','3',10),
  ('Reparacion PC',3,'2015-05-01','2015-11-01','3',10);

COMMIT;

#
# Data for the `inscripciones` table  (LIMIT 0,500)
#

INSERT INTO `inscripciones` (`nom_plan`, `nro_curso`, `dni`, `fecha_inscripcion`) VALUES
  ('Marketing 1',1,10101010,'2013-01-10'),
  ('Marketing 1',1,11111111,'2013-02-20'),
  ('Marketing 1',1,12121212,'2013-01-18'),
  ('Marketing 1',1,13131313,'2013-02-07'),
  ('Marketing 1',2,20202020,'2014-01-15'),
  ('Marketing 1',2,21212121,'2014-01-28'),
  ('Marketing 1',2,22222222,'2014-02-03'),
  ('Marketing 2',1,10101010,'2014-02-11'),
  ('Marketing 2',1,11111111,'2014-01-20'),
  ('Marketing 2',1,12121212,'2014-01-07'),
  ('Marketing 2',2,23232323,'2014-01-14'),
  ('Marketing 2',2,24242424,'2014-02-07'),
  ('Marketing 2',3,10101010,'2015-03-02'),
  ('Marketing 2',3,13131313,'2015-03-09'),
  ('Marketing 2',3,20202020,'2015-01-20'),
  ('Marketing 2',3,22222222,'2015-01-21'),
  ('Marketing 2',3,24242424,'2015-02-28'),
  ('Marketing 3',1,11111111,'2015-01-09'),
  ('Marketing 3',1,12121212,'2015-02-19'),
  ('Marketing 3',1,24242424,'2015-03-28'),
  ('Reparac PC Avanzada',1,15151515,'2014-01-18'),
  ('Reparac PC Avanzada',1,17171717,'2014-01-09'),
  ('Reparac PC Avanzada',2,14141414,'2015-01-28'),
  ('Reparac PC Avanzada',2,17171717,'2015-01-12'),
  ('Reparac PC Avanzada',2,18181818,'2015-01-21'),
  ('Reparacion PC',1,14141414,'2013-02-11'),
  ('Reparacion PC',1,15151515,'2013-02-19'),
  ('Reparacion PC',1,16161616,'2013-01-20'),
  ('Reparacion PC',1,17171717,'2013-01-17'),
  ('Reparacion PC',1,18181818,'2013-01-31'),
  ('Reparacion PC',2,22222222,'2014-01-08'),
  ('Reparacion PC',3,22222222,'2015-01-03');

COMMIT;

#
# Data for the `cuotas` table  (LIMIT 0,500)
#

INSERT INTO `cuotas` (`nom_plan`, `nro_curso`, `dni`, `anio`, `mes`, `fecha_emision`, `fecha_pago`, `importe_pagado`) VALUES
  ('Marketing 1',1,10101010,2013,4,'2013-04-01','2013-04-05',25),
  ('Marketing 1',1,10101010,2013,5,'2013-05-01','2013-05-14',31.25),
  ('Marketing 1',1,10101010,2013,6,'2013-06-01','2013-06-24',35),
  ('Marketing 1',1,10101010,2013,7,'2013-07-01','2013-07-20',35),
  ('Marketing 1',1,10101010,2013,8,'2013-08-01','2013-08-27',35),
  ('Marketing 1',1,10101010,2013,9,'2013-09-01','2013-09-18',35),
  ('Marketing 1',1,11111111,2013,4,'2013-04-01','2013-04-08',25),
  ('Marketing 1',1,11111111,2013,5,'2013-05-01','2013-05-12',31.25),
  ('Marketing 1',1,11111111,2013,6,'2013-06-01','2013-06-10',28),
  ('Marketing 1',1,11111111,2013,7,'2013-07-01','2013-07-11',35),
  ('Marketing 1',1,11111111,2013,8,'2013-08-01','2013-08-25',35),
  ('Marketing 1',1,11111111,2013,9,'2013-09-01','2013-09-04',28),
  ('Marketing 1',1,12121212,2013,4,'2013-04-01','2013-04-05',25),
  ('Marketing 1',1,12121212,2013,5,'2013-05-01','2013-05-10',25),
  ('Marketing 1',1,12121212,2013,6,'2013-06-01','2013-06-05',28),
  ('Marketing 1',1,12121212,2013,7,'2013-07-01','2013-07-23',35),
  ('Marketing 1',1,12121212,2013,8,'2013-08-01','2013-08-14',35),
  ('Marketing 1',1,12121212,2013,9,'2013-09-01','2013-09-02',28),
  ('Marketing 1',1,13131313,2013,4,'2013-04-01','2013-04-25',31.25),
  ('Marketing 1',1,13131313,2013,5,'2013-05-01','2013-05-03',25),
  ('Marketing 1',1,13131313,2013,6,'2013-06-01','2013-06-27',35),
  ('Marketing 1',1,13131313,2013,7,'2013-07-01','2013-07-07',28),
  ('Marketing 1',1,13131313,2013,8,'2013-08-01','2013-08-11',35),
  ('Marketing 1',1,13131313,2013,9,'2013-09-01','2013-09-04',28),
  ('Marketing 1',2,20202020,2014,4,'2014-04-01','2014-04-17',46.25),
  ('Marketing 1',2,20202020,2014,5,'2014-05-01','2014-05-15',46.25),
  ('Marketing 1',2,20202020,2014,6,'2014-06-01','2014-06-25',56.25),
  ('Marketing 1',2,20202020,2014,7,'2014-07-01','2014-07-21',56.25),
  ('Marketing 1',2,20202020,2014,8,'2014-08-01','2014-08-27',67.5),
  ('Marketing 1',2,20202020,2014,9,'2014-09-01','2014-09-15',67.5),
  ('Marketing 1',2,21212121,2014,4,'2014-04-01','2014-04-22',46.25),
  ('Marketing 1',2,21212121,2014,5,'2014-05-01','2014-05-08',37),
  ('Marketing 1',2,21212121,2014,6,'2014-06-01','2014-06-03',45),
  ('Marketing 1',2,21212121,2014,7,'2014-07-01','2014-07-17',56.25),
  ('Marketing 1',2,21212121,2014,8,'2014-08-01','2014-08-19',67.5),
  ('Marketing 1',2,21212121,2014,9,'2014-09-01','2014-09-16',67.5),
  ('Marketing 1',2,22222222,2014,4,'2014-04-01','2014-04-21',46.25),
  ('Marketing 1',2,22222222,2014,5,'2014-05-01','2014-05-28',46.25),
  ('Marketing 1',2,22222222,2014,6,'2014-06-01','2014-06-18',56.25),
  ('Marketing 1',2,22222222,2014,7,'2014-07-01','2014-07-07',45),
  ('Marketing 1',2,22222222,2014,8,'2014-08-01','2014-08-07',54),
  ('Marketing 1',2,22222222,2014,9,'2014-09-01','2014-09-16',67.5),
  ('Marketing 2',1,10101010,2014,4,'2014-04-01','2014-04-29',75),
  ('Marketing 2',1,10101010,2014,5,'2014-05-01','2014-05-09',60),
  ('Marketing 2',1,10101010,2014,6,'2014-06-01','2014-06-16',91.25),
  ('Marketing 2',1,10101010,2014,7,'2014-07-01','2014-07-22',91.25),
  ('Marketing 2',1,10101010,2014,8,'2014-08-01','2014-08-03',88),
  ('Marketing 2',1,10101010,2014,9,'2014-09-01','2014-09-06',88),
  ('Marketing 2',1,10101010,2014,10,'2014-10-01','2014-10-23',110),
  ('Marketing 2',1,11111111,2014,4,'2014-04-01','2014-04-10',60),
  ('Marketing 2',1,11111111,2014,5,'2014-05-01','2014-05-07',60),
  ('Marketing 2',1,11111111,2014,6,'2014-06-01','2014-06-06',73),
  ('Marketing 2',1,11111111,2014,7,'2014-07-01','2014-07-09',73),
  ('Marketing 2',1,11111111,2014,8,'2014-08-01','2014-08-28',110),
  ('Marketing 2',1,11111111,2014,9,'2014-09-01','2014-09-23',110),
  ('Marketing 2',1,11111111,2014,10,'2014-10-01','2014-10-01',88),
  ('Marketing 2',1,12121212,2014,4,'2014-04-01','2014-04-25',75),
  ('Marketing 2',1,12121212,2014,5,'2014-05-01','2014-05-06',60),
  ('Marketing 2',1,12121212,2014,6,'2014-06-01','2014-06-11',91.25),
  ('Marketing 2',1,12121212,2014,7,'2014-07-01','2014-07-08',73),
  ('Marketing 2',1,12121212,2014,8,'2014-08-01','2014-08-04',88),
  ('Marketing 2',1,12121212,2014,9,'2014-09-01','2014-09-27',110),
  ('Marketing 2',1,12121212,2014,10,'2014-10-01','2014-10-06',88),
  ('Marketing 2',2,23232323,2014,4,'2014-04-01','2014-04-02',60),
  ('Marketing 2',2,23232323,2014,5,'2014-05-01','2014-05-01',60),
  ('Marketing 2',2,23232323,2014,6,'2014-06-01','2014-06-02',73),
  ('Marketing 2',2,23232323,2014,7,'2014-07-01','2014-07-02',73),
  ('Marketing 2',2,23232323,2014,8,'2014-08-01','2014-08-02',88),
  ('Marketing 2',2,23232323,2014,9,'2014-09-01','2014-09-02',88),
  ('Marketing 2',2,23232323,2014,10,'2014-10-01','2014-10-02',88),
  ('Marketing 2',2,24242424,2014,4,'2014-04-01','2014-04-02',60),
  ('Marketing 2',2,24242424,2014,5,'2014-05-01','2014-05-01',60),
  ('Marketing 2',2,24242424,2014,6,'2014-06-01','2014-06-02',73),
  ('Marketing 2',2,24242424,2014,7,'2014-07-01',NULL,NULL),
  ('Marketing 2',2,24242424,2014,8,'2014-08-01',NULL,NULL),
  ('Marketing 2',2,24242424,2014,9,'2014-09-01',NULL,NULL),
  ('Marketing 2',2,24242424,2014,10,'2014-10-01',NULL,NULL),
  ('Reparac PC Avanzada',1,15151515,2014,3,'2014-03-01','2014-03-07',80),
  ('Reparac PC Avanzada',1,15151515,2014,4,'2014-04-01','2014-04-16',118.75),
  ('Reparac PC Avanzada',1,15151515,2014,5,'2014-05-01','2014-05-01',95),
  ('Reparac PC Avanzada',1,15151515,2014,6,'2014-06-01','2014-06-14',150),
  ('Reparac PC Avanzada',1,15151515,2014,7,'2014-07-01','2014-07-09',120),
  ('Reparac PC Avanzada',1,15151515,2014,8,'2014-08-01','2014-08-03',145),
  ('Reparac PC Avanzada',1,15151515,2014,9,'2014-09-01','2014-09-14',181.25),
  ('Reparac PC Avanzada',1,15151515,2014,10,'2014-10-01','2014-10-04',145),
  ('Reparac PC Avanzada',1,15151515,2014,11,'2014-11-01','2014-11-08',145),
  ('Reparac PC Avanzada',1,15151515,2014,12,'2014-12-01','2014-12-25',181.25),
  ('Reparac PC Avanzada',1,17171717,2014,3,'2014-03-01','2014-03-14',100),
  ('Reparac PC Avanzada',1,17171717,2014,4,'2014-04-01','2014-04-22',118.75),
  ('Reparac PC Avanzada',1,17171717,2014,5,'2014-05-01','2014-05-11',118.75),
  ('Reparac PC Avanzada',1,17171717,2014,6,'2014-06-01','2014-06-16',150),
  ('Reparac PC Avanzada',1,17171717,2014,7,'2014-07-01','2014-07-17',150),
  ('Reparac PC Avanzada',1,17171717,2014,8,'2014-08-01','2014-08-10',145),
  ('Reparac PC Avanzada',1,17171717,2014,9,'2014-09-01','2014-09-25',181.25),
  ('Reparac PC Avanzada',1,17171717,2014,10,'2014-10-01','2014-10-07',145),
  ('Reparac PC Avanzada',1,17171717,2014,11,'2014-11-01','2014-11-17',181.25),
  ('Reparac PC Avanzada',1,17171717,2014,12,'2014-12-01','2014-12-05',145),
  ('Reparacion PC',1,14141414,2013,5,'2013-05-01','2013-05-04',37),
  ('Reparacion PC',1,14141414,2013,6,'2013-06-01','2013-06-04',42),
  ('Reparacion PC',1,14141414,2013,7,'2013-07-01','2013-07-10',42),
  ('Reparacion PC',1,14141414,2013,8,'2013-08-01','2013-08-05',42),
  ('Reparacion PC',1,14141414,2013,9,'2013-09-01','2013-09-27',52.5),
  ('Reparacion PC',1,14141414,2013,10,'2013-10-01','2013-10-02',42),
  ('Reparacion PC',1,15151515,2013,5,'2013-05-01','2013-05-14',46.25),
  ('Reparacion PC',1,15151515,2013,6,'2013-06-01','2013-06-05',42),
  ('Reparacion PC',1,15151515,2013,7,'2013-07-01','2013-07-11',52.5),
  ('Reparacion PC',1,15151515,2013,8,'2013-08-01','2013-08-12',52.5),
  ('Reparacion PC',1,15151515,2013,9,'2013-09-01','2013-09-27',52.5),
  ('Reparacion PC',1,15151515,2013,10,'2013-10-01','2013-10-09',42),
  ('Reparacion PC',1,16161616,2013,5,'2013-05-01','2013-05-23',46.25),
  ('Reparacion PC',1,16161616,2013,6,'2013-06-01','2013-06-01',42),
  ('Reparacion PC',1,16161616,2013,7,'2013-07-01','2013-07-24',52.5),
  ('Reparacion PC',1,16161616,2013,8,'2013-08-01','2013-08-28',52.5),
  ('Reparacion PC',1,16161616,2013,9,'2013-09-01','2013-09-10',42),
  ('Reparacion PC',1,16161616,2013,10,'2013-10-01','2013-10-23',52.5),
  ('Reparacion PC',1,17171717,2013,5,'2013-05-01','2013-05-28',46.25),
  ('Reparacion PC',1,17171717,2013,6,'2013-06-01','2013-06-11',52.5),
  ('Reparacion PC',1,17171717,2013,7,'2013-07-01','2013-07-27',52.5),
  ('Reparacion PC',1,17171717,2013,8,'2013-08-01','2013-08-16',52.5),
  ('Reparacion PC',1,17171717,2013,9,'2013-09-01','2013-09-29',52.5),
  ('Reparacion PC',1,17171717,2013,10,'2013-10-01','2013-10-08',42),
  ('Reparacion PC',1,18181818,2013,5,'2013-05-01','2013-05-10',37),
  ('Reparacion PC',1,18181818,2013,6,'2013-06-01','2013-06-27',52.5),
  ('Reparacion PC',1,18181818,2013,7,'2013-07-01','2013-07-19',52.5),
  ('Reparacion PC',1,18181818,2013,8,'2013-08-01','2013-08-11',52.5),
  ('Reparacion PC',1,18181818,2013,9,'2013-09-01','2013-09-28',52.5),
  ('Reparacion PC',1,18181818,2013,10,'2013-10-01','2013-10-17',52.5),
  ('Reparacion PC',2,22222222,2014,5,'2014-05-01','2014-05-03',54),
  ('Reparacion PC',2,22222222,2014,6,'2014-06-01','2014-06-19',81.25),
  ('Reparacion PC',2,22222222,2014,7,'2014-07-01','2014-07-29',81.25),
  ('Reparacion PC',2,22222222,2014,8,'2014-08-01','2014-08-29',100),
  ('Reparacion PC',2,22222222,2014,9,'2014-09-01','2014-09-01',80),
  ('Reparacion PC',2,22222222,2014,10,'2014-10-01','2014-10-02',80);

COMMIT;

#
# Data for the `cursos_horarios` table  (LIMIT 0,500)
#

INSERT INTO `cursos_horarios` (`nom_plan`, `nro_curso`, `nro_dia_semana`, `hora_inicio`, `hora_fin`) VALUES
  ('Marketing 1',1,1,'16:00:00','18:00:00'),
  ('Marketing 1',1,3,'16:00:00','18:00:00'),
  ('Marketing 1',2,1,'16:00:00','18:00:00'),
  ('Marketing 1',2,3,'16:00:00','18:00:00'),
  ('Marketing 1',3,1,'16:00:00','18:00:00'),
  ('Marketing 1',3,3,'16:00:00','18:00:00'),
  ('Marketing 2',1,1,'16:00:00','18:30:00'),
  ('Marketing 2',1,3,'16:00:00','18:30:00'),
  ('Marketing 2',2,1,'08:00:00','13:00:00'),
  ('Marketing 2',3,1,'16:00:00','18:30:00'),
  ('Marketing 2',3,3,'16:00:00','18:30:00'),
  ('Marketing 3',1,1,'17:00:00','19:30:00'),
  ('Marketing 3',1,3,'17:00:00','19:30:00'),
  ('Reparac PC Avanzada',1,2,'18:00:00','21:00:00'),
  ('Reparac PC Avanzada',1,4,'18:00:00','21:00:00'),
  ('Reparac PC Avanzada',2,2,'18:00:00','21:00:00'),
  ('Reparac PC Avanzada',2,4,'18:00:00','21:00:00'),
  ('Reparacion PC',1,1,'18:00:00','20:00:00'),
  ('Reparacion PC',1,3,'18:00:00','20:00:00'),
  ('Reparacion PC',2,1,'18:00:00','20:00:00'),
  ('Reparacion PC',2,3,'18:00:00','20:00:00'),
  ('Reparacion PC',3,1,'18:00:00','20:00:00'),
  ('Reparacion PC',3,3,'18:00:00','20:00:00');

COMMIT;

#
# Data for the `instructores` table  (LIMIT 0,500)
#

INSERT INTO `instructores` (`cuil`, `nombre`, `apellido`, `tel`, `email`, `direccion`, `cuil_supervisor`) VALUES
  ('30-30303030-3','Rosa','Pelaes','3030303','rpelaes77@afatse.com.ar','9 de Julio 3030','99-99999999-9'),
  ('31-31313131-3','Jacinto','Ibañes','3131313','jibañes@afatse.com.ar','Pte. Roca 3131','99-99999999-9'),
  ('55-55555555-5','Henri','Amiel','5555555','hamiel@afatse.com.ar','Ayacucho 5555',NULL),
  ('66-66666666-6','Franz','Kafka','6666666','fkafka@afatse.com.ar','San Luis 666 6F','55-55555555-5'),
  ('77-77777777-7','Francisco','Umbral','7777777','fumbral@afatse.com.ar','Italia 777','55-55555555-5'),
  ('88-88888888-8','Otto','Wagner','8888888','owagner@afatse.com.ar','Rondeau 888','77-77777777-7'),
  ('99-99999999-9','Elias','Yanes','9999999','eyanes@afatse.com.ar','27 de Febrero 999','88-88888888-8');

COMMIT;

#
# Data for the `cursos_instructores` table  (LIMIT 0,500)
#

INSERT INTO `cursos_instructores` (`nom_plan`, `nro_curso`, `cuil`) VALUES
  ('Marketing 1',1,'55-55555555-5'),
  ('Marketing 1',2,'55-55555555-5'),
  ('Marketing 3',1,'55-55555555-5'),
  ('Marketing 1',3,'66-66666666-6'),
  ('Marketing 2',1,'66-66666666-6'),
  ('Marketing 2',2,'66-66666666-6'),
  ('Marketing 2',3,'66-66666666-6'),
  ('Marketing 3',1,'66-66666666-6'),
  ('Marketing 1',1,'77-77777777-7'),
  ('Marketing 1',2,'77-77777777-7'),
  ('Marketing 1',3,'77-77777777-7'),
  ('Marketing 2',1,'77-77777777-7'),
  ('Marketing 2',3,'77-77777777-7'),
  ('Marketing 3',1,'77-77777777-7'),
  ('Marketing 2',2,'88-88888888-8'),
  ('Reparac PC Avanzada',1,'88-88888888-8'),
  ('Reparac PC Avanzada',2,'88-88888888-8'),
  ('Reparacion PC',1,'88-88888888-8'),
  ('Reparacion PC',3,'88-88888888-8'),
  ('Reparac PC Avanzada',1,'99-99999999-9'),
  ('Reparac PC Avanzada',2,'99-99999999-9'),
  ('Reparacion PC',2,'99-99999999-9'),
  ('Reparacion PC',3,'99-99999999-9');

COMMIT;

#
# Data for the `examenes` table  (LIMIT 0,500)
#

INSERT INTO `examenes` (`nom_plan`, `nro_examen`) VALUES
  ('Marketing 1',1),
  ('Marketing 1',2),
  ('Marketing 2',1),
  ('Marketing 2',2),
  ('Marketing 3',1),
  ('Marketing 3',2),
  ('Marketing 3',3),
  ('Marketing 3',4),
  ('Reparac PC Avanzada',1),
  ('Reparac PC Avanzada',2),
  ('Reparac PC Avanzada',3),
  ('Reparacion PC',1),
  ('Reparacion PC',2);

COMMIT;

#
# Data for the `evaluaciones` table  (LIMIT 0,500)
#

INSERT INTO `evaluaciones` (`nom_plan`, `nro_curso`, `dni`, `nro_examen`, `cuil`, `fecha_evaluacion`, `nota`) VALUES
  ('Marketing 1',1,10101010,1,'55-55555555-5','2013-06-15',6),
  ('Marketing 1',1,10101010,2,'55-55555555-5','2013-09-29',7),
  ('Marketing 1',1,11111111,1,'77-77777777-7','2013-06-15',8.47),
  ('Marketing 1',1,11111111,2,'77-77777777-7','2013-09-29',7.3),
  ('Marketing 1',1,12121212,1,'55-55555555-5','2013-06-15',6),
  ('Marketing 1',1,12121212,2,'55-55555555-5','2013-09-29',8),
  ('Marketing 1',1,13131313,1,'77-77777777-7','2013-06-15',7.5),
  ('Marketing 1',1,13131313,2,'77-77777777-7','2013-09-29',6.9),
  ('Marketing 1',2,20202020,1,'77-77777777-7','2014-06-15',10),
  ('Marketing 1',2,20202020,2,'77-77777777-7','2014-09-29',4.5),
  ('Marketing 1',2,21212121,1,'77-77777777-7','2014-06-15',6),
  ('Marketing 1',2,21212121,2,'55-55555555-5','2014-09-29',6.89),
  ('Marketing 1',2,22222222,1,'55-55555555-5','2014-06-15',6),
  ('Marketing 1',2,22222222,2,'55-55555555-5','2014-09-29',8),
  ('Marketing 2',1,10101010,1,'66-66666666-6','2014-06-30',5),
  ('Marketing 2',1,10101010,2,'77-77777777-7','2014-10-31',4),
  ('Marketing 2',1,11111111,1,'77-77777777-7','2014-06-30',5),
  ('Marketing 2',1,11111111,2,'66-66666666-6','2014-10-31',9),
  ('Marketing 2',1,12121212,1,'66-66666666-6','2014-06-30',5),
  ('Marketing 2',1,12121212,2,'77-77777777-7','2014-10-31',7),
  ('Marketing 2',2,23232323,1,'66-66666666-6','2014-06-29',10),
  ('Marketing 2',2,23232323,2,'88-88888888-8','2014-10-27',9.9),
  ('Marketing 2',2,24242424,1,'88-88888888-8','2014-06-29',10),
  ('Marketing 2',2,24242424,2,'66-66666666-6','2014-10-27',10),
  ('Reparac PC Avanzada',1,15151515,1,'88-88888888-8','2014-05-31',8.44),
  ('Reparac PC Avanzada',1,15151515,2,'99-99999999-9','2014-09-05',9.82),
  ('Reparac PC Avanzada',1,15151515,3,'99-99999999-9','2014-12-14',3.5),
  ('Reparac PC Avanzada',1,17171717,1,'88-88888888-8','2014-05-31',5.42),
  ('Reparac PC Avanzada',1,17171717,2,'88-88888888-8','2014-09-05',4.81),
  ('Reparac PC Avanzada',1,17171717,3,'99-99999999-9','2014-12-14',7),
  ('Reparacion PC',1,14141414,1,'99-99999999-9','2013-06-30',6.59),
  ('Reparacion PC',1,14141414,2,'88-88888888-8','2013-10-31',9),
  ('Reparacion PC',1,15151515,1,'88-88888888-8','2013-06-30',7),
  ('Reparacion PC',1,15151515,2,'99-99999999-9','2013-10-31',8),
  ('Reparacion PC',1,16161616,1,'99-99999999-9','2013-06-30',0),
  ('Reparacion PC',1,16161616,2,'88-88888888-8','2013-10-31',0),
  ('Reparacion PC',1,17171717,1,'88-88888888-8','2013-06-30',10),
  ('Reparacion PC',1,17171717,2,'99-99999999-9','2013-10-31',8),
  ('Reparacion PC',1,18181818,1,'99-99999999-9','2013-06-30',10),
  ('Reparacion PC',1,18181818,2,'88-88888888-8','2013-10-31',10),
  ('Reparacion PC',2,22222222,1,'99-99999999-9','2014-06-30',2),
  ('Reparacion PC',2,22222222,2,'88-88888888-8','2014-10-31',2.39);

COMMIT;

#
# Data for the `plan_temas` table  (LIMIT 0,500)
#

INSERT INTO `plan_temas` (`nom_plan`, `titulo`, `detalle`) VALUES
  ('Marketing 1','1- Imagen empresarial','Crear la imagen deseada para la empresa'),
  ('Marketing 1','2- Medios de difusion','Evaluacion y análisis de medios de difusion para publicitar'),
  ('Marketing 1','3- Publicidad Institucional','Creacion de mensaje publicitario'),
  ('Marketing 2','1- Mercados','Segmentos de mercado. Targeting'),
  ('Marketing 2','2- FODA','Evaluación de FODA de le empresa y su aplicacion'),
  ('Marketing 2','3- Integracion de contenidos','Targeting basado en matriz FODA y potenciación de la empresa basada en FODA'),
  ('Marketing 3','1-Proteccion de la informacion','Proteccion contra espionaje industrial'),
  ('Marketing 3','2- Espionage industrial','Identificacion de posible espias en competidores'),
  ('Marketing 3','3- Difamacion','Tecnicas de difamacion de competidores'),
  ('Marketing 3','4- Robo de cerebros','Identificar RRHH claves en competidores y traerlos a la empresa'),
  ('Marketing 3','5- Sabotaje','Planificacion y ejecucion de sabotajes. Destruir evidencia comprometedora'),
  ('Reparac PC Avanzada','1- SO Usuarios','Uso e instalacion. Windows 98, XP y Vista'),
  ('Reparac PC Avanzada','2- SO Avanzados','Uso e instalacion. Linux Ubuntu, Debian y Slackware. Windows 2003 y 2014'),
  ('Reparac PC Avanzada','3- Redes','Instalacion y configuracion de redes en todos los SO antes vistos '),
  ('Reparac PC Avanzada','4- Herramientas Especializadas','Uso de herramientas especializadas para detectar errores en redes y SOs'),
  ('Reparac PC Avanzada','5- Reparacion','Reparacion de problemas frecuentes y prevencion'),
  ('Reparacion PC','1- Introduccion','Componentes de una PC. Identificacion y funcion'),
  ('Reparacion PC','2- Diagnostico','Reconocimiento de problemas comunes en el harware y sus causas'),
  ('Reparacion PC','3- Reparacion','Reemplazo de partes defectuosas determinadas durante el diagnostico');

COMMIT;

#
# Data for the `examenes_temas` table  (LIMIT 0,500)
#

INSERT INTO `examenes_temas` (`nom_plan`, `titulo`, `nro_examen`) VALUES
  ('Marketing 1','1- Imagen empresarial',1),
  ('Marketing 1','2- Medios de difusion',1),
  ('Marketing 1','3- Publicidad Institucional',2),
  ('Marketing 2','1- Mercados',1),
  ('Marketing 2','2- FODA',1),
  ('Marketing 2','3- Integracion de contenidos',2),
  ('Marketing 3','1-Proteccion de la informacion',1),
  ('Marketing 3','2- Espionage industrial',2),
  ('Marketing 3','3- Difamacion',3),
  ('Marketing 3','4- Robo de cerebros',3),
  ('Marketing 3','5- Sabotaje',4),
  ('Reparac PC Avanzada','1- SO Usuarios',1),
  ('Reparac PC Avanzada','2- SO Avanzados',1),
  ('Reparac PC Avanzada','3- Redes',2),
  ('Reparac PC Avanzada','4- Herramientas Especializadas',3),
  ('Reparac PC Avanzada','5- Reparacion',3),
  ('Reparacion PC','1- Introduccion',1),
  ('Reparacion PC','2- Diagnostico',1),
  ('Reparacion PC','3- Reparacion',2);

COMMIT;

#
# Data for the `materiales` table  (LIMIT 0,500)
#

INSERT INTO `materiales` (`cod_material`, `desc_material`, `url_descarga`, `autores`, `tamanio`, `fecha_creacion`, `cant_disponible`, `punto_pedido`, `cantidad_a_pedir`) VALUES
  ('AP-001','Introducción al Marketing','www.afatse.com.ar/apuntes?AP=001','Antonio Gramsci',2.5,'2012-08-01',0,NULL,NULL),
  ('AP-002','Estructura de la PC','www.afatse.com.ar/apuntes?AP=002','Juan Carlos Onetit',3,'2012-08-05',0,NULL,NULL),
  ('AP-003','Sectores de Mercado y Trageting','www.afatse.com.ar/apuntes?AP=003','Rafael Alberti',3.9,'2013-05-08',0,NULL,NULL),
  ('AP-004','Sistemas Operativos Modernos','www.afatse.com.ar/apuntes?AP=004','Andrew Tanembaum',4,'2013-11-27',0,NULL,NULL),
  ('AP-005','Redes','www.afatse.com.ar/apuntes?AP=005','Andrew Tanembaum',7.3,'2013-12-02',0,NULL,NULL),
  ('AP-006','Imagen y Competencia','www.afatse.com.ar/apuntes?AP=006','Rafael Muñiz Gonzales y Erica de Forifregoro',3,'2014-05-04',0,NULL,NULL),
  ('AP-007','Usuarios y Seguridad','www.afatse.com.ar/apuntes?AP=007','Andrew Tanembaum',6,'2014-02-08',0,NULL,NULL),
  ('AP-008','Utilidades de diagnostico','www.afatse.com.ar/apuntes?AP=008','Erica de Forifregoro',4,'2014-04-09',0,NULL,NULL),
  ('AP-009','Deteccion de hackers','www.afatse.com.ar/apuntes?AP=009','Erica de Forifregoro',5.7,'2014-05-17',0,NULL,NULL),
  ('UT-001','Birome',NULL,NULL,NULL,NULL,93,20,200),
  ('UT-002','Carpeta con metallas',NULL,NULL,NULL,NULL,7,15,100),
  ('UT-003','Hojas A4 lisas',NULL,NULL,NULL,NULL,5500,2000,5000),
  ('UT-004','Diskete 3 1/2',NULL,NULL,NULL,NULL,57,30,100);

COMMIT;

#
# Data for the `materiales_plan` table  (LIMIT 0,500)
#

INSERT INTO `materiales_plan` (`nom_plan`, `cod_material`, `cant_entrega`) VALUES
  ('Marketing 1','AP-001',0),
  ('Marketing 2','AP-003',0),
  ('Marketing 2','UT-001',1),
  ('Marketing 2','UT-002',1),
  ('Marketing 2','UT-003',20),
  ('Marketing 3','AP-006',0),
  ('Marketing 3','UT-001',1),
  ('Marketing 3','UT-002',1),
  ('Marketing 3','UT-003',20),
  ('Reparac PC Avanzada','AP-004',0),
  ('Reparac PC Avanzada','AP-005',0),
  ('Reparac PC Avanzada','AP-007',0),
  ('Reparac PC Avanzada','UT-001',1),
  ('Reparac PC Avanzada','UT-002',1),
  ('Reparac PC Avanzada','UT-003',20),
  ('Reparacion PC','AP-002',0),
  ('Reparacion PC','UT-001',1),
  ('Reparacion PC','UT-002',1),
  ('Reparacion PC','UT-003',20);

COMMIT;

#
# Data for the `proveedores` table  (LIMIT 0,500)
#

INSERT INTO `proveedores` (`cuit`, `razon_social`, `direccion`, `telefono`) VALUES
  ('11-11111111-1','Data Source','Nansen 1111','1111111'),
  ('22-22222222-2','Libreria REDAL','San Martin 2222','2222222'),
  ('33-33333333-3','LAEROB','Richieri 3333','3333333'),
  ('44-44444444-4','INSUBOX','Valparaiso 4444','4444444');

COMMIT;

#
# Data for the `proveedores_materiales` table  (LIMIT 0,500)
#

INSERT INTO `proveedores_materiales` (`cuit`, `cod_material`) VALUES
  ('22-22222222-2','UT-001'),
  ('33-33333333-3','UT-001'),
  ('22-22222222-2','UT-002'),
  ('33-33333333-3','UT-003'),
  ('11-11111111-1','UT-004'),
  ('44-44444444-4','UT-004');

COMMIT;

#
# Data for the `valores_plan` table  (LIMIT 0,500)
#

INSERT INTO `valores_plan` (`nom_plan`, `fecha_desde_plan`, `valor_plan`) VALUES
  ('Marketing 1','2013-01-05',25),
  ('Marketing 1','2013-06-01',28),
  ('Marketing 1','2014-02-01',30),
  ('Marketing 1','2014-04-01',37),
  ('Marketing 1','2014-06-01',45),
  ('Marketing 1','2014-08-01',54),
  ('Marketing 1','2014-12-01',65),
  ('Marketing 2','2014-02-01',50),
  ('Marketing 2','2014-04-01',60),
  ('Marketing 2','2014-06-01',73),
  ('Marketing 2','2014-08-01',88),
  ('Marketing 2','2015-01-02',60),
  ('Marketing 3','2015-01-02',200),
  ('Reparac PC Avanzada','2014-02-01',80),
  ('Reparac PC Avanzada','2014-04-01',95),
  ('Reparac PC Avanzada','2014-06-01',120),
  ('Reparac PC Avanzada','2014-08-01',145),
  ('Reparac PC Avanzada','2015-01-02',125),
  ('Reparac PC Avanzada','2015-04-01',135),
  ('Reparacion PC','2013-01-05',37),
  ('Reparacion PC','2013-06-01',42),
  ('Reparacion PC','2014-02-01',45),
  ('Reparacion PC','2014-04-01',54),
  ('Reparacion PC','2014-06-01',65),
  ('Reparacion PC','2014-08-01',80),
  ('Reparacion PC','2015-01-02',80);

COMMIT;


