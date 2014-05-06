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
 * Constant for a passed test.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE RESULT_PASSED ANCHOR REPORT_TESTS.FINAL_STATE CONSTANT 'Passed' @

/**
 * Constant for a passed test.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE RESULT_FAILED ANCHOR REPORT_TESTS.FINAL_STATE CONSTANT 'Failed' @

/**
 * Constant for a passed test.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE RESULT_ERROR ANCHOR REPORT_TESTS.FINAL_STATE CONSTANT 'Error' @

/**
 * Max size for assertion messages.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE MAX_MESSAGE SMALLINT CONSTANT 400 @

/**
 * ID of the current execution.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID @

/**
 * Current schema being tested.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE CUR_SCHEMA ANCHOR SYSCAT.SCHEMATA.SCHEMANAME @

/**
 * Current test being executed.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE TESTNAME ANCHOR SYSCAT.PROCEDURES.PROCNAME @

/**
 * Returned status after the execution.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE TEST_RESULT ANCHOR REPORT_TESTS.FINAL_STATE DEFAULT NULL @

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
  IN MSG ANCHOR REPORT_TESTS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_WRITE_IN_REPORT
  DYNAMIC RESULT SETS 0
  AUTONOMOUS -- Autonomous transactions, it means it writes anyway.
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WRITE_IN_REPORT: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE MSG_TEXT ANCHOR DB2UNIT_1A.MAX_SIGNAL.SIGNAL; -- Message from signal.
  DECLARE SENTENCE ANCHOR DB2UNIT_1A.MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE STMT STATEMENT; -- Statement to execute.

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, '', SUBSTR('Warning: SQLCode'
       || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || 'Message:' || MSG_TEXT, 1, 128));
     CALL LOGGER.INFO(LOGGER_ID, '< With warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     COMMIT;
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.WRITE_IN_REPORT', LOGGER_ID);

  SET MSG = TRIM(MSG);
  CALL LOGGER.INFO(LOGGER_ID, '>' || COALESCE(MSG, ''));
  CALL LOGGER.DEBUG(LOGGER_ID, 'Schema ' || CUR_SCHEMA);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Report ' || REPORTS_TABLE);
  CALL LOGGER.DEBUG(LOGGER_ID, 'ExecId ' || EXEC_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'TestName ' || COALESCE(TESTNAME, 'NoTestName'));
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message ' || MSG);


  IF (CUR_SCHEMA IS NULL OR REPORTS_TABLE IS NULL) THEN
   IF (EXEC_ID IS NULL) THEN
    SET EXEC_ID = -1;
   END IF;
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
     VALUES (CURRENT TIMESTAMP, EXEC_ID, -1, 'Invalid parameters');
  ELSE
   SET SENTENCE = 'INSERT INTO ' || CUR_SCHEMA || '.' || REPORTS_TABLE
     || ' (DATE, EXECUTION_ID, TEST_NAME, MESSAGE) VALUES ('
     || 'CURRENT TIMESTAMP, ' || COALESCE(EXEC_ID, -1) || ', '''
     || COALESCE(TESTNAME, '') || ''', ''' || COALESCE(MSG, 'NULL') || ''')';
   CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT;
  END IF;

  COMMIT;

  CALL LOGGER.INFO(LOGGER_ID, '<');
 END P_WRITE_IN_REPORT @

/**
 * Execute a procedure without parameters.
 *
 * IN PROC_NAME
 *   Name of the stored procedure.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXEC_PROCEDURE (
  IN PROC_NAME ANCHOR SYSCAT.PROCEDURES.PROCNAME
  )
  LANGUAGE SQL
  SPECIFIC P_EXEC_PROCEDURE
  DYNAMIC RESULT SETS 0
  AUTONOMOUS -- Autonomous transactions, it means it writes anyway.
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXEC_PROCEDURE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE MSG_TEXT ANCHOR DB2UNIT_1A.MAX_SIGNAL.SIGNAL; -- Message from signal.
  DECLARE SENTENCE ANCHOR DB2UNIT_1A.MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE INEXISTENT CONDITION FOR SQLSTATE '42884';
  DECLARE TOO_LONG CONDITION FOR SQLSTATE '22001';
  DECLARE STMT STATEMENT; -- Statement to execute.
  -- If the procedure does not exist, then exist without any message.
  DECLARE EXIT HANDLER FOR INEXISTENT
    CALL LOGGER.INFO(LOGGER_ID, '<');
  -- A string is too long to be processed.
  DECLARE EXIT HANDLER FOR TOO_LONG
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE;
     CALL WRITE_IN_REPORT(SUBSTR('String too long: "' || COALESCE(MSG_TEXT,
       'No message') || '"', 1, 512));
     CALL LOGGER.INFO(LOGGER_ID, '< String too long ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(MSG_TEXT, 'No message'));
     SET TEST_RESULT = RESULT_ERROR;
     COMMIT;
    END;
  -- Logs any exception or warning.
  DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE;
     CALL WRITE_IN_REPORT(SUBSTR('Warning: SQLCode' || COALESCE(SQLCODE, -1)
       || '-SQLState' || COALESCE(COPY_SQLSTATE, 'EMPTY') || '-'
       || COALESCE(MSG_TEXT, 'No message'), 1, 512));
     CALL LOGGER.INFO(LOGGER_ID, '< With warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     SET TEST_RESULT = RESULT_ERROR;
     COMMIT;
    END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE;
     CALL WRITE_IN_REPORT(SUBSTR('Exception: SQLCode' || COALESCE(SQLCODE, -1)
       || '-SQLState' || COALESCE(COPY_SQLSTATE, 'EMPTY') || '-'
       || COALESCE(MSG_TEXT, 'No message'), 1, 512));
     CALL LOGGER.INFO(LOGGER_ID, '< With exception ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     SET TEST_RESULT = RESULT_ERROR;
     COMMIT;
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.EXEC_PROCEDURE', LOGGER_ID);
  CALL LOGGER.INFO(LOGGER_ID, '>' || COALESCE(PROC_NAME, 'NoName'));

  IF (PROC_NAME IS NOT NULL) THEN
   SET SENTENCE = 'CALL ' || CUR_SCHEMA || '.' || PROC_NAME || '()';
   CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT;
  ELSE
   CALL LOGGER.ERROR(LOGGER_ID, 'Null procedure name');
  END IF;

  CALL LOGGER.INFO(LOGGER_ID, '<');
  COMMIT;
 END P_EXEC_PROCEDURE @

/**
 * Performs the execution of the tests.
 *
 * INOUT CURRENT_STATUS
 *   Current status of the global execution.
 * IN PROCS_NAMES
 *   List of stored procedures to execute.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXECUTION (
  INOUT CURRENT_STATUS ANCHOR EXECUTION_REPORTS.STATUS,
  IN PROCS_NAMES PROCS_NAMES_TYPE
  )
  LANGUAGE SQL
  SPECIFIC P_EXECUTION
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXECUTION: BEGIN
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE LOGGER_ID SMALLINT;
  DECLARE CARD_PROCS INT; -- Quantity of procedures.
  DECLARE INDEX INT; -- Index to scan the procs.
  DECLARE START_TIME TIMESTAMP; -- Start time of the execution.
  DECLARE SECONDS ANCHOR DB2UNIT_1A.REPORT_TESTS.TIME; -- To count the expended
    -- time.
  DECLARE SENTENCE ANCHOR DB2UNIT_1A.MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE STMT STATEMENT; -- Statement to execute.

  -- When the milliseconds conversion cannot be made.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22008'
    BEGIN
     SET SENTENCE = 'UPDATE ' || CUR_SCHEMA || '.' || REPORTS_TABLE || ' '
       || 'SET TIME = -1 '
       || 'WHERE MESSAGE = ''Executing ' || COALESCE(TESTNAME, 'NULL') || ''' '
       || 'AND EXECUTION_ID = ' || EXEC_ID;
     PREPARE STMT FROM SENTENCE;
     EXECUTE STMT;
    END;
  DECLARE CONTINUE HANDLER FOR SQLWARNING
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Warning: SQLCode'
      || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(SQLSTATE, 'EMPTY'));
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Exception: SQLCode'
      || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(SQLSTATE, 'EMPTY'));

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.EXECUTION', LOGGER_ID);
  CALL LOGGER.WARN(LOGGER_ID, '>');

  COMMIT;

  SET CURRENT_STATUS = 'Executing.BeforeSuite';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
  SET TESTNAME = 'Before Suite';
  CALL WRITE_IN_REPORT('Starting execution');
  CALL EXEC_PROCEDURE('BEFORE_SUITE');
  COMMIT;

  SET CARD_PROCS = CARDINALITY(PROCS_NAMES);
  SET INDEX = 1;
  WHILE (INDEX <= CARD_PROCS) DO

   SET CURRENT_STATUS = 'Executing.Before';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   SET TESTNAME = PROCS_NAMES[INDEX];
   CALL WRITE_IN_REPORT(SUBSTR('Executing ' || COALESCE(TESTNAME, 'NULL'), 1,
     128));
   CALL EXEC_PROCEDURE('BEFORE');
   COMMIT;

   SET CURRENT_STATUS = 'Executing.Test';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   SET START_TIME = CURRENT TIMESTAMP;
   CALL EXEC_PROCEDURE(TESTNAME);
   IF (TEST_RESULT IS NULL) THEN
    SET TEST_RESULT = RESULT_PASSED;
   END IF;
   SET SECONDS = TIMESTAMPDIFF(1, CURRENT TIMESTAMP - START_TIME);
   SET SENTENCE = 'UPDATE ' || CUR_SCHEMA || '.' || REPORTS_TABLE || ' '
     || 'SET TIME = ' || SECONDS || ', '
     || 'FINAL_STATE = ''' || TEST_RESULT || ''' '
     || 'WHERE MESSAGE = ''Executing ' || COALESCE(TESTNAME, 'NULL') || ''' '
     || 'AND EXECUTION_ID = ' || EXEC_ID;
   SET TEST_RESULT = NULL;
   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT;
   COMMIT;

   SET CURRENT_STATUS = 'Executing.After';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   CALL EXEC_PROCEDURE('AFTER');
   SET TESTNAME = NULL;
   COMMIT;

   SET INDEX = INDEX + 1;
  END WHILE;

  SET CURRENT_STATUS = 'Executing.AfterSuite';
  SET TESTNAME = 'After Suite';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
  CALL EXEC_PROCEDURE('AFTER_SUITE');
  CALL WRITE_IN_REPORT('Finishing execution');
  SET TESTNAME = NULL;
  COMMIT;

  CALL LOGGER.WARN(LOGGER_ID, '<');
 END P_EXECUTION @


/**
 * Execute the tests defined in a set of stored procedure in the given schema.
 *
 * IN SCHEMA_NAME
 *   Name of the schema where the stored procedures for tests are stored.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE RUN_SUITE (
  IN SCHEMA_NAME ANCHOR SYSCAT.SCHEMATA.SCHEMANAME
  )
  LANGUAGE SQL
  SPECIFIC P_RUN_SUITE
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_RUN_SUITE: BEGIN
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE LOGGER_ID SMALLINT;
  DECLARE CURRENT_STATUS ANCHOR EXECUTION_REPORTS.STATUS; -- Internal status.
  DECLARE CONTINUE BOOLEAN DEFAULT TRUE; -- Stops the execution.
  DECLARE SENTENCE ANCHOR DB2UNIT_1A.MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE TABLENAME ANCHOR SYSCAT.TABLES.TABNAME; -- Name of the table.
  DECLARE REPORT_CREATED BOOLEAN DEFAULT FALSE; -- If a report was created.
  DECLARE PROCS_NAMES PROCS_NAMES_TYPE; -- List of procedures.
  DECLARE PREVIOUS_SCHEMA ANCHOR SYSCAT.SCHEMATA.SCHEMANAME; -- Previous schema
    -- to test itself.
  DECLARE PREVIOUS_TESTNAME ANCHOR SYSCAT.PROCEDURES.PROCNAME; -- Previous test
    -- name to test itself.
  DECLARE PREVIOUS_EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID; -- Previous
    -- exec id to test itself.

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
  DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     SET COPY_SQLSTATE = SQLSTATE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Warning: SQLCode'
       || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.WARN(LOGGER_ID, '< with warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
    END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     SET COPY_SQLSTATE = SQLSTATE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Exception: SQLCode'
       || COALESCE(SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.WARN(LOGGER_ID, '< with exception ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.RUN_SUITE', LOGGER_ID);
  CALL LOGGER.WARN(LOGGER_ID, '>');

  -- Set the initial status
  SET CURRENT_STATUS = 'Initialization';
  CALL LOGGER.INFO(LOGGER_ID, 'Execution for ' || COALESCE(SCHEMA_NAME,
    'NULL schema'));
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  -- Check previous values (for self testing)
  IF (CUR_SCHEMA IS NOT NULL) THEN
   SET PREVIOUS_EXEC_ID = EXEC_ID;
   SET PREVIOUS_SCHEMA = CUR_SCHEMA;
   SET CUR_SCHEMA = NULL;
   SET PREVIOUS_TESTNAME = TESTNAME;
   CALL LOGGER.INFO(LOGGER_ID, 'Self testing');
  END IF;

  SET EXEC_ID = RAND (MIDNIGHT_SECONDS(CURRENT TIMESTAMP)) * 100000;
  CALL LOGGER.INFO(LOGGER_ID, 'EXEC_ID: ' || EXEC_ID);

  -- Validates the schema
  SELECT TRIM(SCHEMANAME) INTO CUR_SCHEMA
    FROM SYSCAT.SCHEMATA
    WHERE SCHEMANAME LIKE TRIM(SCHEMA_NAME);
  IF (CUR_SCHEMA IS NULL) THEN
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
     VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, SUBSTR(
     'The given schema does not exists: ' || COALESCE(SCHEMA_NAME, 'NULL'), 1,
     128));
   CALL LOGGER.DEBUG(LOGGER_ID, 'The given schema does not exists');
   SET CONTINUE = FALSE;
  ELSE
   CALL LOGGER.INFO(LOGGER_ID, CUR_SCHEMA || ':' || EXEC_ID);
   INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
     VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, SUBSTR('Execution of '
     || CUR_SCHEMA || ' with ID ' || EXEC_ID, 1, 128));
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
    SET SENTENCE = 'CREATE TABLE ' || CUR_SCHEMA || '.' || REPORTS_TABLE
      || ' LIKE ' || UTILITY_SCHEMA || '.' || REPORTS_TABLE;
    CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
    PREPARE STMT FROM SENTENCE;
    EXECUTE STMT;
    CALL LOGGER.INFO(LOGGER_ID, 'Table created for ' || CUR_SCHEMA);
   ELSE
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, SUBSTR(
      'The reports table already exist: ' || CUR_SCHEMA || '.'
      || REPORTS_TABLE, 1, 128));
    CALL LOGGER.DEBUG(LOGGER_ID, 'The reports table already exist');
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
     AND PROCNAME LIKE 'TEST_%'
     AND LANGUAGE = 'SQL'
     AND PARM_COUNT = 0];
  END IF;

  -- Sort the list of procedures to execute
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Sort list';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   -- TODO: Sort the list according some criteria.
  END IF;

  -- Execute the tests.
  IF (CONTINUE = TRUE) THEN
   CALL EXECUTION(CURRENT_STATUS, PROCS_NAMES);
  END IF;

  -- Generates the reports (not for self testing)
  SET CURRENT_STATUS = 'Generating reports';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  -- Only create reports when no-self-testing.
  IF (PREVIOUS_SCHEMA IS NULL) THEN
   IF (REPORT_CREATED = TRUE) THEN
    SET SENTENCE = 'SELECT VARCHAR(SUBSTR(TEST_NAME, 1 , 16), 16) AS TEST, '
      || 'FINAL_STATE, TIME AS MICROSECONDS, '
      || 'VARCHAR(SUBSTR(MESSAGE, 1, 64), 64) AS MESSAGE '
      || 'FROM ' || CUR_SCHEMA || '.' || REPORTS_TABLE || ' '
      || 'WHERE EXECUTION_ID = ' || EXEC_ID || ' '
      || 'ORDER BY DATE';
    CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
    PREPARE REPORT_RS FROM SENTENCE;
    OPEN REPORT_CURSOR;
   END IF;
   SET SENTENCE = 'SELECT TIME(DATE) AS TIME, EXECUTION_ID, STATUS, '
     || 'VARCHAR(SUBSTR(MESSAGE_REPORT, 1, 64), 64) AS MESSAGE '
     || 'FROM ' || UTILITY_SCHEMA || '.EXECUTION_REPORTS '
     || 'WHERE EXECUTION_ID = ' || EXEC_ID || ' '
     || 'ORDER BY DATE';
   CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
   PREPARE GLOBAL_REPORT_RS FROM SENTENCE;
   OPEN GLOBAL_REPORT_CURSOR;
  END IF;

  -- Cleans environment.
  SET CURRENT_STATUS = 'Cleans environment';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  SET CUR_SCHEMA = NULL;
  SET EXEC_ID = NULL;

  -- Restore previous environment (For self testing.)
  IF (PREVIOUS_SCHEMA IS NOT NULL) THEN
   CALL LOGGER.DEBUG(LOGGER_ID, 'Reestablish previous environment');
   SET EXEC_ID = PREVIOUS_EXEC_ID;
   SET CUR_SCHEMA = PREVIOUS_SCHEMA;
   SET TESTNAME = PREVIOUS_TESTNAME;
   SET PREVIOUS_EXEC_ID = NULL;
   SET PREVIOUS_SCHEMA = NULL;
   SET PREVIOUS_TESTNAME = NULL;
  END IF;

  CALL LOGGER.WARN(LOGGER_ID, '<');
 END P_RUN_SUITE @

/**
 * Cleans the environment, if a previous execution did not finished correctly.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE CLEAN (
  )
  LANGUAGE SQL
  SPECIFIC P_CLEAN
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_CLEAN: BEGIN
  SET CUR_SCHEMA = NULL;
  SET EXEC_ID = NULL;
  SET TESTNAME = NULL;
 END P_CLEAN @

/**
 * Cleans the last test execution. This is useful for self-testing.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE CLEAN_TEST_RESULT (
  )
  LANGUAGE SQL
  SPECIFIC P_CLEAN_TEST_RESULT
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_CLEAN_TEST_RESULT: BEGIN
  SET TEST_RESULT = NULL;
 END P_CLEAN_TEST_RESULT @

