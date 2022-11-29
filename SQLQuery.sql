

USE Laba_10
GO

/* ================================= */
/* =============== 1 =============== */

CREATE PROCEDURE PROC_INSERT
AS

	INSERT INTO Learn
		VALUES	(1001, 'Клемен Володимир Степанович',	120),
				(1002, 'Ткачук Лідія Володимирівна',	180),
				(1003, 'Волинь Дмитро Іванович',		240),
				(1004, 'Кручицька Єлизавета Степанович', 80),
				(1005, 'Ігнатенко Віктор Степанович',	290),
				(1006, 'Пташка Андрій Васильович',		300),
				(1007, 'Бігунова Світлана Миколаївна',	140),
				(1008, 'Тоненчук Анастасія Дмитрівна',	380),
				(1009, 'Світлий Валентин Ігорович',		170),
				(1010, 'Тараненко Світлана Юріївна',	340);

	INSERT INTO Student
		VALUES	(10001, 120, 'Сніжана',		'Немірова',		'2003/02/02'),
				(10002, 144, 'Кирил',		'Арнаутов',		'2004/04/15'),
				(10003, 143, 'Нестор',		'Кришко',		'2004/10/29'),
				(10004, 120, 'Тетяна',		'Колчанова',	'2002/08/16'),
				(10005, 122, 'Марія',		'Задорожна',	'2004/05/08'),
				(10006, 141, 'Павло',		'Іванов',		'2003/04/10'),
				(10007, 144, 'Владислав',	'Яремак',		'2003/12/28'),
				(10008, 141, 'Марина',		'Сиримак',		'2004/07/19'),
				(10009, 122, 'Олександр',	'Андрищак',		'2004/03/18'),
				(10010, 121, 'Віталій',		'Веркаш',		'2003/07/01'),
				(10011, 120, 'Юлія',		'Панчук',		'2004/10/15');

	INSERT INTO SubjectSuccess
		VALUES	(10001, 1007, '2'),
				(10003, 1009, '5'),
				(10010, 1010, '3'),
				(10008, 1003, '4'),
				(10011, 1008, NULL),
				(10008, 1001, '5'),
				(10009, 1007, '2'),
				(10004, 1002, NULL),
				(10005, 1005, '4'),
				(10007, 1001, '3');

GO

CREATE PROCEDURE PROC_DELETE
AS

	DELETE S FROM Student S
	WHERE 3 <= 
				(
					SELECT COUNT(SS.Rating)
					FROM SubjectSuccess SS
					WHERE S.StudID = SS.StudID AND SS.Rating = '2'
				)

GO

CREATE PROCEDURE PROC_UPDATE
AS

	UPDATE SubjectSuccess
		SET Rating = 'перездача'
		WHERE	(
					SELECT COUNT(SS.Rating)
					FROM SubjectSuccess SS
					WHERE SubjectSuccess.StudID = SS.StudID AND
					SubjectSuccess.PredmetID = SS.PredmetID AND SS.Rating = '2'
				) BETWEEN 1 AND 2

GO


EXEC PROC_INSERT
EXEC PROC_DELETE
EXEC PROC_UPDATE
GO

DROP PROCEDURE PROC_INSERT
DROP PROCEDURE PROC_DELETE
DROP PROCEDURE PROC_UPDATE
GO

/* ================================= */
/* =============== 2 =============== */

CREATE PROCEDURE PROC_CREATE_TABLE
AS
 
	SELECT TOP(5) S.StudID, S.FirstName, S.LastName, S.Groupid, SS.PredmetID, L.TeacherName
	INTO TheBestOfTheBest
	FROM Student S, SubjectSuccess SS, Learn L
	WHERE S.StudID = SS.StudID AND SS.PredmetID = L.PredmetID
	ORDER BY SS.Rating DESC

GO

EXEC PROC_CREATE_TABLE
GO

DROP PROCEDURE PROC_CREATE_TABLE
GO

/* ================================= */
/* =============== 3 =============== */

CREATE PROCEDURE PROC_CREATE_NEW_RECORD
	@TeacherName NVARCHAR(50),
	@HoursCount INT
AS

INSERT INTO Learn
	VALUES (@TeacherName, @HoursCount);

GO

EXEC PROC_CREATE_NEW_RECORD 'Ткаченко Владислав Ігорович', 210
GO

DROP PROCEDURE PROC_CREATE_NEW_RECORD
GO

/* ================================= */
/* =============== 4 =============== */

CREATE PROCEDURE PROC_UPDATE_VALUES
	@TeacherName NVARCHAR(50),
	@HoursCount INT = 100
AS
	UPDATE Learn
	SET HoursCount = @HoursCount
	WHERE TeacherName = @TeacherName AND PredmetID IN 
											/* чіпається самий останній запис цього викладача */
											(SELECT MAX(L.PredmetID)
											 FROM Learn L
											 WHERE L.TeacherName = TeacherName)
GO

EXEC PROC_UPDATE_VALUES 'Ткаченко Владислав Ігорович', 110
GO

DROP PROCEDURE PROC_UPDATE_VALUES
GO

/* ================================= */
/* =============== 5 =============== */


CREATE TRIGGER TR_CHECK_IN_LEARN
ON Learn 
AFTER INSERT
AS
IF @@ROWCOUNT = 1
	BEGIN
		IF	EXISTS (
						SELECT TeacherName
						FROM Learn
						GROUP BY TeacherName
						HAVING SUM(HoursCount) > 500
					)
			BEGIN
				ROLLBACK TRAN
				PRINT 'Error.The trigger TR_CHECK_IN_LEARN worked.The teacher has more hours than 500'
			END
			ELSE PRINT 'Data added successfully'
	END
GO

CREATE TRIGGER TR_CHECK_IN_STUDENT
ON SubjectSuccess 
AFTER INSERT
AS
IF @@ROWCOUNT > 0
	BEGIN
		IF	EXISTS (
						SELECT S.FirstName, S.LastName, SUM(L.HoursCount)
						FROM Learn L, Student S, SubjectSuccess SS
						WHERE S.StudID = SS.StudID AND SS.PredmetID = L.PredmetID
						GROUP BY S.FirstName, S.LastName
						HAVING SUM(L.HoursCount) > 1000
					)
			BEGIN
				ROLLBACK
				PRINT 'Error.The trigger TR_CHECK_IN_STUDENT worked.The student has more hours than 1000'
			END
		ELSE PRINT 'Data added successfully'
	END
GO

INSERT INTO SubjectSuccess
			VALUES	(10005,10001,'2'),
					(10005,10002,'2'),
					(10005,10003,'2'),
					(10005,10004,'2'),
					(10005,10006,'2'),
					(10005,10007,'2'),
					(10005,10008,'2');
GO

DELETE SubjectSuccess

EXEC PROC_CREATE_NEW_RECORD 'Ткаченко Владислав Ігорович', 210
GO

DROP TRIGGER TR_CHECK_IN_LEARN
DROP TRIGGER TR_CHECK_IN_STUDENT
GO
