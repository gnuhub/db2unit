--#SET TERMINATOR @

/*
Copyright (c) 2014-2014 Andres Gomez Casanova (AngocA).

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html -->

Contributors:
Andres Gomez Casanova - initial API and implementation.
*/

SET CURRENT SCHEMA DB2UNIT_1A @

/**
 * Adds the routine's implementation.
 *
 * Version: 2014-04-30 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

/**
 * Constant for the name of the report's table.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE REPORTS_TABLE VARCHAR(16) CONSTANT 'REPORT_TESTS' @

/**
 * ID of the current execution.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID @

/**
 * Current schema being tested.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE CUR_SCHEMA ANCHOR SYSCAT.TABLES.TABSCHEMA @

/**
 * Current test being executed.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE TESTNAME ANCHOR SYSCAT.PROCEDURES.PROCNAME @

/**
 * Array of procedure's names.
 */
ALTER MODULE DB2UNIT ADD
  TYPE PROCS_NAMES_TYPE AS ANCHOR SYSCAT.PROCEDURES.PROCNAME ARRAY [] @

/**
 * Write a message in the tests' report.
 *
 * IN MSG
 *   Message to insert in the report.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE WRITE_IN_REPORT (
  IN MSG VARCHAR(256)
  )
  LANGUAGE SQL
  SPECIFIC P_WRITE_IN_REPORT
  DYNAMIC RESULT SETS 0
  --AUTONOMOUS -- Autonomous transactions, it means it writes anyway.
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WRITE_IN_REPORT: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SENTENCE VARCHAR(1024); -- Dynamic statement to execute.
  DECLARE STMT STATEMENT; -- Statement to execute.

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.WRITE_IN_REPORT', LOGGER_ID);

  CALL LOGGER.DEBUG(LOGGER_ID, '>' || COALESCE(MSG, ''));
  CALL LOGGER.DEBUG(LOGGER_ID, 'Schema ' || CUR_SCHEMA);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Report ' || REPORTS_TABLE);
  CALL LOGGER.DEBUG(LOGGER_ID, 'ExecId ' || EXEC_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'TestName ' || COALESCE(TESTNAME, 'NoTestName'));
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message ' || MSG);

  IF (CUR_SCHEMA IS NULL OR REPORTS_TABLE IS NULL) THEN
   IF (EXEC_ID IS NULL) THEN
    SET EXEC_ID = -1;
   END IF;
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE) VALUES (
     CURRENT TIMESTAMP, EXEC_ID, -1, 'Invalid parameters');
  ELSE
   SET SENTENCE = 'INSERT INTO ' || CUR_SCHEMA || '.' || REPORTS_TABLE 
     || ' (DATE, EXECUTION_ID, TEST_NAME, MESSAGE) VALUES ('
     || 'CURRENT TIMESTAMP, ' || COALESCE(EXEC_ID, -1) || ', '''
     || COALESCE(TESTNAME, '') || ''', ''' || COALESCE(MSG, 'NULL') || ''')';

   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT;
  END IF;

  CALL LOGGER.DEBUG(LOGGER_ID, '<');
 END P_WRITE_IN_REPORT @

/**
 * Execute a procedure without parameters.
 *
 * IN PROC_NAME
 *   Name of the stored procedure.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXEC_PROCEDURE (
  IN PROC_NAME VARCHAR(256)
  )
  LANGUAGE SQL
  SPECIFIC P_EXEC_PROCEDURE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXEC_PROCEDURE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE MSG_TEXT VARCHAR(32672); -- Message from signal.
  DECLARE SENTENCE VARCHAR(1024); -- Dynamic statement to execute.
  DECLARE INEXISTENT CONDITION FOR SQLSTATE '42884';
  DECLARE STMT STATEMENT; -- Statement to execute.
  -- If the procedure does not exist, then exist without any message.
  DECLARE EXIT HANDLER FOR INEXISTENT SET SENTENCE = '';
  -- Logs any exception or warning.
  DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     CALL WRITE_IN_REPORT(
     'Warning: SQLCode' || COALESCE(SQLCODE, -1) || '-SQLState'
     || COALESCE(SQLSTATE, 'EMPTY') || '-' || COALESCE(MSG_TEXT, 'No message'));
    END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     CALL WRITE_IN_REPORT(
     'Exception: SQLCode' || COALESCE(SQLCODE, -1) || '-SQLState'
     || COALESCE(SQLSTATE, 'EMPTY') || '-' || COALESCE(MSG_TEXT, 'No message'));
    END;
  DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     CALL WRITE_IN_REPORT(
     'Not found: SQLCode' || COALESCE(SQLCODE, -1) || '-SQLState'
     || COALESCE(SQLSTATE, 'EMPTY') || '-' || COALESCE(MSG_TEXT, 'No message'));
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.EXEC_PROCEDURE', LOGGER_ID);
  CALL LOGGER.INFO(LOGGER_ID, '>' || COALESCE(PROC_NAME, 'NoName'));

  SET SENTENCE = 'CALL ' || CUR_SCHEMA || '.' || PROC_NAME || '()';
  PREPARE STMT FROM SENTENCE;
  EXECUTE STMT;

  CALL LOGGER.INFO(LOGGER_ID, '<');
 END P_EXEC_PROCEDURE @

/**
 * Execute the tests defined in a set of stored procedure in the given schema.
 *
 * IN SCHEMA_NAME
 *   Name of the schema where the stored procedures for tests are stored.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXECUTE_TESTS (
  IN SCHEMA_NAME ANCHOR SYSCAT.TABLES.TABSCHEMA
  )
  LANGUAGE SQL
  SPECIFIC P_EXECUTE_TESTS
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXECUTE_TESTS: BEGIN
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE LOGGER_ID SMALLINT;
  DECLARE AT_END BOOLEAN; -- End of the loop.
  DECLARE CURRENT_STATUS ANCHOR EXECUTION_REPORTS.STATUS; -- Internal status.
  DECLARE CONTINUE BOOLEAN DEFAULT TRUE; -- Stops the execution.
  DECLARE SENTENCE VARCHAR(1024); -- Dynamic statement to execute.
  DECLARE TABLENAME ANCHOR SYSCAT.TABLES.TABNAME; -- Name of the table.
  DECLARE REPORT_CREATED BOOLEAN DEFAULT FALSE; -- If a report was created.
  DECLARE PROCS_NAMES PROCS_NAMES_TYPE; -- List of procedures.
  DECLARE CARD_PROCS INT; -- Quantity of procedures.
  DECLARE INDEX INT; -- Index to scan the procs.

  DECLARE STMT STATEMENT; -- Statement to execute.

  DECLARE GLOBAL_REPORT_CURSOR CURSOR
    WITH RETURN TO CALLER
    FOR GLOBAL_REPORT_RS;
  DECLARE REPORT_CURSOR CURSOR
    WITH RETURN TO CLIENT
    FOR REPORT_RS;
  DECLARE ALL_PROCS CURSOR WITH HOLD FOR -- List of tests.
    SELECT PROCNAME
    FROM SYSCAT.PROCEDURES
    WHERE PROCNAME LIKE 'TEST_%'
    AND PROCSCHEMA LIKE TRIM(SCHEMA_NAME);
  DECLARE CONTINUE HANDLER FOR NOT FOUND -- Handler for the end of the loop.
    SET AT_END = TRUE;
  DECLARE CONTINUE HANDLER FOR SQLWARNING
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE) VALUES (
      CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Warning: SQLCode'
      || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(SQLSTATE, 'EMPTY'));
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE) VALUES (
      CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Exception: SQLCode'
      || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(SQLSTATE, 'EMPTY'));

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.EXECUTE_TESTS', LOGGER_ID);
  CALL LOGGER.WARN(LOGGER_ID, '>');

  -- Set the initial status
  SET CURRENT_STATUS = 'Initilization';
  CALL LOGGER.INFO(LOGGER_ID, 'Execution for ' || COALESCE(SCHEMA_NAME,
    'Empty schema'));
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  SET EXEC_ID = RAND () * 10000;
  -- Validates the schema
  SELECT TRIM(SCHEMANAME) INTO CUR_SCHEMA
    FROM SYSCAT.SCHEMATA
    WHERE SCHEMANAME LIKE TRIM(SCHEMA_NAME);
  IF (CUR_SCHEMA IS NULL) THEN
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE) VALUES (
     CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS,
     'The given schema does not exists: ' || SCHEMA_NAME);
   SET CONTINUE = FALSE;
  END IF;

  -- Creates the report's table if it does not exist.
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Prepare Report';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   SELECT TABNAME INTO TABLENAME
     FROM SYSCAT.TABLES
     WHERE TABSCHEMA LIKE CUR_SCHEMA
     AND TABNAME = REPORTS_TABLE;
   -- Create the table only if it does not exist.
   IF (TABLENAME IS NULL) THEN
    SET SENTENCE = 'CREATE TABLE ' || CUR_SCHEMA || '.'
      || REPORTS_TABLE || ' ('
      || 'DATE TIMESTAMP NOT NULL, '
      || 'EXECUTION_ID INT NOT NULL, '
      || 'TEST_NAME VARCHAR(128) NOT NULL, '
      || 'MESSAGE VARCHAR(256) NOT NULL '
      || ')';
    PREPARE STMT FROM SENTENCE;
    EXECUTE STMT;
   ELSE
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE) VALUES (
     CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS,
     'The reports table already exist: ' || CUR_SCHEMA || '.'
     || REPORTS_TABLE);
   END IF;
   SET REPORT_CREATED = TRUE;
  END IF;

  -- Generates the list of procedures to execute.
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Generate list';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   SET PROCS_NAMES = ARRAY[
     SELECT PROCNAME
     FROM SYSCAT.PROCEDURES
     WHERE PROCSCHEMA LIKE CUR_SCHEMA
     AND PROCNAME LIKE 'TEST_%'];
  END IF;

  -- Sort the list of procedures to execute
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Sort list';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   -- TODO: Sort the list according some criteria.
  END IF;

  -- Execute the tests.
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Executing.BeforeAll';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   CALL WRITE_IN_REPORT('Starting execution');
   CALL EXEC_PROCEDURE('BEFORE_ALL');

   SET CARD_PROCS = CARDINALITY(PROCS_NAMES);
   SET INDEX = 1;
   WHILE (INDEX <= CARD_PROCS) DO

    SET CURRENT_STATUS = 'Executing.Before';
    CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
    SET TESTNAME = PROCS_NAMES[INDEX];
    CALL WRITE_IN_REPORT('Executing ' || COALESCE(TESTNAME, 'NULL'));
    CALL EXEC_PROCEDURE('BEFORE');

    SET CURRENT_STATUS = 'Executing.Test';
    CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
    CALL EXEC_PROCEDURE(TESTNAME);

    SET CURRENT_STATUS = 'Executing.After';
    CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
    CALL EXEC_PROCEDURE('AFTER');
    SET TESTNAME = NULL;

    SET INDEX = INDEX + 1;
   END WHILE;

   SET CURRENT_STATUS = 'Executing.AfterAll';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   CALL EXEC_PROCEDURE('AFTER_ALL');
  END IF;

  -- Generates the reports
  SET CURRENT_STATUS = 'Generating reports';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  IF (REPORT_CREATED = TRUE) THEN
   SET SENTENCE = 'SELECT VARCHAR(TEST_NAME, 32) AS TEST, '
     || 'VARCHAR(MESSAGE, 64) AS MESSAGE '
     || 'FROM ' || CUR_SCHEMA || '.' || REPORTS_TABLE || ' '
     || 'WHERE EXECUTION_ID = ' || EXEC_ID || ' '
     || 'ORDER BY DATE';
   PREPARE REPORT_RS FROM SENTENCE;
   OPEN REPORT_CURSOR;
  END IF;
  SET SENTENCE = 'SELECT * '
    || 'FROM EXECUTION_REPORTS '
    || 'WHERE EXECUTION_ID = ' || EXEC_ID || ' '
    || 'ORDER BY DATE';
  PREPARE GLOBAL_REPORT_RS FROM SENTENCE;
  OPEN GLOBAL_REPORT_CURSOR;

  -- Cleans environement.
  SET CURRENT_STATUS = 'Cleans environement';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
  SET CUR_SCHEMA = NULL;
  SET EXEC_ID = NULL;

  CALL LOGGER.WARN(LOGGER_ID, '<');
 END P_EXECUTE_TESTS @

/**
 * Asserts if the given two strings are the same, in lenght and in content.
 *
 * IN EXPECTED_STRING
 *   Expected string.
 * IN ACTUAL_STRING
 *   Actual string.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT (
  IN EXPECTED_STRING VARCHAR(512),
  IN ACTUAL_STRING VARCHAR(512)
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_STRINGS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_STRINGS: BEGIN
  IF (LENGTH(EXPECTED_STRING) <> LENGTH(ACTUAL_STRING)) THEN
   CALL WRITE_IN_REPORT ('Strings have different length');
  ELSEIF (EXPECTED_STRING <> ACTUAL_STRING) THEN
   CALL WRITE_IN_REPORT ('The content of both strings is different');
  END IF;
 END P_ASSERT_STRINGS @

