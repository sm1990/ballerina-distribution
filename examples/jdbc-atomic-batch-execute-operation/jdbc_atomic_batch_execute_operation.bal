import ballerina/io;
import ballerina/log;
import ballerinax/java.jdbc;
import ballerina/sql;

public function main() returns error? {

    // Runs the prerequisite setup for the example.
    check initialize();

    // Initializes the JDBC client. The `jdbcClient` can be reused to access the database throughout the application execution.
    jdbc:Client jdbcClient = check new ("jdbc:h2:file:./target/bbes/java_jdbc",
        "rootUser", "rootPass");

    // The transaction block can be used to roll back if any error occurred.
    transaction {
        sql:ExecutionResult|sql:Error result1 = jdbcClient->execute(
                    `INSERT INTO Customers (firstName, lastName, 
                     registrationID, creditLimit, country) VALUES ('Linda', 
                    'Jones', 4, 10000.75, 'USA')`);
        io:println(`First query executed successfully. ${result1}`);

        // Insert Customer record which violates the unique
        sql:ExecutionResult|sql:Error result2 = jdbcClient->execute(
                `INSERT INTO Customers (firstName, lastName, registrationID,
                 creditLimit, country) VALUES ('Peter', 'Stuart', 4, 5000.75,
                 'USA')`);

        if result2 is sql:Error {
            io:println(result2.message());
            io:println("Second query failed.");
            io:println("Rollback transaction.");
            rollback;
        } else {
            error? err = commit;
            if err is error {
                log:printError("Error occurred while committing", err);
            }
        }
    }

    // Closes the JDBC client.
    check jdbcClient.close();

    // Performs the cleanup after the example.
    check cleanup();
}

// Initializes the database as a prerequisite to the example.
function initialize() returns sql:Error? {
    jdbc:Client jdbcClient = check new ("jdbc:h2:file:./target/bbes/java_jdbc",
        "rootUser", "rootPass");

    // Creates a table in the database.
    _ = check jdbcClient->execute(`CREATE TABLE Customers(customerId INTEGER
            NOT NULL GENERATED BY DEFAULT AS IDENTITY, firstName  VARCHAR(300),
            lastName  VARCHAR(300), registrationID INTEGER UNIQUE,
            creditLimit DOUBLE, country VARCHAR(300),
            PRIMARY KEY (customerId))`);

    // Adds records to the newly-created table.
    _ = check jdbcClient->execute(`INSERT INTO Customers (firstName,
            lastName, registrationID,creditLimit,country) VALUES ('Peter',
            'Stuart', 1, 5000.75, 'USA')`);

    check jdbcClient.close();
}

// Cleans up the database after running the example.
function cleanup() returns sql:Error? {
    jdbc:Client jdbcClient = check new ("jdbc:h2:file:./target/bbes/java_jdbc",
        "rootUser", "rootPass");
    // Cleans the database.
    _ = check jdbcClient->execute(`DROP TABLE Customers`);

    check jdbcClient.close();
}
