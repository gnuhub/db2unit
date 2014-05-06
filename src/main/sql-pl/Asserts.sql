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
 * Asserts implementation.
 * Return codes:
 * 0 - OK
 * 1 - Nullability difference.
 * 2 - Different values.
 * 3 - Different length.
 * 4 - Invalid value.
 * 5 - Opposite nullability.
 *
 * Version: 2014-05-02 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

/**
 * Max size for assertion messages.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE MESSAGE_OVERHEAD SMALLINT CONSTANT 50 @

/**
 * Size of the chunk of a truncated string.
 */
ALTER MODULE DB2UNIT ADD
  VARIABLE MESSAGE_CHUNK SMALLINT CONSTANT 100 @

/**
 * Processes the given message.
 */
ALTER MODULE DB2UNIT ADD
  FUNCTION PROC_MESSAGE(
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT
  ) RETURNS ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT
  LANGUAGE SQL
  SPECIFIC F_PROC_MESSAGE
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_PROC_MESSAGE: BEGIN
  IF (MESSAGE = '') THEN
   SET MESSAGE = NULL;
  END IF;
  SET MESSAGE = COALESCE(MESSAGE || '. ', '');
  RETURN MESSAGE;
 END F_PROC_MESSAGE @

/**
 * Returns a character representation of the given boolean.
 *
 * IN VALUE
 *   Value to convert.
 * RETURN
 *   The corresponding represtation of the given boolean.
 */
ALTER MODULE DB2UNIT ADD
  FUNCTION BOOL_TO_CHAR(
  IN VALUE BOOLEAN
  ) RETURNS CHAR(5)
  LANGUAGE SQL
  SPECIFIC F_BOOL_TO_CHAR
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_BOOL_TO_CHAR: BEGIN
  DECLARE RET CHAR(5) DEFAULT 'FALSE';

  IF (VALUE IS NULL) THEN
    SET RET = 'NULL';
  ELSEIF (VALUE = TRUE) THEN
   SET RET = 'TRUE';
  END IF;
  RETURN RET;
 END F_BOOL_TO_CHAR @

-- GENERAL

