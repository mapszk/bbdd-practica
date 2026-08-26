-- ============================================================
--  MIS SOLUCIONES - Práctica de Bases de Datos
--  Generado por Práctica SQL el 2026-08-02 16:07
--  ARCHIVO GENERADO: no editar a mano, se sobrescribe.
--  Resueltos: 0/132
-- ============================================================

-- ############################################################
-- #  PRÁCTICA 1 - Práctica Nº 1: Sentencia SELECT
-- #  BASE DE DATOS: AGENCIA_PERSONAL
-- #  (14 ejercicios)
-- ############################################################
USE agencia_personal;

-- ------------------------------------------------------------
-- 1.1) Mostrar la estructura de la tabla Empresas. Seleccionar toda la información de la misma.
-- ------------------------------------------------------------
select cuit, razon_social, direccion, telefono, ifnull(e_mail, "") "e_mail"
from empresas;

-- ------------------------------------------------------------
-- 1.2) Mostrar la estructura de la tabla Personas. Mostrar el apellido y nombre y la fecha de registro
--      en la agencia.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.3) Guardar el siguiente query en un archivo de extensión .sql, para luego correrlo. Mostrar los
--      títulos con el formato de columna: Código Descripción y Tipo ordenarlo alfabéticamente por
--      descripción.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.4) Mostrar de la persona con DNI nro. 28675888. El nombre y apellido, fecha de nacimiento,
--      teléfono, y su dirección. Las cabeceras de las columnas serán:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.5) Mostrar los datos de ej. Anterior, pero para las personas 27890765, 29345777 y 31345778.
--      Ordenadas por fecha de Nacimiento
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.6) Mostrar las personas cuyo apellido empiece con la letra ‘G’.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.7) Mostrar el nombre, apellido y fecha de nacimiento de las personas nacidas entre 1980 y 2000
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.8) Mostrar las solicitudes que hayan sido hechas alguna vez ordenados en forma ascendente por
--      fecha de solicitud.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.9) Mostrar los antecedentes laborales que aún no hayan terminado su relación laboral ordenados por
--      fecha desde.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.10) Mostrar aquellos antecedentes  laborales que finalizaron y cuya fecha hasta no esté entre junio
--      del 2013 a diciembre de 2013, ordenados por número de DNI del empleado.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.11) Mostrar los contratos cuyo salario sea mayor que 2000 y trabajen en las empresas 30-10504876-5
--      o 30-21098732-4.Rotule el encabezado:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.12) Mostrar los títulos técnicos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.13) Seleccionar las solicitudes cuya fecha sea mayor que ‘21/09/2013’ y el código de cargo sea 6;
--      o hayan solicitado aspirantes de sexo femenino
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 1.14) Seleccionar los contratos con un salario pactado mayor que 2000 y que no hayan sido terminado.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 2 - Práctica Nº 2: JOINS
-- #  BASE DE DATOS: AFATSE, AGENCIA_PERSONAL
-- #  (16 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 2.1) Mostrar del Contrato 5:  DNI, Apellido y Nombre de la persona contratada y el sueldo acordado
--      en el contrato.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.2) Q¿uiénes fueron contratados por la empresa Viejos Amigos o Tráigame Eso? Mostrar el DNI, número
--      de contrato, fecha de incorporación, fecha de solicitud en la agencia de los contratados y
--      fecha de caducidad (si no tiene fecha de caducidad colocar ‘Sin Fecha’). Ordenado por fecha de
--      incorporación y nombre de empresa.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.3) Listado de las solicitudes consignando razón social, dirección y e_mail de la empresa,
--      descripción del cargo solicitado y años de experiencia solicitados, ordenado por fecha d
--      solicitud y descripción de cargo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.4) ¿Listar todos los candidatos con título de bachiller o un título de educación no formal.
--      Mostrar nombre y apellido, descripción del título y DNI.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.5) Realizar el punto 4 sin mostrar el campo DNI pero para todos los títulos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.6) Empleados que no tengan referencias o hayan puesto de referencia a Armando Esteban Quito o
--      Felipe Rojas. Mostrarlos de la siguiente forma: Pérez, Juan tiene como referencia a Felipe
--      Rojas cuando trabajo en Constructora Gaia S.A
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.7) Seleccionar para la empresa Viejos amigos, fechas de solicitudes, descripción del cargo
--      solicitado y edad máxima  y mínima . Si no tiene edad mínima y máxima indicar “sin
--      especificar”. Encabezado:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.8) Mostrar los antecedentes de cada postulante:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.9) Mostrar todas las evaluaciones realizadas para cada solicitud ordenar en forma ascendente por
--      empresa y descendente por cargo:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.10) Listar las empresas solicitantes mostrando la razón social y fecha de cada solicitud, y
--      descripción del cargo solicitado. Si hay empresas no han solicitado que salga la leyenda: Sin
--      Solicitudes en la fecha y descripción del cargo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.11) Mostrar para todas las solicitudes la razón social de la empresa solicitante, el cargo y si se
--      hubiese realizado un contrato los datos de la(s) persona(s).
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.12) Mostrar para todas las solicitudes la razón social de la empresa solicitante, el cargo de las
--      solicitudes para las cuales no se haya realizado un contrato.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.13) Listar todos los cargos y para aquellos que hayan sido realizados (como antecedente) por alguna
--      persona indicar nombre y apellido de la persona y empresa donde lo ocupó.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.14) Indicar todos los instructores que tengan un supervisor. Mostrar:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.15) Ídem 14) pero para todos los instructores. Si no tiene supervisor mostrar esos campos en blanco
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 2.16) Ranking de Notas por Supervisor e Instructor. El ranking deberá indicar para cada supervisor
--      los instructores a su cargo y las notas de los exámenes que el instructor haya corregido en el
--      2014. Indicando los datos del supervisor , nombre y apellido del instructor, plan de
--      capacitación, curso, nombre y apellido del alumno, examen, fecha de evaluación y nota. En caso
--      de que no tenga instructor a cargo indicar espacios en blanco. Ordenado ascendente por nombre y
--      apellido de supervisor y descendente por fecha.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 3 - Práctica Nº 3: Funciones de presentación de datos
-- #  BASE DE DATOS: AGENCIA_PERSONAL
-- #  (5 ejercicios)
-- ############################################################
USE agencia_personal;

