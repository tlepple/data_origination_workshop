
---
#### Addition Spark & Python Exercises:

Here are some additional spark examples that demonstrate how to interact with the data generated with spark.

In this spark job  [`consume_stream_customer_2_console.py`](./datagen/consume_stream_customer_2_console.py) we will consume the records from the topic `dgCustomer` and just stream them to our console.

```
spark-submit ~/datagen/consume_stream_customer_2_console.py
```
---
In this spark job  [`consume_stream_txn_2_console.py`](./datagen/consume_stream_txn_2_console.py) we will consume the records from the topic  `dgTxn` and just stream them to our console.

```
spark-submit ~/datagen/consume_stream_txn_2_console.py
```

---
In this python job  [`comsume_topic_dgCustomer.py`](./datagen/comsume_topic_dgCustomer.py) we will consume 4 records from the topic  `dgCustomer` and just stream them to our console.

```
python3 ~/datagen/comsume_topic_dgCustomer.py 4
```
---

Click here to return to the workshop: [`Workshop 2 Exercises`](./README.md/#automation-of-workshop-1-exercises).

---
