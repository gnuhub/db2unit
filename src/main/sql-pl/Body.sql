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

SET CURRENT SCHEMA DB2UNIT_1B @

/**
 * Core implementation.
 *
 * Version: 2014-04-30 1-Beta
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
 * Constant for OneTimeSetup.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE ONE_TIME_SETUP VARCHAR(20) CONSTANT 'ONE_TIME_SETUP' @

/**
 * Constant for OneTimeSetup.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE SETUP VARCHAR(20) CONSTANT 'SETUP' @

/**
 * Constant for OneTimeSetup.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE TEAR_DOWN VARCHAR(20) CONSTANT 'TEAR_DOWN' @

/**
 * Constant for OneTimeSetup.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE ONE_TIME_TEAR_DOWN VARCHAR(20) CONSTANT 'ONE_TIME_TEAR_DOWN' @

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
 * Transaction mode execution.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE AUTONOMOUS_EXEC BOOLEAN DEFAULT TRUE @

/**
 * Order type to sort the proc names. False ordered by name; true random.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE RANDOM_SORT BOOLEAN DEFAULT TRUE @

/**
 * Array of procedure's names.
 */
ALTER MODULE DB2UNIT ADD
  TYPE PROCS_NAMES_TYPE AS ANCHOR SYSCAT.PROCEDURES.PROCNAME ARRAY [] @

