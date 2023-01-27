from __future__ import print_function
from faker import Faker
from datagenerator import DataGenerator
import simplejson
import sys
import psycopg2
#########################################################################################
#	Define variables
#########################################################################################
dg = DataGenerator()
fake = Faker() # <--- Don't Forgot this
startKey = int(sys.argv[1])
iterateVal = int(sys.argv[2])
# functions to display errors
def printf (format,*args):
	sys.stdout.write (format % args)
def printException (exception):
	error, = exception.args
	printf("Error code = %s\n",error.code);
	printf("Error message = %s\n",error.message);
def myconverter(obj):
	if isinstance(obj, (datetime.datetime)):
		return obj.__str__()
#########################################################################################
#	Code execution below
#########################################################################################
try:
    try:
        conn = psycopg2.connect(host="127.0.0.1",database="datagen", user="datagen", password="supersecret1")
        print("Connection Established")
    except psycopg2.Error as exception:
        printf ('Failed to connect to database')
        printException (exception)
        exit (1)
    cursor = conn.cursor()
    try:
        fpg = dg.fake_person_generator(startKey, iterateVal, fake)
        for person in fpg:
#            print(simplejson.dumps(person, ensure_ascii=False, default = myconverter))
            json_out = simplejson.dumps(person, ensure_ascii=False, default = myconverter)
            print(json_out)
            insert_stmt = "SELECT datagen.insert_from_json('" + json_out +"');"
            cursor.execute(insert_stmt)
        print("Records inserted successfully")
    except psycopg2.Error as exception:
        printf ('Failed to insert\n')
        printException (exception)
        exit (1)
    finally:
        if(conn):
            conn.commit()
            cursor.close()
            conn.close()
            print("PostgreSQL connection is closed")
except (Exception, psycopg2.Error) as error:
    print("Something else went wrong...\n", error)
finally:
    print("script complete!")