-- ------------------------------------------------------------
-- 3.1) Para aquellos contratos que no hayan terminado calcular la fecha de caducidad como la fecha de
--      solicitud más 30 días (no actualizar la base de datos). Función ADDDATE
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 3.2) Mostrar los contratos. Indicar nombre y apellido de la persona, razón social de la empresa
--      fecha de inicio del contrato y fecha de caducidad del contrato. Si la fecha no ha terminado
--      mostrar “Contrato Vigente”. Función IFNULL
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 3.3) Para aquellos contratos que terminaron antes de la fecha de finalización, indicar la cantidad
--      de días que finalizaron antes de tiempo. Función DATEDIFF
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 3.4) Emitir un listado de comisiones impagas para cobrar. Indicar cuit, razón social de la empresa y
--      dirección, año y mes de la comisión, importe y la fecha de vencimiento que se calcula como la
--      fecha actual más dos meses. Función ADDDATE con INTERVAL
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 3.5) Mostrar en qué día mes y año nacieron las personas (mostrarlos en columnas separadas) y sus
--      nombres y apellidos concatenados. Funciones DAY, YEAR, MONTH y CONCAT
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 4 - Practica Nº 4: GROUP BY - HAVING
-- #  BASE DE DATOS: AGENCIA_PERSONAL
-- #  (15 ejercicios)
-- ############################################################
USE agencia_personal;

