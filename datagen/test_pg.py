import psycopg2

try:
    try:
         # Connect to your PostgreSQL database on a remote server
         conn = psycopg2.connect(host="127.0.0.1", port="5432", dbname="datagen", user="datagen", password="supersecret1")
         print("Connection Established!")
         print("\n")
    except psycopg2.Error as exception:
         printf ('Failed to connect to database')
         printException (exception)
         exit (1)

    # Open a cursor to perform database operations
    cur = conn.cursor()
    try:
        # Execute a test query
        cur.execute("SELECT * FROM customer")

        # Retrieve query results
        records = cur.fetchall()

        #print records
        print(records)

    except psycopg2.Error as exception:
        printf ('Failed to insert\n')
        printException (exception)
        exit (1)
    finally:
        if(conn):
            cur.close()
            conn.close()
            print("\n")
            print("PostgreSQL connection is closed")

except (Exception, psycopg2.Error) as error:
    print("Something else went wrong...\n", error)

finally:
    print("\n")
    print("script complete!")

