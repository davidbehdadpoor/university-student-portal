CREATE FUNCTION registration_trigger() RETURNS TRIGGER AS $$
    DECLARE 
        registration_status TEXT;
        pos INT;
    BEGIN
        pos := (SELECT COUNT(*) FROM WaitingList WHERE course = NEW.course)+1;
        registration_status := (SELECT status FROM Registrations WHERE student = NEW.student AND course = NEW.course);
        --Checking if the student is already registered (or waiting)
        IF registration_status = 'waiting' OR registration_status = 'registered' THEN
            RAISE EXCEPTION 'Failure: Already registered or in waiting list';
        END IF;

        --Checking if the student has already completed the course
        IF EXISTS (SELECT 1 FROM PassedCourses WHERE course = NEW.course AND student = New.student)THEN
            RAISE EXCEPTION 'Failure: Student has passed course';
        END IF;

        -- Checking if the student is missing prerequisites
        IF EXISTS (SELECT prerequisite_course FROM Prerequisites WHERE course = NEW.course 
            EXCEPT SELECT course FROM PassedCourses WHERE student = NEW.student) THEN
                RAISE EXCEPTION 'Failure: Student has not passed all the prerequisite courses.';
        END IF;

        -- Checking if a course is full
        IF EXISTS (
            SELECT 1 
            FROM LimitedCourses lc
            WHERE lc.code = NEW.course 
            AND (SELECT COUNT(*) FROM Registered r WHERE r.course = NEW.course) >= lc.capacity) THEN
                INSERT INTO WaitingList VALUES(NEW.student, NEW.course, pos);
        ELSE
            INSERT INTO Registered VALUES(NEW.student, NEW.course);
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER registration_check
INSTEAD OF INSERT ON Registrations
FOR EACH ROW
EXECUTE FUNCTION registration_trigger();


CREATE FUNCTION Deregistration_trigger() RETURNS TRIGGER AS $$
    DECLARE
        firstStudentPos INT;
        next_student TEXT;
        currentStudentPos INT;
    BEGIN
        firstStudentPos := (SELECT COALESCE(MIN(position), 0) FROM WaitingList WHERE course = OLD.course);
        -- Checking if that student is registered.
        IF EXISTS(SELECT 1 FROM Registered WHERE student = OLD.student AND course = OLD.course) THEN
            DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;

            -- Check if the course has available spots
            IF NOT EXISTS (
                SELECT 1 
                FROM LimitedCourses lc
                WHERE lc.code = OLD.course 
                AND (SELECT COUNT(*) FROM Registered r WHERE r.course = OLD.course) >= lc.capacity) THEN

                -- Checking if there is any student on the waiting list.
                IF firstStudentPos > 0 THEN 
                    SELECT student INTO next_student FROM WaitingList WHERE course = OLD.course AND position = firstStudentPos;
                    INSERT INTO Registered VALUES (next_student, OLD.course);
                    DELETE FROM WaitingList WHERE student = next_student AND course = OLD.course;     
                    UPDATE WaitingList SET position = position - 1 WHERE course = OLD.course;
                    
                END IF;  
            END IF;
        
        -- Checking if that student is in the waiting List.
        ELSEIF EXISTS(SELECT 1 FROM WaitingList WHERE student = OLD.student AND course = OLD.course) THEN
            currentStudentPos := (SELECT position FROM WaitingList WHERE course = OLD.course AND student = OLD.student);
            DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
            UPDATE WaitingList SET position = position - 1 WHERE course = OLD.course AND position > currentStudentPos;

        ELSE
            RAISE EXCEPTION 'Error: Student is neither registered nor on the waiting list.';
        END IF;
        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;
       
CREATE OR REPLACE TRIGGER Deregistration_check
INSTEAD OF DELETE ON Registrations
FOR EACH ROW
EXECUTE FUNCTION Deregistration_trigger();