-- ------------------------------------------------------------
-- 4.1) Mostrar la suma de las comisiones pagadas por la empresa Tráigame eso.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.2) Ídem 1) pero para todas las empresas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.3) Mostrar el promedio, desviación estándar y varianza del puntaje de las evaluaciones de
--      entrevistas, por tipo de evaluación y entrevistador. Ordenar por promedio en forma ascendente y
--      luego por desviación estándar en forma descendente.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.4) Ídem 3) pero para Angélica Doria, con promedio mayor a 71. Ordenar por código de evaluación.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.5) Cuantas entrevistas fueron hechas por cada entrevistador en octubre de 2014.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.6) Ídem 4) pero para todos los entrevistadores. Mostrar nombre y cantidad. Ordenado por cantidad
--      de entrevistas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.7) Ídem 6) para aquellos cuya cantidad de entrevistas por codigo de evaluacion sea myor mayor que
--      1. Ordenado por nombre en forma descendente y por codigo de evalucacion en forma ascendente
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.8) Mostrar para cada contrato cantidad total de las comisiones, cantidad a pagar, cantidad
--      pagadas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.9) Mostrar para cada contrato la cantidad de comisiones, el % de comisiones pagas y el % de
--      impagas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.10) Mostrar la cantidad de empresas diferentes que han realizado solicitudes y la diferencia
--      respecto al total de solicitudes.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.11) Cantidad de solicitudes por empresas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.12) Cantidad de solicitudes por empresas y cargos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.13) Listar las empresas, indicando todos sus datos y la cantidad de personas diferentes que han
--      mencionado dicha empresa como antecedente laboral. Si alguna empresa NO fue mencionada como
--      antecedente laboral deberá indicar 0 en la cantidad de personas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.14) Indicar para cada cargo la cantidad de veces que fue solicitado. Ordenado en forma descendente
--      por cantidad de solicitudes. Si un cargo nunca fue solicitado, mostrar 0.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 4.15) Indicar los cargos que hayan sido solicitados menos de 2 veces
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 5 - Practica Nº 5: Subconsultas, Tablas Temporales, CTE y Variables
-- #  BASE DE DATOS: AFATSE, AGENCIA_PERSONAL
-- #  (17 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 5.1) ¿Qué personas fueron contratadas por las mismas empresas que Stefanía Lopez?
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.2) Encontrar a aquellos empleados que ganan menos que el máximo sueldo de los empleados de Viejos
--      Amigos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.3) Mostrar empresas contratantes y sus promedios de comisiones pagadas o a pagar, pero sólo de
--      aquellas cuyo promedio supere al promedio de Tráigame eso.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.4) Seleccionar las comisiones pagadas que tengan un importe menor al promedio de todas las
--      comisiones(pagas y no pagas), mostrando razón social de la empresa contratante, mes contrato,
--      año contrato , nro. contrato, nombre y apellido del empleado.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.5) Determinar las empresas que en promedio van a pagar  la mayor de las comisiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.6) Seleccionar los empleados que no tengan educación no formal o terciario.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.7) Mostrar los empleados cuyo salario supere al promedio de sueldo de la empresa que los contrató.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.8) Determinar las empresas que pagaron en promedio la mayor o menor de  las comisiones
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.9) Alumnos que se  hayan inscripto a más cursos que Antoine de Saint-Exupery. Mostrar todos los
--      datos de los alumnos, la cantidad de cursos a la que se inscribió y cuantas veces más que
--      Antoine de Saint-Exupery.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.10) En el año 2014, qué cantidad de alumnos se han inscripto a los Planes de Capacitación indicando
--      para cada Plan de Capacitación la cantidad de alumnos inscriptos y el porcentaje que representa
--      respecto del total de inscriptos a los Planes de Capacitación dictados en el año.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.11) Indicar el valor actual de los planes de Capacitación
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.12) Plan de capacitacion mas barato. Indicar los datos del plan de capacitacion y el valor actual
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.13) ¿Qué instructores que han dictado algún curso del Plan de Capacitación “Marketing 1” el año
--      2014 y no vayan a dictarlo este año? (año 2015)
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.14) Alumnos que tengan todas sus cuotas pagas hasta la fecha.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.15) Alumnos cuyo promedio supere al del curso que realizan. Mostrar dni, nombre y apellido,
--      promedio y promedio del curso.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.16) Para conocer la disponibilidad de lugar en los cursos que empiezan en abril para lanzar una
--      campaña  se desea conocer la cantidad de alumnos inscriptos a los cursos que comienzan a partir
--      del 1/04/2014 indicando: Plan de Capacitación, curso, fecha de inicio, salón, cantidad de
--      alumnos inscriptos y diferencia con el cupo de alumnos registrado para el curso que tengan al
--      más del 80% de lugares disponibles respecto del cupo. Ayuda: tener en cuenta el uso de los
--      paréntesis y la precedencia de los operadores matemáticos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 5.17) Indicar el último incremento de los valores de los planes de capacitación, consignando nombre
--      del plan fecha del valor actual, fecha del valor anterior, valor actual, valor anterior y
--      diferencia entre los valores. Si el curso tiene un único valor mostrar la fecha anterior en
--      NULL el valor anterior en 0 y la diferencia a 0.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 6 - Práctica 6
-- #  BASE DE DATOS: AGENCIA_PERSONAL
-- #  (4 ejercicios)
-- ############################################################
USE agencia_personal;

