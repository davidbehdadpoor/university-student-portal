# University Student Portal

A PostgreSQL database and Java student portal for a fictional university. Completed independently as part of a database course at Chalmers University of Technology, using course-provided requirements and starter code.

The database models students, programmes, specialisations, departments and courses. It manages registration, prerequisites and waiting lists, and tracks graduation requirements based on mandatory courses, recommended courses and credits. Students can view their progress and manage registrations through a simple web interface.

Database design and supporting documentation are in `docs/`.

## Requirements

- Java 17 or newer
- PostgreSQL 17, with the server running
- Git
- [PostgreSQL JDBC driver](https://jdbc.postgresql.org/download/): create `lib/` in the project root and place one driver JAR there

Make sure `git`, `java`, `javac`, `createdb` and `psql` are available in your terminal. On Windows, you may need to add PostgreSQL's `bin` directory to `Path` and reopen the terminal.

## Clone

```sh
git clone https://github.com/davidbehdadpoor/university-student-portal.git
cd university-student-portal
```

Run the remaining commands from this directory. Choose the instructions for your terminal below.

## macOS / Linux (zsh or bash)

Replace `YOUR_DB_USER` with your PostgreSQL username:

```sh
export PORTAL_DB_USER="YOUR_DB_USER"
export PORTAL_DB_URL="jdbc:postgresql://localhost:5432/university_portal"
```

Run this command, type your PostgreSQL password and press Enter. Input is hidden:

```sh
read -s PORTAL_DB_PASSWORD
```

Then export the password:

```sh
export PORTAL_DB_PASSWORD
```

Create and initialise the database:

```sh
createdb -h localhost -U "$PORTAL_DB_USER" university_portal
psql -h localhost -U "$PORTAL_DB_USER" -d university_portal -v ON_ERROR_STOP=1 -f database/runsetup.sql
```

Compile and start the portal, with the JDBC driver in `lib/`:

```sh
mkdir -p build
javac -d build src/PortalConnection.java src/PortalServer.java
java -cp "build:lib/*" PortalServer
```

## Windows (PowerShell)

Replace `YOUR_DB_USER` with your PostgreSQL username:

```powershell
$env:PORTAL_DB_USER = "YOUR_DB_USER"
$env:PORTAL_DB_URL = "jdbc:postgresql://localhost:5432/university_portal"
$password = Read-Host "PostgreSQL password" -AsSecureString
$env:PORTAL_DB_PASSWORD = [System.Net.NetworkCredential]::new("", $password).Password
```

Create and initialise the database:

```powershell
createdb -h localhost -U $env:PORTAL_DB_USER university_portal
psql -h localhost -U $env:PORTAL_DB_USER -d university_portal -v ON_ERROR_STOP=1 -f database/runsetup.sql
```

Compile and start the portal, with the JDBC driver in `lib/`:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
javac -d build src/PortalConnection.java src/PortalServer.java
java -cp "build;lib/*" PortalServer
```

## Setup notes

- Skip `createdb` if the dedicated project database already exists. **`runsetup.sql` deletes and recreates its `public` schema**, including existing data.
- `createdb` and `psql` may ask for your PostgreSQL password separately. The `PORTAL_DB_*` variables are used by the Java application.
- All three variables must be set in the terminal used to start Java. They last for that terminal session. For an IDE launch, set them in its run configuration. The application does not load `.env` files automatically.
- Leave the password empty only if your PostgreSQL configuration permits passwordless connections for that role.

## Use the portal

Open [http://localhost](http://localhost), enter a sample student ID such as `2222222222` and click **Run**. Keep PostgreSQL and the Java server running; stop Java with **Ctrl+C**.

The server uses port 80. If the port is unavailable or permission is denied, change `PORT` in `src/PortalServer.java` to `8080`, recompile and open `http://localhost:8080`.

## Tests

After compiling the application, compile the interactive test client on any operating system:

```sh
javac -cp build -d build tests/TestPortal.java
```

Run it in the terminal where the connection variables are set:

macOS / Linux:

```sh
java -cp "build:lib/*" TestPortal
```

Windows:

```powershell
java -cp "build;lib/*" TestPortal
```

The client prints registration results, pauses between scenarios and changes the sample data. Rerun the setup script to reset it.

This is a course project for local use with sample data. The portal does not implement user authentication.
