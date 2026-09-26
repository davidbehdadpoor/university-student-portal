
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    static final String DATABASE = System.getenv("PORTAL_DB_URL");
    static final String USERNAME = System.getenv("PORTAL_DB_USER");
    static final String PASSWORD = System.getenv("PORTAL_DB_PASSWORD");

    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }

    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode) {
        String sql = "INSERT INTO Registrations (student, course) VALUES (?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, student);
            ps.setString(2, courseCode);
            int affectedRows = ps.executeUpdate();

            if (affectedRows > 0)
                return "{\"success\":true}";
            else
                return "{\"success\":false, \"error\":\"Registration failed.\"}";
        }

        catch (SQLException e) {
            return "{\"success\":false, \"error\":\"" + getError(e) + "\"}";
        }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a
    // String)
    public String unregister(String student, String courseCode) {
        String sql = "DELETE FROM Registrations WHERE student = ? AND course = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, student);
            ps.setString(2, courseCode);
            int affectedRows = ps.executeUpdate();

            if (affectedRows > 0)
                return "{\"success\":true}";
            else
                return "{\"success\":false, \"error\":\"failed to unregister.\"}";

        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\"" + getError(e) + "\"}";
        }
    }

    // Return a JSON document containing lots of information about a student, it
    // should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException {
        String sql = """
                    SELECT jsonb_build_object(
                        'student', bi.idnr,
                        'name', bi.name,
                        'login', bi.login,
                        'program', bi.program,
                        'branch', bi.branch,
                        'finished', (SELECT COALESCE(
                            jsonb_agg(
                                jsonb_build_object(
                                    'course', fc.coursename,
                                    'code', fc.course,
                                    'credits', fc.credits,
                                    'grade', fc.grade
                                )
                            ), '[]'::jsonb
                        ) FROM FinishedCourses fc WHERE fc.student = bi.idnr),
                        'registered', (SELECT COALESCE(
                            jsonb_agg(
                                jsonb_build_object(
                                    'course', c.name,
                                    'code', r.course,
                                    'status', r.status,
                                    'position', CASE WHEN r.status = 'waiting' THEN wl.position ELSE NULL END

                                )
                            ), '[]'::jsonb
                        ) FROM Registrations r
                          JOIN Courses c ON r.course = c.code
                          LEFT JOIN WaitingList wl ON r.student = wl.student AND r.course = wl.course
                          WHERE r.student = bi.idnr),
                        'seminarCourses', COALESCE(pg.seminarCourses, 0),
                        'mathCredits', COALESCE(pg.mathCredits, 0),
                        'totalCredits', COALESCE(pg.totalCredits, 0),
                        'canGraduate', COALESCE(pg.qualified, false)
                    ) AS jsondata
                    FROM BasicInformation bi
                    LEFT JOIN PathToGraduation pg ON bi.idnr = pg.student
                    WHERE bi.idnr = ?
                    GROUP BY bi.idnr, bi.name, bi.login, bi.program, bi.branch,
                             pg.seminarCourses, pg.mathCredits, pg.totalCredits, pg.qualified;
                """;

        try (PreparedStatement st = conn.prepareStatement(sql)) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();

            if (rs.next()) {
                return rs.getString("jsondata");
            } else {
                return "{\"error\": \"Student not found\"}";
            }
        }
    }

    // This is a hack to turn an SQLException into a JSON string error message. No
    // need to change.
    public static String getError(SQLException e) {
        String message = e.getMessage();
        int ix = message.indexOf('\n');
        if (ix > 0)
            message = message.substring(0, ix);
        message = message.replace("\"", "\\\"");
        return message;
    }
}