-- ------------------------------------------------------------
-- 6.1) De las empresas registradas interesa tener un listado de personas que pueden operar como
--      contacto. Mostrar los datos de las empresas Solicitantes con contratos y empresas de
--      Antecedentes de personas. Indicar cuit, razón, dni de las personas contratadas y en caso que
--      sean empresas de antecedentes dni de personas que la indican como antecedente, nombre,
--      apellido, código de cargo, descripción del cargo y en la última columna agregar “Contrato” si
--      la persona fue contratado o “Antecedente” si la persona figura como antecedente. Mostrar
--      ordenado por razón.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 6.2) De las empresas registradas interesa la cantidad de personas que podemos tener como contacto
--      por haber sido contratadas y cantidad de personas que podemos tener como contacto por ser
--      registrada como antecedente. Mostrar también las empresas que no tienen personas como contacto
--      tanto en contratos como en antecedentes. Indicar el porcentaje que representa respecto al total
--      de personas que tenemos registradas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 6.3) Listar las empresas solicitantes mostrando la razón social y fecha de cada solicitud, y
--      descripción del cargo solicitado. Si hay empresas que no hayan solicitado que muestre la
--      leyenda: Sin Solicitudes en la fecha y en la descripción del cargo. Además mostrar todos los
--      cargos incluso los que no han sido solicitados nunca, en ese caso indicar en razón social y
--      fecha de solicitud la leyenda “Cargo no solicitado”
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 6.4) Listado de personas que hayan sido contratadas y que existan registradas también con sus
--      antecedentes. Si se repiten mostrarlas una sola vez.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 7 - Práctica Nº 7: Vistas
-- #  BASE DE DATOS: AFATSE
-- #  (5 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 7.1) De los instructores:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 7.2) De los cursos que se dictan este año(2015) indicar:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 7.3) De los cursos que se dictan este año (2015) indicar:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 7.4) De los alumnos, indicar para cada curso al que se ha inscripto:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 7.5) Crear una vista de útiles y una de apuntes, sólo con los datos específicos de dichos elementos.
--      Luego mostrar los útiles y todos los proveedores que los venden utilizando la vista y para cada
--      curso de este año mostrar los apuntes que se utilizan en los mismos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 8 - Práctica Nº 8: INSERT VALUES, UPDATE, DELETE y TRUNCATE
-- #  BASE DE DATOS: AFATSE
-- #  (13 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 8.1) Agregar el nuevo instructor Daniel Tapia con cuil: 44-44444444-4, teléfono: 444-444444, email:
--      dotapia@gmail.com, dirección Ayacucho 4444 y sin supervisor.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.2) Ingresar un nuevo plan de capacitación con sus datos, costo, temas, exámenes y materiales:
--      Plan: Nombre: Administrador de BD, descripción: Instalación y configuración MySQL. Lenguaje
--      SQL. Usuarios y permisos, de 300 hs con modalidad presencial Temas: 4 Exámenes: 4 Materiales
--      Existentes que entrega: Código UT-001, UT-002, UT-003 y UT-004 Nuevos Materiales: Valor: $ 150
--      desde el 01/02/2009
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.3) Como resultado de una mudanza a otro edificio más grande se ha incrementado la capacidad de los
--      salones, además la experiencia que han adquirido los instructores permite ampliar el cupo de
--      los cursos. Para todos los curso con modalidad presencial y semipresencial aumentar el cupo de
--      la siguiente forma: - 50% para los cursos con cupo menor a 20 - 25% para los cursos con cupo
--      mayor o igual a 20
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.4) Convertir a Daniel Tapia en el supervisor de Henri Amiel y Franz Kafka. Utilizar el cuil de
--      cada uno.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.5) Ídem 4) pero utilizar variables para obtener el cuil de los 3 instructores.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.6) El alumno Victor Hugo se ha mudado. Actualizar su dirección a Italia 2323 y su teléfono nuevo
--      es 3232323.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.7) Eliminar el plan creado en la consulta 2). Ayuda: Tener en cuenta las CF para poder eliminarlo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.8) Eliminar los nuevos apuntes AP-008 y AP-009. Ayuda: Tener en cuenta las CF para poder
--      eliminarlo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.9) Eliminar al instructor Daniel Tapia. Ayuda: Tener en cuenta las CF para poder eliminarlo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.10) Eliminar los inscriptos al curso de Marketing 3 curso numero 1.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.11) Eliminar los instructores que tienen de supervisor a Elias Yanes (CUIL 99-99999999-9)
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.12) Ídem 11) pero usar una variable para obtener el CUIL de Elias Yanes.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 8.13) Eliminar todos los apuntes que tengan como autora o coautora a Erica de Forifregoro
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 9 - Práctica Nº 9: INSERT SELECT, UPDATE y DELETE con JOINS
-- #  BASE DE DATOS: AFATSE
-- #  (7 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 9.1) Crear una nueva lista de precios para todos los planes de capacitación, a partir del 01/06/2009
--      con un 20 por ciento más que su último valor. Eliminar las filas agregadas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.2) Crear una nueva lista de precios para todos los planes de capacitación, a partir del
--      01/08/2009, con la siguiente regla: Los cursos cuyo último valor sea menor a $90 aumentarlos en
--      un 20% al resto aumentarlos un 12%.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.3) Crear un nuevo plan: Marketing 1 Presen. Con los mismos datos que el plan Marketing 1 pero con
--      modalidad presencial. Este plan tendrá los mismos temas, exámenes y materiales que Marketing 1
--      pero con un costo un 50% superior, para todos los períodos de este año que ya estén definidos
--      costos del plan.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.4) Cambiar el supervisor de aquellos instructores que dictan Reparac PC Avanzada este año a
--      66-66666666-6 (Franz Kafka).
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.5) Cambiar el horario de los cursos de que dicta este año Franz Kafka (cuil ) desde las 16 hs.
--      Moverlos una hora más temprano.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.6) Eliminar los exámenes donde el promedio general de las evaluaciones sea menor a 5.5. Eliminar
--      también los temas que sólo se evalúan en esos exámenes. Ayuda: Usar una tabla temporal para
--      determinar el/los exámenes que cumplan en las condiciones y utilizar dichas tabla para los
--      joins. Tener en cuenta las CF para poder eliminarlos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 9.7) Eliminar las inscripciones a los cursos de este año de los alumnos que adeuden cuotas impagas
--      del año pasado.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 10 - Práctica Nº 10: DCL
-- #  BASE DE DATOS: AGENCIA_PERSONAL
-- #  (7 ejercicios)
-- ############################################################
USE agencia_personal;

