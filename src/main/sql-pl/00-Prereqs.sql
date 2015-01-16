--#SET TERMINATOR @

/*
 This file is part of db2unit: A unit testing framework for DB2 LUW.
 Copyright (C)  2014  Andres Gomez Casanova (@AngocA)

 db2unit is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 db2unit is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 Andres Gomez Casanova <angocaATyahooDOTcom>
*/

/**
 * Checks prerequisites.
 * dib dob: Set compilation environment for compiled SQL PL routines.
 *
 * Version: 2014-05-08 V2_BETA
 * Author: Andres Gomez Casanova (AngocA)
 * Author: Robert Mala (dib dob)
 */

BEGIN
 DECLARE LOGGER_ID SMALLINT;
 DECLARE EXIST INT;
 DECLARE STEP SMALLINT DEFAULT 0;
 DECLARE VERSION_DATE DATE;
 DECLARE MESSAGE VARCHAR(70);
 DECLARE CONT BOOLEAN DEFAULT TRUE;
 DECLARE SENTENCE VARCHAR(256); -- Dynamic statement to execute.
 DECLARE STMT STATEMENT; -- Statement to execute.

 SET STEP = 1;
 -- Checks log4db2 module in schema for Beta version.
 SELECT COUNT(1) INTO EXIST
   FROM SYSCAT.MODULES
   WHERE MODULESCHEMA LIKE 'LOGGER_%'
   AND MODULENAME = 'LOGGER';
 IF (EXIST >= 1) THEN
  SET STEP = 2;
  -- Checks log4db2 module as public.
  SELECT COUNT(1) INTO EXIST
    FROM SYSCAT.MODULES
    WHERE MODULESCHEMA = 'SYSPUBLIC'
    AND MODULENAME = 'LOGGER'
    AND BASE_MODULESCHEMA LIKE 'LOGGER_%'
    AND BASE_MODULENAME = 'LOGGER';
 ELSE
  SET CONT = FALSE;
 END IF;
 IF (CONT = TRUE AND EXIST >= 1) THEN
  SET STEP = 3;
  -- Checks log procedure in module.
  SELECT COUNT(1) INTO EXIST
    FROM SYSCAT.MODULEOBJECTS
    WHERE OBJECTSCHEMA LIKE 'LOGGER_%'
    AND OBJECTMODULENAME = 'LOGGER'
    AND OBJECTNAME = 'LOG'
    AND OBJECTTYPE = 'PROCEDURE'
    AND PUBLISHED = 'Y';
 ELSE
  SET CONT = FALSE;
 END IF;
 IF (CONT = TRUE AND EXIST >= 1) THEN
  SET STEP = 4;
  -- Checks getLogger procedure in module.
  SELECT COUNT(1) INTO EXIST
    FROM SYSCAT.MODULEOBJECTS
    WHERE OBJECTSCHEMA LIKE 'LOGGER_%'
    AND OBJECTMODULENAME = 'LOGGER'
    AND OBJECTNAME = 'GET_LOGGER'
    AND OBJECTTYPE = 'PROCEDURE'
    AND PUBLISHED = 'Y';
 ELSE
  SET CONT = FALSE;
 END IF;
 IF (CONT = TRUE AND EXIST >= 1) THEN
   SET STEP = 5;
  -- Get current log4db2 date version.
  BEGIN
   DECLARE OLD_VERSION_NOT_FOUND CONDITION FOR SQLSTATE '42703';
   DECLARE CONTINUE HANDLER FOR OLD_VERSION_NOT_FOUND
     BEGIN
      SET SENTENCE = 'SET ? = SUBSTR(LOGADMIN.VERSION, 1, 10)';
      PREPARE STMT FROM SENTENCE;
      EXECUTE STMT INTO VERSION_DATE;
     END;

   SET SENTENCE = 'SET ? = SUBSTR(LOGGER.VERSION, 1, 10)';
   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT INTO VERSION_DATE;
  END;
  IF (VERSION_DATE < '2014-04-21') THEN
   SET CONT = FALSE;
  END IF;
 END IF;
 IF (CONT = TRUE) THEN
  SET STEP = 6;
  -- Executes the logger methods in order to check them.
  SET SENTENCE = 'CALL LOGGER.GET_LOGGER(''DB2UNIT_2_BETA'', ?)';
  PREPARE STMT FROM SENTENCE;
  EXECUTE STMT INTO LOGGER_ID;

  SET SENTENCE = 'CALL LOGGER.DEBUG(?, ''db2unit installation test'')';
  PREPARE STMT FROM SENTENCE;
  EXECUTE STMT USING LOGGER_ID;
 END IF;
 -- Checks if any step failed.
 IF (CONT = FALSE) THEN
  SET MESSAGE = 'log4db2 is not installed. Step ' || STEP;
  SIGNAL SQLSTATE 'DUIN1' SET MESSAGE_TEXT = MESSAGE;
 END IF;
