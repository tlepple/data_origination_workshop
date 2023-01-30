---
Title:  Data Origination Workshop 
Author:  Tim Lepple
Date:  1.29.2023
Comments:  This repo will evolve over time with new items.
Tags:  Red Panda | PostgreSQL | Kafka Connect | Python
---

# Data Origination Workshop (WIP)
---

## Objective:

---

###  Install Git tools and pull this repo.
*  ssh into your new Ubuntu 20.04 instance and run the below command:

---

```
sudo apt-get install git-all -y

cd ~
git clone https://github.com/tlepple/data_origination_workshop.git
```

---

### Start the build:

---

```
#  run it:
chmod +x ~/data_origination_workshop/setup_data_origination_apps.sh
. ~/data_origination_workshop/setup_data_origination_apps.sh
```
 * Refill your coffee, this will run for about 5 min.

---
---

###  Explore the Red Panda CLI tool `RPK`  
  *   Add link to RPK descriptions here:

####  From a terminal window run:

```
#  Let's create a topic with RPK
rpk topic create movie_list

```

####  Let's add a few messages to this topic:
  *  this will open a producer session and await your input until you close it with `<ctrl> + d`

```
rpk topic produce movie_list
```

####  Add some movies:

```
#  Entry 1:
Top Gun Maverick

#  Entry 2:
Star Wars - Return of the Jedi
```

  *  exit producer:  `<ctrl> + d`



#### Output:
```
Produced to partition 0 at offset 0 with timestamp 1675085635701.
Star Wars - Return of the Jedi
Produced to partition 0 at offset 1 with timestamp 1675085644895.

```

####  Let's consume these messages from CLI:

```
rpk topic consume movie_list --num 2
```

---

####  Expected Output:

```
{
  "topic": "movie_list",
  "value": "Top Gun Maverick",
  "timestamp": 1675085635701,
  "partition": 0,
  "offset": 0
}
{
  "topic": "movie_list",
  "value": "Star Wars - Return of the Jedi",
  "timestamp": 1675085644895,
  "partition": 0,
  "offset": 1
}

```

---


##  Let's explore the Red Panda GUI.
  *  Open a browswer and navigate to your host ip address:  `http:\\<your ip address>:8080`  This will open the Red Panda GUI

---
  ###  screenshot goes here:
  


####  Delete the topic from the CLI:

```
rpk topic delete movie_list
```

---

#  Stream some data to our topics:

We will switch to a different OS user `datagen` (password for user: `supersecret1` where some data generation tools were installed in the build.  From a terminal window run:

```
su - datagen
```