-- ------------------------------------------------------------
-- 10.1) Crear el usuario ‘usuario’ con contraseña ‘entre’.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.2) Cambiar la contraseña de usuario a ‘entrar’
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.3) Darle permisos a usuario para realizar SELECT de todas las tablas de AGENCIA_PERSONAL.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.4) Darle permisos al usuario para realizar (INSERT, UPDATE y DELETE) los datos de la tabla
--      PERSONAS.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.5) Quitarle todos los permisos a usuario.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.6) Darle permisos a usuario de realizar SELECT, INSERT y UPDATE sobre la vista vw_contratos.
--      Analizar: La vista vw_contratos NO posee las columnas de sueldo y comisión. De esta forma se
--      permite que distintos usuarios puedan acceder a los datos específicos que pueden y evitar que
--      accedan a datos que no deberían. La vista por ser simple permite realizar inserciones,
--      actualizaciones y eliminaciones. De esta forma para que un grupo de usuario no acceda a
--      determinadas columnas y a otras si, el sistema de vistas permite un forma sencilla de gestionar
--      los permisos en comparación con dar permisos por columna y en caso de tener que cambiar las
--      columnas que pueden ver y modificar sólo debe modificarse la vista y todos los usuarios que
--      tienen acceso a esa vista tendrán automáticamente el cambio en las columnas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 10.7) Quitarle a usuario todos los permisos.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 11 - Práctica Nº 11: TCL
-- #  BASE DE DATOS: AFATSE
-- #  (13 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 11.1) Ejecute SET AUTOCOMMIT=1; en la conexión principal. Esta propiedad indica que cualquier
--      sentencia que ejecute realizará un COMMIT automático. Está así por defecto
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.2) (sin consigna)
--   a. Crear un nuevo alumno e inscribirlo a Marketing 3 curso nro. 1 sin utilizar START
--      TRANSACTION.
--   b. Desde la misma conexión listar los alumnos y las inscripciones del nuevo alumno.
--      PRECAUCION: NO utilizar el diseñador gráfico de tablas.
--   c. Desde conexión  secundaria listar los alumnos y las inscripciones del nuevo alumno.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.3) (sin consigna)
--   a. Eliminar la inscripción y el alumno creados en 2) sin utilizar START TRANSACTION.
--   b. Desde la misma conexión listar los alumnos y las inscripciones del nuevo alumno.
--      PRECAUCION: NO utilizar el diseñador gráfico de tablas.
--   c. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--      Estando seteada la propiedad de AUTOCOMMIT en 1 las sentencias se ejecutan con COMMIT
--      implícito al finalizar cada una sin permitir ejecutar varias sentencias en una sola
--      transacción. Mientras esta propiedad se encuentre en 1 la única forma de ejecutar varias
--      sentencias dentro de una única transacción es indicar explícitamente que se va a comenzar
--      una transacción. Esto se hace con la sentencia START TRANSACTION;
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.4) (sin consigna)
--   a. Crear un nuevo alumno e inscribirlo a Marketing 3 curso nro. 1 utilizando START
--      TRANSACTION.
--   b. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   c. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   d. Luego desde la conexión principal ejecutar ROLLBACK. Volver a probar en ambas conexiones.
--      La sentencia ROLLBACK deshace los cambios pendientes de la transacción (Desde el START
--      TRANSACTION.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.5) (sin consigna)
--   a. Crear un nuevo alumno e inscribirlo a Marketing 3 curso nro. 1 utilizando START
--      TRANSACTION.
--   b. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   c. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   d. Luego desde la conexión principal ejecutar COMMIT. Volver a probar en ambas conexiones. La
--      sentencia COMMIT confirma los cambios pendientes en la transacción desde el START
--      TRANSACTION
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.6) (sin consigna)
--   a. Eliminar la inscripción y el alumno creados en 4) utilizando START TRANSACTION.
--   b. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   c. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   d. Luego desde la conexión principal ejecutar ROLLBACK. Volver a probar en ambas conexiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.7) (sin consigna)
--   a. Eliminar la inscripción y el alumno creados en 4) utilizando START TRANSACTION.
--   b. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   c. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   d. Luego desde la conexión principal ejecutar COMMIT. Volver a probar en ambas conexiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.8) (sin consigna)
--   a. Ejecutar la sentencia SET AUTOCOMMIT=0;
--   b. Repetir los apartados 2) y 3).
--   c. Ejecutar la sentencia COMMIT; Con AUTOCOMMIT en 0 las sentencias requieren un COMMIT
--      EXPLICITO por lo tanto todas las sentencias se ejecutan en una misma transacción. Con
--      AUTOCOMMIT en 0, al ejecutar una sentencia COMMIT o ROLLBACK se confirman o revierten
--      respectivamente las sentencias pendientes. Luego al ejecutar cualquier sentencia de
--      modificación de datos se inicia una nueva transacción.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.9) (sin consigna)
--   a. Ejecutar START TRANSACTION;
--   b. Crear un nuevo alumno.
--   c. Ejecutar SAVEPOINT alumno;
--   d. Inscribirlo a Marketing 3 curso nro. 1 utilizando.
--   e. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   f. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   g. Ejecutar ROLLBACK TO alumno;
--   h. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   i. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   j. Luego desde la conexión principal ejecutar ROLLBACK. Volver a probar en ambas conexiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.10) (sin consigna)
--   a. Ejecutar START TRANSACTION;
--   b. Crear un nuevo alumno.
--   c. Ejecutar SAVEPOINT alumno;
--   d. Inscribirlo a Marketing 3 curso nro. 1 utilizando.
--   e. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   f. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   g. Ejecutar ROLLBACK TO alumno;
--   h. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   i. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   j. Luego desde la conexión principal ejecutar COMMIT. Volver a probar en ambas conexiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.11) Eliminar el alumno creado.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.12) (sin consigna)
--   a. Ejecutar START TRANSACTION;
--   b. Crear un nuevo alumno.
--   c. Ejecutar SAVEPOINT alumno;
--   d. Inscribirlo a Marketing 3 curso nro. 1 utilizando.
--   e. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   f. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   g. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   h. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   i. Luego desde la conexión principal ejecutar ROLLBACK. Volver a probar en ambas conexiones.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 11.13) (sin consigna)
--   a. Ejecutar START TRANSACTION;
--   b. Crear un nuevo alumno.
--   c. Ejecutar SAVEPOINT alumno;
--   d. Inscribirlo a Marketing 3 curso nro. 1 utilizando.
--   e. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   f. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   g. Desde la misma conexión los alumnos y las inscripciones del nuevo alumno. PRECAUCION: NO
--      utilizar el diseñador gráfico de tablas.
--   h. Desde la conexión secundaria listar los alumnos y las inscripciones del nuevo alumno.
--   i. Luego desde la conexión principal ejecutar COMMIT. Volver a probar en ambas conexiones.
--      SAVEPOINT, como su nombre lo indica es un punto donde se guarda el estado de la
--      transacción para permitir volver a dicho punto con la sentencia ROLLBACK TO  permite
--      volver a al SAVEPOINT cuyo nombre se indicó. Los datos vuelven al valor que tenían al
--      crear el SAVEPOINT. Se pueden crear tantos SAVEPOINT como se desee y se puede volver a
--      cualquiera de los creados. Una vez que se realiza un ROLLBACK TO todos los SAVEPOINT
--      creados después del indicado son eliminados. Si se ejecuta la sentencia COMMIT o ROLLBACK
--      (sin especificar en nombre del SAVEPOINT) los cambios se aplican o revierten
--      (respectivamente) desde el START TRANSACTION hasta el final y todos los SAVEPOINT de dicha
--      transacción son eliminados. Si se desea eliminar un SAVEPOINT para no volver a ese punto o
--      para reutilizar su nombre nuevamente se puede utilizar la sentencia RELEASE SAVEPOINT
--      nombre_savepoint;
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 12 - Práctica Nº 12: STORE PROCEDURES y FUNCTIONS
-- #  BASE DE DATOS: AFATSE
-- #  (12 ejercicios)
-- ############################################################
USE afatse;

