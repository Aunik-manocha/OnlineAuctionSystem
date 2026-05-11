package com.cs336.pkg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ApplicationDB {

    public ApplicationDB() { }

    public Connection getConnection() {

        // ✅ updated connection string
    	String connectionUrl = "jdbc:mysql://localhost:3306/cs336"
    		    + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";


        Connection connection = null;

        try {
            // ✅ modern MySQL Connector/J driver class name
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // ✅ use your actual username and password here
            connection = DriverManager.getConnection(connectionUrl, "cs336", "cs336pwd");
            //  or use root if you prefer:
            //  connection = DriverManager.getConnection(connectionUrl, "root", "YourPassword");
            
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return connection;
    }

    public void closeConnection(Connection connection) {
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) {
        ApplicationDB dao = new ApplicationDB();
        Connection connection = dao.getConnection();

        System.out.println(connection);
        dao.closeConnection(connection);
    }
}