/**
 * List of procedure.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE PROCS_NAMES PROCS_NAMES_TYPE @

/**
 * Write a message in the tests' report. Implementation.
 *
 * IN MSG
 *   Message to insert in the report.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE WRITE_IN_REPORT_BODY (
  IN MSG ANCHOR REPORT_TESTS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_WRITE_IN_REPORT_BODY
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WRITE_IN_REPORT_BODY: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE MSG_TEXT ANCHOR MAX_SIGNAL.SIGNAL; -- Message from signal.
  DECLARE SENTENCE ANCHOR MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE STMT STATEMENT; -- Statement to execute.

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, '', SUBSTR('Warning: SQLCode'
       || COALESCE(COPY_SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || 'Message:' || MSG_TEXT, 1, 128));
     CALL LOGGER.INFO(LOGGER_ID, '< With warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(COPY_SQLCODE, -1));
     COMMIT;
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1B.DB2UNIT.WRITE_IN_REPORT', LOGGER_ID);

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
 END P_WRITE_IN_REPORT_BODY @

/**
 * Write a message in the tests' report. Autonomous.
 *
 * IN MSG
 *   Message to insert in the report.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE WRITE_IN_REPORT_AUTONOMOUS (
  IN MSG ANCHOR REPORT_TESTS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_WRITE_IN_REPORT_AUTONOMOUS
  DYNAMIC RESULT SETS 0
  AUTONOMOUS -- Autonomous transactions, it means it writes anyway.
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WRITE_IN_REPORT_AUTONOMOUS: BEGIN
  CALL WRITE_IN_REPORT_BODY(MSG);
 END P_WRITE_IN_REPORT_AUTONOMOUS @

/**
 * Write a message in the tests' report. Dispatcher between autonomous or not.
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
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WRITE_IN_REPORT: BEGIN
  IF (AUTONOMOUS_EXEC = TRUE) THEN
   CALL WRITE_IN_REPORT_AUTONOMOUS(MSG);
  ELSE
   CALL WRITE_IN_REPORT_BODY(MSG);
  END IF;
 END P_WRITE_IN_REPORT @


/**
 * Sorts the procedures list.
 *
 * IN PREV_EXEC_ID
 *   Previous execution ID to run the tests in that same order. Useful when
 *   tests were executed randominly and generate an error.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE SORT_PROC_NAMES (
  IN PREV_EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID DEFAULT NULL
  )
  LANGUAGE SQL
  SPECIFIC P_SORT_PROC_NAMES
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SORT_PROC_NAMES: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE NEW_LIST PROCS_NAMES_TYPE;
  DECLARE INDEX INT;
  DECLARE LENGTH SMALLINT;
  DECLARE POS INT;
  DECLARE PROC_NAME ANCHOR SYSCAT.PROCEDURES.PROCNAME;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1B.DB2UNIT.SORT_PROC_NAMES', LOGGER_ID);
  CALL LOGGER.INFO(LOGGER_ID, '>');

  IF (PREV_EXEC_ID IS NULL AND RANDOM_SORT = FALSE) THEN
   CALL LOGGER.INFO(LOGGER_ID, 'No random');
  ELSEIF (PREV_EXEC_ID IS NULL AND RANDOM_SORT = TRUE) THEN
   CALL LOGGER.INFO(LOGGER_ID, 'Random');
   SET INDEX = 1;
   SET LENGTH = CARDINALITY(PROCS_NAMES);
   WHILE (INDEX <= LENGTH) do
    -- Looks for an empty space
    BEGIN
     DECLARE EXIT HANDLER FOR SQLSTATE '2202E' SET PROC_NAME = NULL;
     SET POS = RAND() * LENGTH + 1;
     SET PROC_NAME = NEW_LIST[POS];
     WHILE (PROC_NAME IS NOT NULL) DO
      CALL LOGGER.DEBUG(LOGGER_ID, 'Try ' || POS);
      SET POS = RAND() * LENGTH + 1;
      SET PROC_NAME = NEW_LIST[POS];
     END WHILE;
    END;
    CALL LOGGER.DEBUG(LOGGER_ID, 'Iteration ' || INDEX || ' position ' || POS);

    SET NEW_LIST[POS] = PROCS_NAMES[INDEX];
    SET INDEX = INDEX + 1;
   END WHILE;
   SET PROCS_NAMES = NEW_LIST;
  ELSE
   SET PROCS_NAMES = (
     SELECT ARRAY_AGG(PROC_NAME ORDER BY POSITION)
     FROM SORTS
     WHERE SUITE_NAME = CUR_SCHEMA
     AND EXECUTION_ID = PREV_EXEC_ID);
   CALL LOGGER.DEBUG(LOGGER_ID, 'Elements ' || CARDINALITY(PROCS_NAMES));
  END IF;

  CALL LOGGER.INFO(LOGGER_ID, '<' );
 END P_SORT_PROC_NAMES @

/**
 * Writes the order of the list in a table for future reference.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE SAVE_LIST (
  )
  LANGUAGE SQL
  SPECIFIC P_SAVE_LIST
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SAVE_LIST: BEGIN
  INSERT INTO SORTS
    SELECT CUR_SCHEMA, EXEC_ID, POSITION, PROC_NAME
    FROM UNNEST(PROCS_NAMES) WITH ORDINALITY AS (PROC_NAME, POSITION);
 END P_SAVE_LIST @

/**
 * Execute a procedure without parameters. Implementation.
 *
 * IN PROC_NAME
 *   Name of the stored procedure.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXEC_PROCEDURE_BODY (
  IN PROC_NAME ANCHOR SYSCAT.PROCEDURES.PROCNAME
  )
  LANGUAGE SQL
  SPECIFIC P_EXEC_PROCEDURE_BODY
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXEC_PROCEDURE_BODY: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  -- To keep the generated error.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE MSG_TEXT ANCHOR MAX_SIGNAL.SIGNAL; -- Message from signal.
  DECLARE SENTENCE ANCHOR MAX_VALUES.SENTENCE; -- Dynamic statement
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
     DECLARE COPY_SQLCODE INTEGER;
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     CALL WRITE_IN_REPORT(SUBSTR('Warning: SQLCode' || COALESCE(COPY_SQLCODE,
       -1) || '-SQLState' || COALESCE(COPY_SQLSTATE, 'EMPTY') || '-'
       || COALESCE(MSG_TEXT, 'No message'), 1, 512));
     CALL LOGGER.INFO(LOGGER_ID, '< With warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(COPY_SQLCODE, -1));
     SET TEST_RESULT = RESULT_ERROR;
     COMMIT;
    END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     GET DIAGNOSTICS EXCEPTION 1 MSG_TEXT = MESSAGE_TEXT;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     CALL WRITE_IN_REPORT(SUBSTR('Exception: SQLCode' || COALESCE(COPY_SQLCODE,
       -1) || '-SQLState' || COALESCE(COPY_SQLSTATE, 'EMPTY') || '-'
       || COALESCE(MSG_TEXT, 'No message'), 1, 512));
     CALL LOGGER.INFO(LOGGER_ID, '< With exception ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(COPY_SQLCODE, -1));
     SET TEST_RESULT = RESULT_ERROR;
     COMMIT;
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1B.DB2UNIT.EXEC_PROCEDURE', LOGGER_ID);
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
 END P_EXEC_PROCEDURE_BODY @

/**
 * Execute a procedure without parameters. Autonomous.
 *
 * IN PROC_NAME
 *   Name of the stored procedure.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXEC_PROCEDURE_AUTONOMOUS (
  IN PROC_NAME ANCHOR SYSCAT.PROCEDURES.PROCNAME
  )
  LANGUAGE SQL
  SPECIFIC P_EXEC_PROCEDURE_AUTONOMOUS
  DYNAMIC RESULT SETS 0
  AUTONOMOUS -- Autonomous transactions, it means it writes anyway.
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXEC_PROCEDURE_AUTONOMOUS: BEGIN
  CALL EXEC_PROCEDURE_BODY(PROC_NAME);
 END P_EXEC_PROCEDURE_AUTONOMOUS @

/**
 * Execute a procedure without parameters. Dispatcher between autonomous or not.
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
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_EXEC_PROCEDURE: BEGIN
  IF (AUTONOMOUS_EXEC = TRUE) THEN
   CALL EXEC_PROCEDURE_AUTONOMOUS(PROC_NAME);
  ELSE
   CALL EXEC_PROCEDURE_BODY(PROC_NAME);
  END IF;
 END P_EXEC_PROCEDURE @

/**
 * Performs the execution of the tests.
 *
 * INOUT CURRENT_STATUS
 *   Current status of the global execution.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE EXECUTION (
  INOUT CURRENT_STATUS ANCHOR EXECUTION_REPORTS.STATUS
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
  DECLARE SECONDS ANCHOR REPORT_TESTS.TIME; -- To count the expended
    -- time.
  DECLARE SENTENCE ANCHOR MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.

  -- For tests summary
  DECLARE TESTS_EXEC SMALLINT DEFAULT 0;
  DECLARE TESTS_PASSED SMALLINT DEFAULT 0;
  DECLARE TESTS_FAILED SMALLINT DEFAULT 0;
  DECLARE TESTS_ERROR SMALLINT DEFAULT 0;

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
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Warning: SQLCode'
       || COALESCE(COPY_SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.INFO(LOGGER_ID, 'Warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(COPY_SQLCODE, -1));
    END;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Exception: SQLCode'
       || COALESCE(COPY_SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.INFO(LOGGER_ID, 'Exception ' || COALESCE(COPY_SQLSTATE,
       'EMPTY') || '-' || COALESCE(COPY_SQLCODE, -1));
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1B.DB2UNIT.EXECUTION', LOGGER_ID);
  CALL LOGGER.WARN(LOGGER_ID, '>');

  COMMIT;

  -- BEFORE SUITE
  SET CURRENT_STATUS = 'Executing.BeforeSuite';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
  SET TESTNAME = 'Before Suite';
  CALL WRITE_IN_REPORT('Starting execution');
  CALL EXEC_PROCEDURE(ONE_TIME_SETUP);
  COMMIT;

  SET CARD_PROCS = CARDINALITY(PROCS_NAMES);
  SET INDEX = 1;
  WHILE (INDEX <= CARD_PROCS) DO

   -- BEFORE
   SET CURRENT_STATUS = 'Executing.Before';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   SET TESTNAME = PROCS_NAMES[INDEX];
   CALL WRITE_IN_REPORT(SUBSTR('Executing ' || COALESCE(TESTNAME, 'NULL'), 1,
     128));
   CALL EXEC_PROCEDURE(SETUP);
   COMMIT;

   -- TEST
   SET CURRENT_STATUS = 'Executing.Test';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   SET START_TIME = CURRENT TIMESTAMP;
   CALL EXEC_PROCEDURE(TESTNAME);
   SET SECONDS = TIMESTAMPDIFF(1, CURRENT TIMESTAMP - START_TIME);

   IF (TEST_RESULT IS NULL) THEN
    SET TEST_RESULT = RESULT_PASSED;
   END IF;
   -- Update the stats
   SET TESTS_EXEC = TESTS_EXEC + 1;
   IF (TEST_RESULT = RESULT_PASSED) THEN
    SET TESTS_PASSED = TESTS_PASSED + 1;
   ELSEIF (TEST_RESULT = RESULT_FAILED) THEN
    SET TESTS_FAILED = TESTS_FAILED + 1;
   ELSEIF (TEST_RESULT = RESULT_ERROR) THEN
    SET TESTS_ERROR = TESTS_ERROR + 1;
   END IF;

   SET SENTENCE = 'UPDATE ' || CUR_SCHEMA || '.' || REPORTS_TABLE || ' '
     || 'SET TIME = ' || SECONDS || ', '
     || 'FINAL_STATE = ''' || TEST_RESULT || ''' '
     || 'WHERE MESSAGE = ''Executing ' || COALESCE(TESTNAME, 'NULL') || ''' '
     || 'AND EXECUTION_ID = ' || EXEC_ID;
   SET TEST_RESULT = NULL;
   PREPARE STMT FROM SENTENCE;
   EXECUTE STMT;
   COMMIT;

   -- AFTER
   SET CURRENT_STATUS = 'Executing.After';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
   CALL EXEC_PROCEDURE(TEAR_DOWN);
   SET TESTNAME = NULL;
   COMMIT;

   SET INDEX = INDEX + 1;
  END WHILE;

  -- AFTER SUITE
  SET CURRENT_STATUS = 'Executing.AfterSuite';
  SET TESTNAME = 'After Suite';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);
  CALL EXEC_PROCEDURE(ONE_TIME_TEAR_DOWN);
  CALL WRITE_IN_REPORT('Finishing execution');
  SET TESTNAME = NULL;
  COMMIT;

 -- Write a summary
  CALL WRITE_IN_REPORT (TESTS_EXEC || ' tests were executed');
  CALL WRITE_IN_REPORT (TESTS_PASSED || ' tests passed');
  CALL WRITE_IN_REPORT (TESTS_FAILED || ' tests failed');
  CALL WRITE_IN_REPORT (TESTS_ERROR || ' tests with errors');

  CALL LOGGER.WARN(LOGGER_ID, '<');
 END P_EXECUTION @


/**
 * Execute the tests defined in a set of stored procedure in the given schema.
 *
 * IN SCHEMA_NAME
 *   Name of the schema where the stored procedures for tests are stored.
 * IN PREV_EXEC_ID
 *   Previous execution ID to run the tests in that same order. Useful when
 *   tests were executed randominly and generate an error.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE RUN_SUITE (
  IN SCHEMA_NAME ANCHOR SYSCAT.SCHEMATA.SCHEMANAME,
  IN PREV_EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID DEFAULT NULL
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
  DECLARE SENTENCE ANCHOR MAX_VALUES.SENTENCE; -- Dynamic statement
    -- to execute.
  DECLARE TABLENAME ANCHOR SYSCAT.TABLES.TABNAME; -- Name of the table.
  DECLARE REPORT_CREATED BOOLEAN DEFAULT FALSE; -- If a report was created.
  DECLARE PREVIOUS_SCHEMA ANCHOR SYSCAT.SCHEMATA.SCHEMANAME; -- Previous schema
    -- to test itself.
  DECLARE PREVIOUS_TESTNAME ANCHOR SYSCAT.PROCEDURES.PROCNAME; -- Previous test
    -- name to test itself.
  DECLARE PREVIOUS_EXEC_ID ANCHOR EXECUTION_REPORTS.EXECUTION_ID; -- Previous
    -- exec id to test itself.
  DECLARE PREVIOUS_PROCS_NAMES PROCS_NAMES_TYPE; -- Previous list.
  DECLARE INIT_TIME TIMESTAMP;
  DECLARE SEED INTEGER;

  DECLARE EXISTING_LOCK CONDITION FOR SQLSTATE '23505';
  DECLARE STMT STATEMENT; -- Statement to execute.

  DECLARE GLOBAL_REPORT_CURSOR CURSOR
    WITH RETURN TO CALLER
    FOR GLOBAL_REPORT_RS;
  DECLARE REPORT_CURSOR CURSOR
    WITH RETURN TO CLIENT
    FOR REPORT_RS;
  DECLARE CONTINUE HANDLER FOR EXISTING_LOCK
    BEGIN
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'There is another '
       || 'execution of the same test suite concurrently.');
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'If not, please '
       || 'execute CALL DB2UNIT.RELEASE_LOCK(''' || COALESCE(SCHEMA_NAME,
       'SUITE_NAME') || ''')');
     CALL LOGGER.WARN(LOGGER_ID, 'There is another execution of the same '
       || 'test suite concurrently');
     SET CONTINUE = FALSE;
    END;
  DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Warning: SQLCode'
       || COALESCE(COPY_SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.WARN(LOGGER_ID, '< with warning ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
    END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
     DECLARE COPY_SQLSTATE CHAR(5);
     DECLARE COPY_SQLCODE INTEGER;
     SET COPY_SQLSTATE = SQLSTATE, COPY_SQLCODE = SQLCODE;
     INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
       VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Exception: SQLCode'
       || COALESCE(COPY_SQLCODE, -1) || '-SQLState' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
     CALL LOGGER.WARN(LOGGER_ID, '< with exception ' || COALESCE(COPY_SQLSTATE,
       'EMPTY'));
    END;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1B.DB2UNIT.RUN_SUITE', LOGGER_ID);
  CALL LOGGER.WARN(LOGGER_ID, '>');
  SET INIT_TIME = CURRENT TIMESTAMP;

  -- INITIALIZATION
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
   SET PREVIOUS_PROCS_NAMES = PROCS_NAMES;
   CALL LOGGER.INFO(LOGGER_ID, 'Self testing');
  END IF;

  SET SEED = CHAR(SUBSTR(VARCHAR_FORMAT_BIT(CAST(GENERATE_UNIQUE AS CHAR(16) FOR
    BIT DATA),'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'), 20, 4));
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
   -- Puts the lock for the current suite.
   INSERT INTO SUITE_LOCKS (NAME) VALUES (SCHEMA_NAME);

   -- If there is not another execution of the same test suite.
   IF (CONTINUE = TRUE) THEN
    CALL LOGGER.INFO(LOGGER_ID, CUR_SCHEMA || ':' || EXEC_ID);
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, LICENSE);
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, SUBSTR('Execution of '
      || CUR_SCHEMA || ' with ID ' || EXEC_ID, 1, 128));
   END IF;
  END IF;

  -- PREPARE REPORT
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
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, SUBSTR(
      'The reports table created: ' || CUR_SCHEMA || '.' || REPORTS_TABLE, 1,
      128));
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

  -- GENERATE LIST
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
     AND PARM_COUNT = 0
     ORDER BY PROCNAME];
  END IF;

  -- SORT LIST
  -- Sort the list of procedures to execute
  IF (CONTINUE = TRUE) THEN
   SET CURRENT_STATUS = 'Sort list';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   CALL SORT_PROC_NAMES(PREV_EXEC_ID);
   CALL SAVE_LIST();
  END IF;

  -- EXECUTE
  -- Execute the tests.
  IF (CONTINUE = TRUE) THEN
   CALL EXECUTION(CURRENT_STATUS);
  END IF;

  IF (CONTINUE = TRUE) THEN
   -- Release the lock.
   CALL RELEASE_LOCK(SCHEMA_NAME);

   -- CALCULATING TIME
   SET CURRENT_STATUS = 'Calculating time';
   CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

   -- Elapsed time.
   IF (PREVIOUS_SCHEMA IS NULL) THEN
    INSERT INTO EXECUTION_REPORTS (DATE, EXECUTION_ID, STATUS, MESSAGE_REPORT)
      VALUES (CURRENT TIMESTAMP, EXEC_ID, CURRENT_STATUS, 'Total execution time '
      || 'is: ' || TIMESTAMPDIFF(2, CURRENT TIMESTAMP - INIT_TIME)
      || ' seconds');
   END IF;
  END IF;

  -- GENERATING REPORTS
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
   SET SENTENCE = 'SELECT TIME(DATE) AS TIME, EXECUTION_ID,'
     || 'VARCHAR(SUBSTR(STATUS, 1, 21), 21) AS STATUS, '
     || 'VARCHAR(SUBSTR(MESSAGE_REPORT, 1, 62), 62) AS MESSAGE '
     || 'FROM ' || UTILITY_SCHEMA || '.EXECUTION_REPORTS '
     || 'WHERE EXECUTION_ID = ' || EXEC_ID || ' '
     || 'ORDER BY DATE';
   CALL LOGGER.DEBUG(LOGGER_ID, 'Sentence: ' || SENTENCE);
   PREPARE GLOBAL_REPORT_RS FROM SENTENCE;
   OPEN GLOBAL_REPORT_CURSOR;
  END IF;

  -- CLEAN ENVIRONMENT
  -- Cleans environment.
  SET CURRENT_STATUS = 'Clean environment';
  CALL LOGGER.INFO(LOGGER_ID, CURRENT_STATUS);

  SET CUR_SCHEMA = NULL;
  SET EXEC_ID = NULL;

  -- Restore previous environment (For self testing.)
  IF (PREVIOUS_SCHEMA IS NOT NULL) THEN
   CALL LOGGER.DEBUG(LOGGER_ID, 'Reestablish previous environment');
   SET EXEC_ID = PREVIOUS_EXEC_ID;
   SET CUR_SCHEMA = PREVIOUS_SCHEMA;
   SET TESTNAME = PREVIOUS_TESTNAME;
   SET PROCS_NAMES = PREVIOUS_PROCS_NAMES;
   SET PREVIOUS_EXEC_ID = NULL;
   SET PREVIOUS_SCHEMA = NULL;
   SET PREVIOUS_TESTNAME = NULL;
   SET PREVIOUS_PROCS_NAMES = NULL;
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

/**
 * Release the lock for a given suite. It should be used when a test suite
 * execution is cancelled and it does not finish correctly.
 *
 * IN NAME
 *   Name of the test suite for remove its lock.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE RELEASE_LOCK (
  NAME ANCHOR SYSCAT.SCHEMATA.SCHEMANAME
  )
  LANGUAGE SQL
  SPECIFIC P_RELEASE_LOCK
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_RELEASE_LOCK: BEGIN
  DECLARE STATEMENT VARCHAR(256);
  DECLARE STMT STATEMENT;
  DECLARE EXIT HANDLER FOR NOT FOUND SET STATEMENT = '';

  SET STATEMENT = 'DELETE FROM ' || UTILITY_SCHEMA || '.SUITE_LOCKS '
    || 'WHERE NAME = ''' || NAME || '''';
  PREPARE STMT FROM STATEMENT;
  EXECUTE STMT;
 END P_RELEASE_LOCK @

/**
 * Changes the transaction mode to non-autonomous.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE SET_NON_AUTONOMOUS (
  )
  LANGUAGE SQL
  SPECIFIC P_SET_NON_AUTONOMOUS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SET_NON_AUTONOMOUS: BEGIN
  SET AUTONOMOUS_EXEC = FALSE;
 END P_SET_NON_AUTONOMOUS @

/**
 * Changes the transaction mode to autonomous.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE SET_AUTONOMOUS (
  )
  LANGUAGE SQL
  SPECIFIC P_SET_AUTONOMOUS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SET_AUTONOMOUS: BEGIN
  SET AUTONOMOUS_EXEC = TRUE;
 END P_SET_AUTONOMOUS @

/**
 * Shows the license of this framework.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE LICENSE (
  )
  LANGUAGE SQL
  SPECIFIC P_LICENSE
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LICENSE: BEGIN
  DECLARE LICENSE_CURSOR CURSOR
    WITH RETURN FOR
    SELECT LINE
    FROM LICENSE
    ORDER BY NUMBER;
  OPEN LICENSE_CURSOR;
 END P_LICENSE @

/**
 * Changes the sort type for the procedures.
 *
 * IN RANDOM
 *   True if the sort should be random, false if the sort is alphabetical.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE RANDOM_SORT (
  IN RANDOM BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_RANDOM_SORT
  DYNAMIC RESULT SETS 0
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_RANDOM_SORT: BEGIN
  SET RANDOM_SORT = RANDOM;
 END P_RANDOM_SORT @