-- ------------------------------------------------------------
-- 12.1) Crear un procedimiento almacenado llamado plan_lista_precios_actual que devuelva los planes de
--      capacitación indicando:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.2) Crear un procedimiento almacenado llamado plan_lista_precios_a_fecha que dada una fecha
--      devuelva los planes de capacitación indicando:
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.3) Modificar el procedimiento almacenado creado en 1) para que internamente invoque al
--      procedimiento creado en 2).
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.4) Crear una función llamada plan_valor que reciba el nombre del plan y una fecha y devuelva el
--      valor de dicho plan a esa fecha.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.5) Modifique el procedimiento almacenado creado en 2) para que internamente utilice la función
--      creada en 4).
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.6) Crear un procedimiento almacenado llamado alumnos_pagos_deudas_a_fecha que dada una fecha y un
--      alumno indique cuanto ha pagado hasta esa fecha y cuantas cuotas adeudaba a dicha fecha (cuotas
--      emitidas y no pagadas). Devolver los resultados en parámetros de salida.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.7) Crear una función llamada alumnos_deudas_a_fecha que dado un alumno y una fecha indique cuantas
--      cuotas adeuda a la fecha.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.8) Crear un procedimiento almacenado llamado alumno_inscripcion que dados los datos de un alumno y
--      un curso lo inscriba en dicho curso el día de hoy y genere la primera cuota con fecha de
--      emisión hoy para el mes próximo.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.9) Modificar el procedimiento almacenado creado en 8) para que antes de inscribir a un alumno
--      valide que el mismo no esté ya inscripto.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.10) Modificar el procedimiento almacenado editado en 9) para que realice el proceso en una
--      transacción. Además luego de inscribirlo y generar la cuota verificar si la cantidad de
--      inscriptos supera el cupo, en ese caso realizar un ROLLBACK. Si la cantidad de inscriptos es
--      correcta ejecutar un COMMIT
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.11) Crear dos procedimientos almacenados, aplicando conceptos de reutilización de código:
--      stock_ingreso dado el código de material y la cantidad ingresada (número positivo) que realice
--      un ingreso de mercadería. stock_egreso dado el código de material y la cantidad egresada
--      (número positivo) que realice un egreso de mercadería. Ambos procedimiento deberán devolver la
--      cantidad restante en stock. Realizar las validaciones pertinentes. Solución: Crear un
--      procedimiento almacenado llamado stock_movimiento que reciba el código de un material y la
--      cantidad del movimiento (si la cantidad es positiva es un ingreso de mercadería y si es
--      negativa es un egreso). El procedimiento debe (dentro de una transacción) validar que se trate
--      de un útil y no de un apunte y si luego de modificar las cantidades la misma resultara en un
--      valor menor a 0 hacer ROLLBACK. El mismo deberá devolver la cantidad restante de stock ya sea
--      que se haya descontado o no. Los procedimientos solicitados invocan a stock_movimiento.
--      stock_egreso previamente invierte el signo de la cantidad a modificar. ¿Por qué se realiza el
--      UPDATE de la cantidad y se controla luego que la cantidad restante sea mayor a 0 y no antes?
--      Porque la sentencia UPDATE bloquea registros mientras que la SELECT no. Por lo tanto si de un
--      determinado material quedan en stock 10 elementos y el usuario A quiere descontar 8 y un
--      usuario B quiere descontar 5, realizando la actualización casi simultáneamente. Si ambos
--      realizaran primero el SELECT vería que la cantidad restante es suficiente, entonces ejecutarían
--      los UPDATE en secuencia descontarían en total 13 elementos de sólo 10 disponibles. En cambio al
--      realizar el UPDATE primero el registro es bloqueado y el UPDATE del segundo usuario deberá
--      esperar hasta que el del primero termine. Entonces al finalizar el segundo UPDATE la cantidad
--      restante será -3 entonces realizará el ROLLBACK.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 12.12) Crear un procedimiento almacenado llamado alumno_anula_inscripcion que elimine la inscripción
--      del alumno. El mismo deberá tener en cuenta que el alumno no haya pagado ninguna cuota antes de
--      eliminarlo. Si hay cuotas ya generadas pero impagas las mismas deberán ser eliminadas.
-- ------------------------------------------------------------
-- (sin resolver)

