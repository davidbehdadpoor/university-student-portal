CREATE VIEW BasicInformation AS
SELECT 
    Students.idnr,
    Students.name,
    Students.login,
    Students.program,
    StudentBranches.branch
FROM Students LEFT JOIN StudentBranches
ON Students.idnr = StudentBranches.student;

CREATE VIEW FinishedCourses AS
SELECT 
    Taken.student, 
    Taken.course, 
    Courses.name AS coursename, 
    Taken.grade, 
    Courses.credits 
FROM Taken JOIN Courses
ON Taken.course = Courses.code;

CREATE VIEW Registrations AS
SELECT 
student, 
course, 
'registered' AS status 
FROM Registered 

UNION

SELECT 
student, 
course, 
'waiting' AS status 
FROM WaitingList;

CREATE VIEW PassedCourses AS
SELECT student, course, credits FROM FinishedCourses WHERE grade != 'U';

CREATE VIEW UnreadMandatory AS
SELECT t1.student, t1.course
FROM (
    SELECT idnr AS student, course 
    FROM Students JOIN MandatoryProgram 
    USING (program)
    UNION 
    SELECT student, course
    FROM StudentBranches JOIN MandatoryBranch
    USING(program, branch)
) AS t1
EXCEPT SELECT t2.student, t2.course
FROM PassedCourses t2;



CREATE VIEW RecommendedCourses AS
SELECT sb.student, rb.course, c.credits
FROM StudentBranches AS sb JOIN RecommendedBranch AS rb
ON 
    sb.branch = rb.branch AND sb.program = rb.program
JOIN Courses c
ON 
    rb.course = c.code
JOIN PassedCourses AS pc
ON 
    sb.student = pc.student AND rb.course = pc.course;

CREATE VIEW TotalCredits AS
SELECT student, SUM(credits) AS totalCredits
FROM PassedCourses
GROUP BY student;

CREATE VIEW MandatoryLeft AS
SELECT student, COUNT(*) AS mandatoryLeft
FROM UnreadMandatory 
GROUP BY student;

CREATE VIEW MathCredits AS
SELECT student, SUM(credits) AS mathCredits
FROM PassedCourses
WHERE course IN(SELECT Classified.course FROM Classified WHERE Classified.classification = 'math')
GROUP BY student;

CREATE VIEW SeminarCourses AS
SELECT student, COUNT(*) AS seminarCourses
FROM PassedCourses
WHERE course IN(SELECT Classified.course FROM Classified WHERE Classified.classification = 'seminar')
GROUP BY student;



CREATE VIEW PathToGraduation AS
WITH RecommendedCredits AS (
    SELECT 
        rc.student, 
        SUM(rc.credits) AS recommendedcredits
    FROM 
        RecommendedCourses rc
    GROUP BY 
        rc.student
)
SELECT 
    s.idnr AS student, 
    COALESCE(tc.totalCredits, 0) AS totalCredits,
    COALESCE(ml.mandatoryLeft, 0) AS mandatoryLeft,
    COALESCE(mc.mathCredits, 0) AS mathCredits,
    COALESCE(sc.seminarCourses, 0) AS seminarCourses,
     (COALESCE(rc.recommendedcredits, 0) >= 10 
     AND COALESCE(ml.mandatoryLeft, 0) = 0 
     AND COALESCE(mc.mathCredits, 0) >= 20 
     AND COALESCE(sc.seminarCourses, 0) >= 1) AS qualified
FROM 
    Students s
LEFT JOIN 
    TotalCredits tc ON s.idnr = tc.student
LEFT JOIN 
    MandatoryLeft ml ON s.idnr = ml.student
LEFT JOIN 
    MathCredits mc ON s.idnr = mc.student
LEFT JOIN 
    SeminarCourses sc ON s.idnr = sc.student
LEFT JOIN 
    RecommendedCredits rc ON s.idnr = rc.student;

       