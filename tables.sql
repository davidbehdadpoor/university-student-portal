CREATE TABLE Programs (
    name TEXT PRIMARY KEY,
    abbreviation VARCHAR(20) NOT NULL

);

CREATE TABLE Departments (
    name TEXT PRIMARY KEY,
    abbreviation VARCHAR(20) NOT NULL
);

CREATE TABLE ProgramDepartments (
    program TEXT,
    department TEXT,
    PRIMARY KEY(program, department),
    FOREIGN KEY(program) REFERENCES Programs(name),
    FOREIGN KEY(department) REFERENCES Departments(name)

);

CREATE TABLE Branches (
   name TEXT,
   program TEXT,
   PRIMARY KEY(name, program),
   FOREIGN KEY(program) REFERENCES Programs(name)
);



CREATE TABLE Students (
    idnr VARCHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login VARCHAR(10) NOT NULL,
    program TEXT NOT NULL,
    UNIQUE(login),
    FOREIGN KEY (program) REFERENCES Programs(name),
    UNIQUE(idnr,program)
);




CREATE TABLE Courses(
    code VARCHAR(6),
    name TEXT NOT NULL,
    credits REAL NOT NULL,
    department TEXT NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (department) REFERENCES Departments(name)
    
);

CREATE TABLE Prerequisites(
    course VARCHAR(6),
    prerequisite_course VARCHAR(6),
    PRIMARY KEY(course, prerequisite_course),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (prerequisite_course) REFERENCES Courses(code)
);

CREATE TABLE LimitedCourses(
    code VARCHAR(6),
    capacity INT NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE Classifications(
    name TEXT,
    PRIMARY KEY (name)
);


CREATE TABLE Classified(
    course VARCHAR(6),
    classification TEXT,
    PRIMARY KEY(course, classification),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name)
);


CREATE TABLE StudentBranches(
    student VARCHAR(10),
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY(student),
    FOREIGN KEY(student, program) REFERENCES Students(idnr, program),
    FOREIGN KEY(branch, program) REFERENCES Branches(name, program)
);


CREATE TABLE MandatoryProgram(
    course VARCHAR(6),
    program TEXT,
    PRIMARY KEY(course, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (program) REFERENCES Programs(name)
);


CREATE TABLE MandatoryBranch(
    course VARCHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course,branch, program),
    FOREIGN KEY(course) REFERENCES Courses(code),
    FOREIGN KEY(branch, program) REFERENCES Branches(name, program)
);


CREATE TABLE RecommendedBranch(
    course VARCHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course,branch, program),
    FOREIGN KEY(course) REFERENCES Courses(code),
    FOREIGN KEY(branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Taken(
    student VARCHAR(10),
    course VARCHAR(6),
    grade CHAR(1) NOT NULL,
    PRIMARY KEY(student, course),
    FOREIGN KEY(student) REFERENCES Students(idnr),
    FOREIGN KEY(course) REFERENCES Courses(code),
    CHECK(grade IN ('U','3','4','5'))
);

CREATE TABLE Registered(
    student VARCHAR(10),
    course VARCHAR(6),
    PRIMARY KEY(student, course),
    FOREIGN KEY(student) REFERENCES Students(idnr),
    FOREIGN KEY(course) REFERENCES Courses(code)
);


CREATE TABLE WaitingList(
    student VARCHAR(10),
    course VARCHAR(6),
    position INT NOT NULL,
    PRIMARY KEY(student, course),
    FOREIGN KEY(student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses (code),
    UNIQUE(course, position)

);

  