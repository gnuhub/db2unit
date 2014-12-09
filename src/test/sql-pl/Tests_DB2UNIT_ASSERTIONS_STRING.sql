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

SET CURRENT SCHEMA DB2UNIT_ASSERTIONS_STRING @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", DB2UNIT_1, DB2UNIT_ASSERTIONS_STRING @

/**
 * Tests for String assertions.
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

ALTER TABLE DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
  ALTER COLUMN SUITE_NAME
  SET WITH DEFAULT 'DB2UNIT_ASSERTIONS_STRING' @

-- STRING

-- Tests that no message is inserted in the report when two strings are equals
-- in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_01()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET STR_1 = 'String';
  SET STR_2 = 'String';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different strings with same length in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_02()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different strings, the first being longer than the second one in
-- assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_03()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Strings have different lengths';
  SET STR_1 = 'String-LONG';
  SET STR_2 = 'String';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String-LONG"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test two different strings, the second being longer than the first one in
-- assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_04()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Strings have different lengths';
  SET STR_1 = 'String';
  SET STR_2 = 'String-LONG';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String-LONG"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test both strings as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_05()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET STR_1 = NULL;
  SET STR_2 = NULL;
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test first string as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_06()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Nullability difference';
  SET STR_1 = NULL;
  SET STR_2 = 'String';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test second string as null in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_07()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'Nullability difference';
  SET STR_1 = 'String';
  SET STR_2 = NULL;
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test a string that should be truncated in assert_equals.
CREATE OR REPLACE PROCEDURE TEST_STRING_08()
 BEGIN
  DECLARE ACTUAL_MSG_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE ACTUAL_MSG_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET STR = '123456789012345678901234567890123456789012345678901234567890123456'
    || '78901234567890123456789012345678901234567890123456789012345678901234567'
    || '89012345678901234567890123456789012345678901234567890123456789012345678'
    || '90123456789012345678901234567890123456789012345678901234567890123456789'
    || '01234567890123456789012345678901234567890123456789012345678901234567890'
    || '123456789012345678901234567890';

  SET STR_1 = STR;
  SET STR_2 = STR || '1';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SET EXPECTED_MSG_1 = 'Actl truncated: "' || SUBSTR(STR, 1, 100) || '"..."'
    || SUBSTR(STR, LENGTH(STR) - 99) || '1"';
  SELECT MESSAGE INTO ACTUAL_MSG_1
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG_1
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SET EXPECTED_MSG_2 = 'Expd truncated: "' || SUBSTR(STR, 1, 100) || '"..."'
    || SUBSTR(STR, LENGTH(STR) - 100) || '"';
  SELECT MESSAGE INTO ACTUAL_MSG_2
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG_2
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Strings have different lengths'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG_1, ACTUAL_MSG_1);
  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG_2, ACTUAL_MSG_2);
 END@

-- Test the assert_equals with null message.
CREATE OR REPLACE PROCEDURE TEST_STRING_09()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(NULL, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with empty message.
CREATE OR REPLACE PROCEDURE TEST_STRING_10()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS('', STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with whitespace message.
CREATE OR REPLACE PROCEDURE TEST_STRING_11()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET EXPECTED_MSG = 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(' ', STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with message.
CREATE OR REPLACE PROCEDURE TEST_STRING_12()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Text';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message.
CREATE OR REPLACE PROCEDURE TEST_STRING_13()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Text text text text text text text text text text text.';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - no extra chars.
CREATE OR REPLACE PROCEDURE TEST_STRING_14()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3at';
  SET EXPECTED_MSG = MSG || 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - with dot.
CREATE OR REPLACE PROCEDURE TEST_STRING_15()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3a';
  SET EXPECTED_MSG = MSG || '.The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - with extra chars (. ).
CREATE OR REPLACE PROCEDURE TEST_STRING_16()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - no extra chars.
CREATE OR REPLACE PROCEDURE TEST_STRING_17()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex'' tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3at';
  SET EXPECTED_MSG = MSG || 'The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - with dot.
CREATE OR REPLACE PROCEDURE TEST_STRING_18()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex'' tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3a';
  SET EXPECTED_MSG = MSG || '.The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message - with extra chars (. ).
CREATE OR REPLACE PROCEDURE TEST_STRING_19()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Tex'' tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Test the assert_equals with long message.
CREATE OR REPLACE PROCEDURE TEST_STRING_20()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE RAISED_433 BOOLEAN; -- String too long.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22001'
    SET RAISED_433 = TRUE;

  CALL DB2UNIT.REGISTER_MESSAGE('String too long');
  SET MSG = 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3 tex4 tex5 tex6 tex7 tex8 tex9 tex0 tex1 tex2 '
    || 'Tex1 tex2 tex3ate';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE(RAISED_433);
 END@

-- Test the assert_string_null with null.
CREATE OR REPLACE PROCEDURE TEST_STRING_21()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STRING ANCHOR DB2UNIT_1.MAX_VALUES.MESSAGE_ASSERT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET STRING = NULL;
  CALL DB2UNIT.ASSERT_STRING_NULL(STRING);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
 END @

-- Test the assert_string_null without null.
CREATE OR REPLACE PROCEDURE TEST_STRING_22()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STRING ANCHOR DB2UNIT_1.MAX_VALUES.MESSAGE_ASSERT;

  SET EXPECTED_MSG = 'The given string is "NOT NULL"';
  SET STRING = 'Message';
  CALL DB2UNIT.ASSERT_STRING_NULL(STRING);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test the assert_string_not_null with not null.
CREATE OR REPLACE PROCEDURE TEST_STRING_23()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STRING ANCHOR DB2UNIT_1.MAX_VALUES.MESSAGE_ASSERT;

  SET EXPECTED_MSG = 'Message check';
  INSERT INTO DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS (DATE, EXECUTION_ID,
    TEST_NAME, MESSAGE) VALUES (CURRENT TIMESTAMP, 0, '', EXPECTED_MSG);
  SET STRING = 'Message';
  CALL DB2UNIT.ASSERT_STRING_NOT_NULL(STRING);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE EXECUTION_ID = 0
    AND MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
 END @

-- Test the assert_string_not_null without not null.
CREATE OR REPLACE PROCEDURE TEST_STRING_24()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STRING ANCHOR DB2UNIT_1.MAX_VALUES.MESSAGE_ASSERT;

  SET EXPECTED_MSG = 'The given string is "NULL"';
  SET STRING = NULL;
  CALL DB2UNIT.ASSERT_STRING_NOT_NULL(STRING);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_NOT_NULL'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test the assert_equals with a message with single quotes.
CREATE OR REPLACE PROCEDURE TEST_STRING_25()
 BEGIN
  DECLARE ACTUAL_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE EXPECTED_MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE MSG ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_1 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;
  DECLARE STR_2 ANCHOR DB2UNIT_1.REPORT_TESTS.MESSAGE;

  SET MSG = 'Text '' quote';
  SET EXPECTED_MSG = MSG || '. The content of both strings is different';
  SET STR_1 = 'String1';
  SET STR_2 = 'String2';
  CALL DB2UNIT.ASSERT_STRING_EQUALS(MSG, STR_1, STR_2);
  CALL DB2UNIT.BACK_TO_EXECUTING();

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Actual        : "String2"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'Expected      : "String1"'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  SELECT MESSAGE INTO ACTUAL_MSG
    FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE DATE = (SELECT MAX(DATE)
      FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = EXPECTED_MSG
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);
  DELETE FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS
    WHERE MESSAGE = 'STRING_EQUALS'
    AND DATE = (SELECT MAX(DATE) FROM DB2UNIT_ASSERTIONS_STRING.REPORT_TESTS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS(EXPECTED_MSG, ACTUAL_MSG);
 END@

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