/**
 * Fails the current message giving a reason in the message.
 *
 * IN MESSAGE
 *   Related message to the fail.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE FAIL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT
  )
  LANGUAGE SQL
  SPECIFIC P_FAIL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_FAIL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_FAIL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);

  CALL WRITE_IN_REPORT (MESSAGE || 'Test failed');
  SET TEST_RESULT = RESULT_FAILED;
  SET RET = 1;

  RETURN RET;
 END P_FAIL_MESSAGE @

-- STRING

/**
 * Asserts if the given two strings are the same, in nullability, in length and
 * in content.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN EXPECTED
 *   Expected boolean.
 * IN ACTUAL
 *   Actual boolean.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_STRING_EQUALS (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN EXPECTED ANCHOR DB2UNIT_1A.MAX_STRING.STRING,
  IN ACTUAL ANCHOR DB2UNIT_1A.MAX_STRING.STRING
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_STRING_EQUALS_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_STRING_EQUALS_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE SHOW BOOLEAN DEFAULT FALSE;
  DECLARE LENGTH SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_STRING_EQUALS_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, EXPECTED);
  CALL LOGGER.DEBUG(LOGGER_ID, ACTUAL);

  -- Check values.
  IF ((EXPECTED IS NULL AND ACTUAL IS NOT NULL)
    OR (EXPECTED IS NOT NULL AND ACTUAL IS NULL)) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'Nullability difference');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 1;
  ELSEIF (LENGTH(EXPECTED) <> LENGTH(ACTUAL)) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'Strings have different lengths');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 3;
  ELSEIF (EXPECTED <> ACTUAL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The content of both strings is different');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 2;
  END IF;

  -- Show problems.
  IF (SHOW = TRUE) THEN
   IF (EXPECTED IS NOT NULL) THEN
    SET LENGTH = LENGTH(EXPECTED);
    IF (LENGTH < MAX_MESSAGE - MESSAGE_OVERHEAD) THEN
     CALL WRITE_IN_REPORT ('Expected      : "' || EXPECTED || '"');
    ELSE
     SET EXPECTED = SUBSTR(EXPECTED, 1, MESSAGE_CHUNK) || '"..."'
       || SUBSTR(EXPECTED, LENGTH - MESSAGE_CHUNK);
     CALL WRITE_IN_REPORT ('Expd truncated: "' || EXPECTED || '"');
    END IF;
   ELSE
    CALL WRITE_IN_REPORT ('Expected      : NULL');
   END IF;
   IF (ACTUAL IS NOT NULL) THEN
    SET LENGTH = LENGTH(ACTUAL);
    IF (LENGTH < MAX_MESSAGE - MESSAGE_OVERHEAD) THEN
     CALL WRITE_IN_REPORT ('Actual        : "' || ACTUAL || '"');
    ELSE
     SET ACTUAL = SUBSTR(ACTUAL, 1, MESSAGE_CHUNK) || '"..."'
       || SUBSTR(ACTUAL, LENGTH - MESSAGE_CHUNK);
     CALL WRITE_IN_REPORT ('Actl truncated: "' || ACTUAL || '"');
    END IF;
   ELSE
    CALL WRITE_IN_REPORT ('Actual        : NULL');
   END IF;
  END IF;

  RETURN RET;
 END P_ASSERT_STRING_EQUALS_MESSAGE @

/**
 * Asserts if the given string is null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN STRING
 *   Value to check if it is null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_STRING_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN STRING ANCHOR DB2UNIT_1A.MAX_STRING.STRING
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_STRING_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_STRING_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_STRING_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, STRING);

  -- Check value.
  IF (STRING IS NOT NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given string is "NOT NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_STRING_NULL_MESSAGE @

/**
 * Asserts if the given string is not null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN STRING
 *   Value to check if it is not null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_STRING_NOT_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN STRING ANCHOR DB2UNIT_1A.MAX_STRING.STRING
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_STRING_NOT_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_STRING_NOT_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_STRING_NOT_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, STRING);

  -- Check value.
  IF (STRING IS NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given string is "NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_STRING_NOT_NULL_MESSAGE @

-- BOOLEAN

/**
 * Asserts if the given two booleans are the same, in nullability and in
 * content.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN EXPECTED
 *   Expected boolean.
 * IN ACTUAL
 *   Actual boolean.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_BOOLEAN_EQUALS (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN EXPECTED BOOLEAN,
  IN ACTUAL BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_BOOLEAN_EQUALS_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_BOOLEAN_EQUALS_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE SHOW BOOLEAN DEFAULT FALSE;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_BOOLEAN_EQUALS_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(EXPECTED));
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(ACTUAL));

  -- Check values.
  IF ((EXPECTED IS NULL AND ACTUAL IS NOT NULL)
    OR (EXPECTED IS NOT NULL AND ACTUAL IS NULL)) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'Nullability difference');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 1;
  ELSEIF (EXPECTED <> ACTUAL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The value of both booleans is different');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 2;
  END IF;

  -- Show problems.
  IF (SHOW = TRUE) THEN
   IF (EXPECTED IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Expected: "' || BOOL_TO_CHAR(EXPECTED) || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Expected: NULL');
   END IF;
   IF (ACTUAL IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Actual  : "' || BOOL_TO_CHAR(ACTUAL) || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Actual  : NULL');
   END IF;
  END IF;

  RETURN RET;
 END P_ASSERT_BOOLEAN_EQUALS_MESSAGE @

/**
 * Asserts if the given value is true.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN CONDITION
 *   Value to check against TRUE.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_BOOLEAN_TRUE (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN CONDITION BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_BOOLEAN_TRUE_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_BOOLEAN_TRUE_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_BOOLEAN_TRUE_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(CONDITION));

  -- Check value.
  IF (CONDITION = FALSE) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "FALSE"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 4;
  END IF;

  RETURN RET;
 END P_ASSERT_BOOLEAN_TRUE_MESSAGE @

/**
 * Asserts if the given value is false.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN CONDITION
 *   Value to check against FALSE.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_BOOLEAN_FALSE (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN CONDITION BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_BOOLEAN_FALSE_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_BOOLEAN_FALSE_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_BOOLEAN_FALSE_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(CONDITION));

  -- Check value.
  IF (CONDITION = TRUE) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "TRUE"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 4;
  END IF;

  RETURN RET;
 END P_ASSERT_BOOLEAN_FALSE_MESSAGE @

/**
 * Asserts if the given boolean is null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN CONDITION
 *   Value to check if it is null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_BOOLEAN_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN CONDITION BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_BOOLEAN_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_BOOLEAN_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_BOOLEAN_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(CONDITION));

  -- Check value.
  IF (CONDITION IS NOT NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NOT NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_BOOLEAN_NULL_MESSAGE @

/**
 * Asserts if the given boolean is not null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN CONDITION
 *   Value to check if it is not null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_BOOLEAN_NOT_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN CONDITION BOOLEAN
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_BOOLEAN_NOT_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_BOOLEAN_NOT_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_BOOLEAN_NOT_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, BOOL_TO_CHAR(CONDITION));

  -- Check value.
  IF (CONDITION IS NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_BOOLEAN_NOT_NULL_MESSAGE @

-- INTEGER

/**
 * Asserts if the given two int are the same, in nullability and in content.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN EXPECTED
 *   Expected int.
 * IN ACTUAL
 *   Actual int.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_INT_EQUALS (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN EXPECTED BIGINT,
  IN ACTUAL BIGINT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_INT_EQUALS_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_INT_EQUALS_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE SHOW BOOLEAN DEFAULT FALSE;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_INT_EQUALS_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, EXPECTED);
  CALL LOGGER.DEBUG(LOGGER_ID, ACTUAL);

  -- Check values.
  IF ((EXPECTED IS NULL AND ACTUAL IS NOT NULL)
    OR (EXPECTED IS NOT NULL AND ACTUAL IS NULL)) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'Nullability difference');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 1;
  ELSEIF (EXPECTED <> ACTUAL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The value of both integers is different');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 2;
  END IF;

  -- Show problems.
  IF (SHOW = TRUE) THEN
   IF (EXPECTED IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Expected: "' || EXPECTED || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Expected: NULL');
   END IF;
   IF (ACTUAL IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Actual  : "' || ACTUAL || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Actual  : NULL');
   END IF;
  END IF;

  RETURN RET;
 END P_ASSERT_INT_EQUALS_MESSAGE @

/**
 * Asserts if the given value is null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN VALUE
 *   Value to check if it is null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_INT_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN VALUE BIGINT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_INT_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_INT_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_INT_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, VALUE);

  -- Check value.
  IF (VALUE IS NOT NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NOT NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_INT_NULL_MESSAGE @

/**
 * Asserts if the given int is not null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN VALUE
 *   Value to check if it is not null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_INT_NOT_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN VALUE BIGINT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_INT_NOT_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_INT_NOT_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_INT_NOT_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, VALUE);

  -- Check value.
  IF (VALUE IS NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_INT_NOT_NULL_MESSAGE @

-- DECIMAL

/**
 * Asserts if the given two decimals are the same, in nullability and in
 * content.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN EXPECTED
 *   Expected decimal.
 * IN ACTUAL
 *   Actual decimal.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_DEC_EQUALS (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN EXPECTED DECFLOAT,
  IN ACTUAL DECFLOAT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_DEC_EQUALS_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_DEC_EQUALS_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE SHOW BOOLEAN DEFAULT FALSE;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_DEC_EQUALS_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, EXPECTED);
  CALL LOGGER.DEBUG(LOGGER_ID, ACTUAL);

  -- Check values.
  IF ((EXPECTED IS NULL AND ACTUAL IS NOT NULL)
    OR (EXPECTED IS NOT NULL AND ACTUAL IS NULL)) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'Nullability difference');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 1;
  ELSEIF (EXPECTED <> ACTUAL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The value of both decimals is different');
   SET SHOW = TRUE;
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 2;
  END IF;

  -- Show problems.
  IF (SHOW = TRUE) THEN
   IF (EXPECTED IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Expected: "' || EXPECTED || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Expected: NULL');
   END IF;
   IF (ACTUAL IS NOT NULL) THEN
    CALL WRITE_IN_REPORT ('Actual  : "' || ACTUAL || '"');
   ELSE
    CALL WRITE_IN_REPORT ('Actual  : NULL');
   END IF;
  END IF;

  RETURN RET;
 END P_ASSERT_DEC_EQUALS_MESSAGE @

/**
 * Asserts if the given value is null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN VALUE
 *   Value to check if it is null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_DEC_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN VALUE DECFLOAT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_DEC_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_DEC_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_DEC_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, VALUE);

  -- Check value.
  IF (VALUE IS NOT NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NOT NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_DEC_NULL_MESSAGE @

/**
 * Asserts if the given decimal is not null.
 *
 * IN MESSAGE
 *   Related message to the test.
 * IN VALUE
 *   Value to check if it is not null.
 */