END @

/**
 * Set compilation environment for compiled sql/pl routines.
 *
 * Version: 2014-05-08 V2_BETA
 * Author: Robert Mala.
 */

/**
 * Returns the version of db2 as an integer.
 *
 * OUT VERSION_NUMBER
 *   Version of db2 as an integer.
 */
CREATE OR REPLACE PROCEDURE DB2UNIT.DB_VERSION(
  OUT VERSION_NUMBER INTEGER
)
  LANGUAGE SQL
  SPECIFIC P_DB_VERSION
  MODIFIES SQL DATA
  DETERMINISTIC
 P_DB_VERSION: BEGIN
  DECLARE VERSION, COMPATIBILITY VARCHAR(1024);
  DECLARE STRING VARCHAR(8) DEFAULT '';
  DECLARE P, PP INTEGER DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN END; -- Mask exceptions

  PREPARE S1 FROM 'CALL DBMS_UTILITY.DB_VERSION(?, ?)'; -- Prepare call
  EXECUTE S1 INTO VERSION, COMPATIBILITY; -- Get version

  SET VERSION = UPPER(VERSION);

  IF (VERSION LIKE 'DB2 V%.%.%.%') THEN
    SET VERSION = SUBSTR(VERSION, LOCATE_IN_STRING(VERSION, 'V', 1) + 1); -- Remove leading characters
    SET P = LOCATE_IN_STRING(VERSION, '.', 1); -- Find first period
    WHILE (P > 0) DO
      SET STRING = STRING || RIGHT('0'
        || SUBSTR( VERSION, (PP + 1), (P - PP - 1) ), 2); -- Extract current element
      SET PP = P; -- Reset pp
      SET P = LOCATE_IN_STRING(VERSION, '.', P + 1); -- Find next period
    END WHILE; -- Elements remain
    SET STRING = STRING || RIGHT('0' || SUBSTR(VERSION, (PP + 1) ), 2); -- Extract last element
  END IF ; -- Valid format

  SET VERSION_NUMBER = INTEGER(STRING); -- cast to integer
 END P_DB_VERSION @

-- Set current SQL_CCFLAGS register.
BEGIN
 DECLARE VERSION_NUMBER INTEGER;
 DECLARE CURRENT_SQL_CCFLAGS VARCHAR(1024);

 SET CURRENT_SQL_CCFLAGS = CURRENT SQL_CCFLAGS;

 CALL DB2UNIT.DB_VERSION(VERSION_NUMBER);

 IF (CURRENT_SQL_CCFLAGS NOT LIKE '%VERSION:%') THEN
  SET CURRENT_SQL_CCFLAGS = CURRENT_SQL_CCFLAGS || ',VERSION:'
    || VERSION_NUMBER;
 END IF;

 CASE
 WHEN (VERSION_NUMBER <= 10010000) THEN
  IF CURRENT_SQL_CCFLAGS NOT LIKE '%SQLSTATE_429BB:%' THEN
   SET CURRENT_SQL_CCFLAGS = CURRENT_SQL_CCFLAGS || ',SQLSTATE_429BB:TRUE';
  END IF;
 ELSE
 END CASE;

 IF (LEFT(CURRENT_SQL_CCFLAGS, 1) = ',') THEN
  SET CURRENT_SQL_CCFLAGS = SUBSTR(CURRENT_SQL_CCFLAGS, 2);
 END IF;

 SET CURRENT SQL_CCFLAGS = CURRENT_SQL_CCFLAGS;
END@