-- ############################################################
-- #  PRÁCTICA 13 - Práctica Nº 11: TRIGGERS
-- #  (4 ejercicios)
-- ############################################################

-- ------------------------------------------------------------
-- 13.1) (sin consigna)
--   a. Crear una tabla para registrar el histórico de cambios en los datos de los alumnos con el
--      siguiente script: CREATE TABLE `alumnos_historico` ( `dni` int(11) NOT NULL,
--      `fecha_hora_cambio` datetime NOT NULL, `nombre` varchar(20) default NULL, `apellido`
--      varchar(20) default NULL, `tel` varchar(20) default NULL, `email` varchar(50) default
--      NULL, `direccion` varchar(50) default NULL, `usuario_modificacion` varchar(50) default
--      NULL, PRIMARY KEY  (`dni`,`fecha_hora_cambio`), CONSTRAINT `alumnos_historico_alumnos_fk`
--      FOREIGN KEY (`dni`) REFERENCES `alumnos` (`dni`) ON UPDATE CASCADE ) ENGINE=InnoDB DEFAULT
--      CHARSET=utf8;
--   b. Luego crear TRIGGERS para insertar los nuevos valores en archivo_historico cuando los
--      alumnos sean ingresados o sus datos sean modificados. Registrar la fecha y hora actual con
--      CURRENT_TIMESTAMP y el usuario actual con CURRENT_USER.
--   c. Probarlo ejecutando INSERTS y UPDATES dentro de transacciones. Probar con ROLLBACK y luego
--      con COMMIT.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 13.2) (sin consigna)
--   a. Crear la tabla stock_movimientos para registrar las cambios en las existencias de
--      artículos con el siguiente script: CREATE TABLE `stock_movimientos` ( `cod_material`
--      char(6) NOT NULL, `fecha_movimiento` timestamp NOT NULL default CURRENT_TIMESTAMP on
--      update CURRENT_TIMESTAMP, `cantidad_movida` int(11) NOT NULL, `cantidad_restante` int(11)
--      NOT NULL, `usuario_movimiento` varchar(50) NOT NULL, PRIMARY KEY
--      (`cod_material`,`fecha_movimiento`), CONSTRAINT `stock_movimientos_fk` FOREIGN KEY
--      (`cod_material`) REFERENCES `materiales` (`cod_material`) ON UPDATE CASCADE )
--      ENGINE=InnoDB DEFAULT CHARSET=utf8; Aclaración: En este caso utilizamos el tipo de datos
--      timestamp en lugar de datetime para registrar la fecha y hora de la modificación. En el
--      ejercicio anterior utilizamos el tipo de dato datetime pero entonces debemos registrar el
--      dato a nosotros (en ese caso lo hicimos con CURRENT_TIMESTAMP). En los casos donde
--      queremos hacer históricos o asegurarnos de que se registra el momento exacto en que se
--      inserta un dato es mejor utilizar el tipo de dato timestamp que hace esto automáticamente
--      pero en los INSERT que realicemos sobre las tablas con estos datos deberemos omitir este
--      campo.
--   b. Crear TRIGGERS para registrar los movimientos en las cantidades de los materiales en la
--      tabla del histórico. En el caso de un nuevo material se debe registrar la cantidad inicial
--      como la cantidad movida y SÓLO en el caso de un cambio en la cantidad registrar el cambio.
--   c. Probarlo ejecutando INSERTS y UPDATES dentro de transacciones. Probar con ROLLBACK y luego
--      con COMMIT.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 13.3) (sin consigna)
--   a. Modificar la tabla cursos, agregarle una columna llamada cant_inscriptos que será un
--      atributo calculado de la cantidad de inscriptos al curso con el siguiente script: alter
--      table `cursos` add column cant_inscriptos int(11) default null;
--   b. Completar el campo con la cantidad actual de inscriptos con el script: START TRANSACTION;
--      drop temporary table if exists insc_curso; create temporary table insc_curso select
--      c.`nom_plan`, c.`nro_curso`, count(i.`nro_curso`) cant from cursos c left join
--      `inscripciones` i on c.`nom_plan`=i.`nom_plan` and c.`nro_curso`=i.`nro_curso` group by
--      c.`nom_plan`,c.`nro_curso`; update cursos c inner join insc_curso ic on
--      c.`nom_plan`=ic.`nom_plan` and c.`nro_curso`=ic.`nro_curso` set
--      c.`cant_inscriptos`=ic.cant; commit;
--   c. Hacer obligatorio el campo cant_inscriptos con el script: alter table `cursos` modify
--      cant_inscriptos int(11) not null;
--   d. Crear los TRIGGERS necesarios para actualizar la cantidad de inscriptos del curso, los
--      mismos deberán dispararse al inscribir un nuevo alumno y al eliminar una inscripción.
--   e. Probarlo inscribiendo y anulando inscripciones dentro de transacciones. Realizar las
--      pruebas con ROLLBACK y con COMMIT.
-- ------------------------------------------------------------
-- (sin resolver)

-- ------------------------------------------------------------
-- 13.4) (sin consigna)
--   a. Agregar la columna usuario_alta a la tabla valores_plan con el siguiente script: alter
--      table `valores_plan` add column usuario_alta varchar(50);
--   b. Crear un TRIGGER que una vez insertado el nuevo precio registre el usuario que lo ingresó.
--   c. Probar el TRIGGER dentro de una transacción. Realizar las pruebas con ROLLABACK y COMMIT.
-- ------------------------------------------------------------
-- (sin resolver)