ALTER MODULE DB2UNIT ADD
  PROCEDURE ASSERT_DEC_NOT_NULL (
  IN MESSAGE ANCHOR DB2UNIT_1A.MAX_VALUES.MESSAGE_ASSERT,
  IN VALUE DECFLOAT
  )
  LANGUAGE SQL
  SPECIFIC P_ASSERT_DEC_NOT_NULL_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ASSERT_DEC_NOT_NULL_MESSAGE: BEGIN
  DECLARE LOGGER_ID SMALLINT;
  DECLARE RET INT;

  CALL LOGGER.GET_LOGGER('DB2UNIT_1A.DB2UNIT.P_ASSERT_DEC_NOT_NULL_MESSAGE',
    LOGGER_ID);
  -- Pre process
  SET MESSAGE = PROC_MESSAGE(MESSAGE);
  SET RET = 0;
  CALL LOGGER.DEBUG(LOGGER_ID, MESSAGE);
  CALL LOGGER.DEBUG(LOGGER_ID, VALUE);

  -- Check value.
  IF (VALUE IS NULL) THEN
   CALL WRITE_IN_REPORT (MESSAGE || 'The given value is "NULL"');
   SET TEST_RESULT = RESULT_FAILED;
   SET RET = 5;
  END IF;

  RETURN RET;
 END P_ASSERT_DEC_NOT_NULL_MESSAGE @

