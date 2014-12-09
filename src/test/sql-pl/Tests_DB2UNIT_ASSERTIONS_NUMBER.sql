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

SET CURRENT SCHEMA DB2UNIT_ASSERTIONS_NUMBER @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", DB2UNIT_1, DB2UNIT_ASSERTIONS_NUMBER @

/**
 * Tests for number assertions.
 *
 * Version: 2014-05-01 1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Previously create the table in order to compile these tests.
BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE TABLE REPORT_TESTS LIKE DB2UNIT_1.REPORT_TESTS';
 EXECUTE IMMEDIATE STATEMENT;
END @

ALTER TABLE DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
  ALTER COLUMN SUITE_NAME
  SET WITH DEFAULT 'DB2UNIT_ASSERTIONS_NUMBER' @

-- Before all tests.
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DECLARE SENTENCE ANCHOR DB2UNIT_1.MAX_VALUES.SENTENCE;
  DECLARE INEXISTANT_TABLE CONDITION FOR SQLSTATE '42704';
  DECLARE STMT STATEMENT;
  DECLARE CONTINUE HANDLER FOR INEXISTANT_TABLE
    SET SENTENCE = '';

 END @

-- Before all tests.
CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
  CALL ONE_TIME_SETUP() @

-- INTEGER

-- Tests that no message is inserted in the report when two ints are equals
-- in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_01()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 BIGINT;
  DECLARE INT_2 BIGINT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET INT_1 = 42;
  SET INT_2 = 42;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test both ints as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_02()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 BIGINT;
  DECLARE INT_2 BIGINT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET INT_1 = NULL;
  SET INT_2 = NULL;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different ints with same data type in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_03()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 BIGINT;
  DECLARE INT_2 BIGINT;

  SET EXPECTED_MSG = 'The value of both integers is different';
  SET INT_1 = 5;
  SET INT_2 = 4;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : "4"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: "5"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different ints with diff data type in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_04()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 INT;
  DECLARE INT_2 SMALLINT;

  SET EXPECTED_MSG = 'The value of both integers is different';
  SET INT_1 = 7;
  SET INT_2 = 6;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : "6"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: "7"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test first int as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_05()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 BIGINT;
  DECLARE INT_2 BIGINT;

  SET EXPECTED_MSG = 'Nullability difference';
  SET INT_1 = NULL;
  SET INT_2 = 3;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : "3"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test second int as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_06()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 BIGINT;
  DECLARE INT_2 BIGINT;

  SET EXPECTED_MSG = 'Nullability difference';
  SET INT_1 = 2;
  SET INT_2 = NULL;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: "2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_int_null with null.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_07()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE BIGINT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET VALUE = NULL;
  CALL DB2UNIT.ASSERT_INT_NULL(VALUE);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
 END @

-- Test the assert_int_null without null.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_08()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE BIGINT;

  SET EXPECTED_MSG = 'The given value is "NOT NULL"';
  SET VALUE = 8;
  CALL DB2UNIT.ASSERT_INT_NULL(VALUE);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test the assert_int_not_null with not null.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_09()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE BIGINT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET VALUE = 9;
  CALL DB2UNIT.ASSERT_INT_NOT_NULL(VALUE);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
 END @

-- Test the assert_int_not_null without not null.
CREATE OR REPLACE PROCEDURE TEST_INTEGER_10()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE BIGINT;

  SET EXPECTED_MSG = 'The given value is "NULL"';
  SET VALUE = NULL;
  CALL DB2UNIT.ASSERT_INT_NOT_NULL(VALUE);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'INT_NOT_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- DECIMAL

-- Tests that no message is inserted in the report when two decimals are equals
-- in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_01()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 DECFLOAT;
  DECLARE INT_2 DECFLOAT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET INT_1 = 42.6543;
  SET INT_2 = 42.6543;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Tests that no message is inserted in the report when two decimals are equals
-- in assert_equals, with real data types.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_02()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 REAL;
  DECLARE INT_2 REAL;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET INT_1 = 42.6543;
  SET INT_2 = 42.6543;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Tests that no message is inserted in the report when two decimals are equals
-- in assert_equals, with real data types.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_03()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE INT_1 DOUBLE;
  DECLARE INT_2 DOUBLE;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET INT_1 = 42.6543;
  SET INT_2 = 42.6543;
  CALL DB2UNIT.ASSERT_INT_EQUALS(INT_1, INT_2);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test both decimals as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_04()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 DECFLOAT;
  DECLARE DEC_2 DECFLOAT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET DEC_1 = NULL;
  SET DEC_2 = NULL;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different decimals with same data type in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_05()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 DECFLOAT;
  DECLARE DEC_2 DECFLOAT;

  SET EXPECTED_MSG = 'The value of both decimals is different';
  SET DEC_1 = 5.3658463;
  SET DEC_2 = 4.65575;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : "' || DEC_2 || '"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: "' || DEC_1 || '"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different decimals with diFf data type in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_06()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 DOUBLE;
  DECLARE DEC_2 REAL;

  SET EXPECTED_MSG = 'The value of both decimals is different';
  SET DEC_1 = 7.31;
  SET DEC_2 = 6.34;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE LIKE 'Actual  : "6.3%"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE LIKE 'Expected: "7.3%"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different decimals with diFf data type in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_07()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 REAL;
  DECLARE DEC_2 REAL;

  SET EXPECTED_MSG = 'The value of both decimals is different';
  SET DEC_1 = 9.435;
  SET DEC_2 = 3.14;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE LIKE 'Actual  : "3.1%"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE LIKE 'Expected: "9.43%"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test first decimal as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_08()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 DECFLOAT;
  DECLARE DEC_2 DECFLOAT;

  SET EXPECTED_MSG = 'Nullability difference';
  SET DEC_1 = NULL;
  SET DEC_2 = 3.134;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : "' || DEC_2 || '"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test second decimal as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_09()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE DEC_1 DECFLOAT;
  DECLARE DEC_2 DECFLOAT;

  SET EXPECTED_MSG = 'Nullability difference';
  SET DEC_1 = 2.8764;
  SET DEC_2 = NULL;
  CALL DB2UNIT.ASSERT_DEC_EQUALS(DEC_1, DEC_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Actual  : NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'Expected: "' || DEC_1 || '"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_dec_null with null.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_10()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE DECFLOAT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET VALUE = NULL;
  CALL DB2UNIT.ASSERT_DEC_NULL(VALUE);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
 END @

-- Test the assert_dec_null without null.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_11()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE DECFLOAT;

  SET EXPECTED_MSG = 'The given value is "NOT NULL"';
  SET VALUE = 8482.34;
  CALL DB2UNIT.ASSERT_DEC_NULL(VALUE);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test the assert_dec_not_null with not null.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_12()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE DECFLOAT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET VALUE = 9;
  CALL DB2UNIT.ASSERT_DEC_NOT_NULL(VALUE);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
 END @

-- Test the assert_dec_not_null without not null.
CREATE OR REPLACE PROCEDURE TEST_DECIMAL_13()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE VALUE DECFLOAT;

  SET EXPECTED_MSG = 'The given value is "NULL"';
  SET VALUE = NULL;
  CALL DB2UNIT.ASSERT_DEC_NOT_NULL(VALUE);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS
    WHERE MESSAGE = 'DEC_NOT_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_NUMBER.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @
