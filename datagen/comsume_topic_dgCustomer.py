import json 
import sys
import argparse
from kafka import KafkaConsumer

startKey = int(1)
#iterateVal = int(5)

parser = argparse.ArgumentParser()

# define our required arguments to pass in:
parser.add_argument("recordCount", help="Enter int value for desired number of records", type=int)

# parse these args
args = parser.parse_args()

# assign args to vars:
stopVal = int(args.recordCount)

try:
    # define our Kafka Consumer 
    consumer = KafkaConsumer(
        'dgCustomer',
        bootstrap_servers='localhost:9092',
        auto_offset_reset='earliest',
        value_deserializer=lambda m: json.loads(m.decode('utf-8'))
    )
    for message in consumer:
        print(message.value)
        startKey += 1 

        if startKey == stopVal:
            print("\n")
            print(str(stopVal) +  " msgs have been consumed.")
            print("\n")
            consumer.close()
            sys.exit()


except KeyboardInterrupt:
    sys.exit()
finally:
    print("script complete!")

