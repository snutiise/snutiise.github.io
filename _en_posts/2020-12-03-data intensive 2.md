---
layout: post
title: "Designing Data-Intensive Applications (2)"
date:   2020-12-03 23:00:00
categories:
- Architecture
tags:
- study
ko_sha: 3050b5f64d7ef1186219c33ea153eaf77034857d
---

The data model is the most important part of software development, because it strongly affects not only how the software is written but also how we think about the problem we are trying to solve.

Most applications are built by layering one data model on top of another. The key question at each layer is how to represent its data model in terms of the next lower layer. For example:

- An application developer looks at the real world and models objects or data structures, and the APIs that manipulate those data structures.
- To store those data structures, they are expressed in a general-purpose data model such as JSON, XML, an RDB, or a graph model.
- Decide how to represent the data as bytes in memory, on disk, or on a network.
- At a still lower level, decide how to represent the bytes.

A complex application may have more intermediate layers, but the basic idea is still the same. Each layer hides the complexity of the layers below it by providing a clean data model.

These abstractions matter because they let different groups of people (for example, database engineers and software developers) work together effectively.

## Relational model and document model

The best-known data model today is SQL, which is based on the <a href='https://ko.wikipedia.org/wiki/%EA%B4%80%EA%B3%84%ED%98%95_%EB%AA%A8%EB%8D%B8'>relational model</a> proposed by <a href='https://ko.wikipedia.org/wiki/%EC%97%90%EB%93%9C%EA%B1%B0_F._%EC%BB%A4%EB%93%9C'>Edgar Codd</a> in 1970. Data is organized into **relations** (called a **table[(table)** in SQL), and each relation is an unordered collection of **tuples** (**rows** in SQL).

Most services are still provided through this relational model.

### The birth of NoSQL

NoSQL was originally a popular Twitter hashtag for a meetup on open-source, distributed, non-relational databases, but it has since been reinterpreted as **Not Only SQL**.

NoSQL emerged because of a variety of needs, as follows:

- A need for greater scalability, so that large datasets can be handled more easily than with an RDB
- A growing preference for free, open-source software over commercial database products
- Specialized queries that the relational model does not support
- Frustration with the restrictions of relational schemas, and a need for a more dynamic and expressive data model

Most NoSQL databases are open source and are **schema-less**. They use an **aggregate-oriented** model, which suits scale-out. (The graph model is an exception.)

### Object-relational mismatch

Object-oriented code and the database model objects (table, row, column) need an awkward translation layer between them, and this is called the impedance mismatch.

Object-relational mapping (ORM) frameworks reduce the amount of boilerplate code in the translation layer, but they cannot completely hide the differences between the two models.

A JSON representation has better **locality** than a multi-table schema. Even in a case that needs multiple joins in the relational model, all the related information in the JSON representation is in one place, so a single query is enough.

### Many-to-one and many-to-many relationships

Normalizing duplicated data requires many-to-one relationships. Such many-to-one relationships suit relational databases, where joins are easy, but a document database can also express them.

Many-to-many relationships, which express more complex relationships, are harder to express and therefore less suited to document databases.

### Are document databases repeating history?

Document databases and NoSQL have been in a long debate with the rest of the database world about how to represent many-to-many relationships.

In the 1970s, IBM's Information Management System (IMS) used a hierarchical model, which closely resembles JSON.

Like document databases, IMS worked well for one-to-many relationships but made many-to-many relationships hard to express. The solutions proposed to overcome this limitation of the hierarchical model were as follows:

- The relational model (mainstream)
- The network model (non-mainstream)

Will we end up returning to the relational model after all?

### The network model

The network model generalizes the hierarchical model. In the hierarchical model's tree structure every record has exactly one parent, whereas in the network model a record can have multiple parents.

The only way to access a record is to follow a chain of links from a root record. This is called an **access path**.

If a record has multiple parents, all of the various relationships must be tracked, and if there is no path to the data you want, you are in a difficult position. Access paths can be changed, but doing so requires manual rewriting.

It is similar to the graph databases discussed later, but a network-model database operates at a lower level of abstraction and **cannot easily traverse a series of edges**.

### The relational model

It lays out all known data in the open. A relation (table) is simply a collection of tuples (rows). So there are no complex access paths, and you only need to read the tables you need.

In a relational database, the query optimizer decides which parts of a query to execute in which order and automatically decides which indexes to use, and this amounts to building the **access path**.

To query data in a new way, you only need to declare a new index, and queries automatically find the most suitable path. In other words, the relational model makes it much easier to add new features to an application.

### Comparison with document databases

A document database is similar to the hierarchical model in that it stores nested records inside a parent record rather than in separate tables, but it is not fundamentally different from a relational database when expressing many-to-one and many-to-many relationships.

This is because in both cases a related item is referenced by a unique identifier. This is called a **foreign key** in the relational model and a **document reference** in the document model.

### Relational databases and today's document databases

Document data model
- Schema flexibility
- Better performance due to locality
- Suits cases where the application's data has a document-like structure

Relational model
- Better support for joins and many-to-many/many-to-one relationships

### Which data model makes application code simpler?

If the application's data has a document-like structure (a tree of one-to-many relationships, where the entire tree is usually loaded at once), it is a good idea to use the document model.

If the application uses many-to-many relationships, the relational model is more suitable than the document model.

In general, it is not possible to say which data model makes application code simpler. It depends on the kinds of relationships that exist between data items. For highly interconnected data, the document model is awkward, the relational model is acceptable, and the graph model is the most natural.

### Schema flexibility in the document model

The document model does not enforce a schema. That is, arbitrary keys and values can be added to a document, and when reading, the client has no guarantee about which fields a document contains.

The differences between the relational model and the document model regarding schemas are as follows:

- The relational model is explicit, and the database ensures that all written data conforms to the schema; this is **schema-on-write**.
- In the document model, the data structure is implicit and is interpreted only when the data is read; this is **schema-on-read**.

### Data locality for queries

In the relational model, if data is split across multiple tables, retrieving all of it requires multiple index lookups, which wastes many resources.

The document model, in contrast, has better locality and therefore a performance advantage. However, the benefit of locality applies only when you need a large part of the document at once.

With the document model, the entire document must be loaded even when only a small part of it is updated, which can be wasteful. For this reason, it is recommended to keep documents small.

### Unifying document and relational databases

Since the mid-2000s, most relational databases have <a href="https://dev.mysql.com/doc/refman/5.7/en/json.html">supported data models similar to the document database model (XML, JSON)</a>.

Document databases, too, are <a href="https://mongoosejs.com/">moving toward supporting relational joins and defining schemas</a>, like the relational model.

In this way, relational and document databases are becoming more similar over time, because each data model is making up for what the other lacks.

## Query languages for data

### Imperative and declarative queries

IMS and CODASYL (the network model) use imperative query languages similar to programming languages. SQL, in contrast, is a declarative query language.

An imperative query language looks like this:

{% highlight javascript %}
function getSharks(){
    let sharks = [];
    for(let i=0; i<animals.length; i++){
        if(animals[i].family === "Sharks") sharks.push(animals[i]);
    }
    return sharks;
}
{% endhighlight %}

A declarative query language looks like this:

{% highlight sql %}
SELECT * FROM animals WHERE family = 'Sharks';
{% endhighlight %}

An imperative language instructs the computer to perform certain operations in a certain order. A declarative language, in contrast, specifies the pattern of the data you want, not how to achieve that goal.

The advantages of declarative languages are as follows:

- The detailed implementation of the DB engine is hidden, so the performance of the DB system can be improved without changing queries.
- SQL does not guarantee ordering, so it does not matter if the order changes.
- The fact that SQL is more limited in functionality means that the DB has more room to optimize automatically.
- Declarative languages suit parallel execution.

### MapReduce queries

MapReduce is a programming model for processing large amounts of data on many machines. MapReduce sits somewhere between a declarative language and a fully imperative query API.

MapReduce is based on the map (collect) and reduce (fold or inject) functions found in functional programming languages.


## Graph-like data models

If an application mostly has one-to-many relationships (tree-structured data) or has no relationships between records, the document model is suitable.

The relational model can handle simple many-to-many relationships, but as the connections within the data become more complex, it is more natural to model the data as a graph.

A graph consists of two kinds of objects.

- Vertex: also called a node or an entity.
- Edge: also called a relationship or an arc.

Examples of graph modeling

- Social graph
    - Vertices: people
    - Edges: relationships between people
- Web graph
    - Vertices: web pages
    - Edges: HTML links to other pages
- Road or rail network
    - Vertices: junctions
    - Edges: roads/railway lines, etc.

There are several different ways to structure and query data in a graph. They include the **property graph** model, the triple-store model, and the declarative graph query languages **Cypher**, SPARQL, and Datalog.

### Property graphs

In the property graph model, each vertex consists of the following elements:

- A unique identifier
- A set of outgoing edges
- A set of incoming edges
- A collection of properties (key-value pairs)

Each edge consists of the following elements:
- A unique identifier
- The tail vertex: the vertex where the edge starts
- The head vertex: the vertex where the edge ends
- A label describing the type of relationship between the two vertices
- A collection of properties (key-value pairs)

Representing a property graph with a relational schema looks like this:

{% highlight sql %}
CREATE TABLE vertices (
    vertex_id integer PRIMARY KEY,
    properties json
);

CREATE TABLE edges (
    edge_id integer PRIMARY KEY,
    tail_vertex integer REFERENCES vertices (vertex_id),
    head_vertex integer REFERENCES vertices (vertex_id),
    label text,
    properties json
);

CREATE INDEX edges_tails ON edges (tail_vertex);
CREATE INDEX edges_heads ON edges (head_vertex);
{% endhighlight %}

The advantages of this model are as follows:

- Any vertex can be connected to any other vertex by an edge.
- There is no schema that restricts which kinds of things can be related.
- Given a vertex, you can efficiently find both its incoming and outgoing edges.
- You can traverse the graph by following vertices.
- Using different labels for different types of relationships lets you store different kinds of information in a single graph while keeping the data model clean.

### The Cypher query language

It is a declarative query language for property graphs.

{% highlight sql %}
MATCH
  (person) -[:BORN_IN]->  () -[:WITHIN*0..]-> (us:Location {name:'United States'}),
  (person) -[:LIVES_IN]-> () -[:WITHIN*0..]-> (eu:Location {name:'Europe'})
RETURN person.name
{% endhighlight %}

The query above asks us to find vertices that satisfy 2 conditions:

- The person has an outgoing BON_IN edge to some vertex. From that vertex, follow a chain of outgoing WITHIN edges until reaching a vertex of type Location whose name property is "United States".
- The same person vertex also has an outgoing LIVES_IN edge. Following that edge and then a chain of outgoing WITHIN edges eventually reaches a vertex of type Location whose name property is "Europe".

### Graph queries in SQL

Above, we showed that a graph database can be represented in a relational database. Then can we put graph data into a relational database and query it with SQL?

The answer is "yes", but it is somewhat difficult. It is hard to replace edge-traversal queries such as **[:WITHIN*0..]-> ()**, which is used in Cypher.

### Triple-stores and SPARQL

The triple-store model is mostly equivalent to the property graph model. It stores all information in the form of very simple three-part statments: subject, predicate, and object.

A triple store is optimized for storing and retrieving triples. Besides querying, triples can usually be imported and exported using the <a href="https://ko.wikipedia.org/wiki/%EC%9E%90%EC%9B%90_%EA%B8%B0%EC%88%A0_%ED%94%84%EB%A0%88%EC%9E%84%EC%9B%8C%ED%81%AC">Resource Description Framework (RDF)</a> and other formats.

SPARQL is a query language for retrieving and manipulating data stored in RDF format.

Its structure appears very similar to Cypher (because Cypher, created later, borrowed its pattern matching from SPARQL).

Comparing the Cypher query above with a SPARQL query looks like this:

{% highlight sql %}
(person) -[:BORN_IN]-> () -[:WITHIN*0..]-> (location)   # Cypher

?person :bornIn / :within* ?location.                   # SPARQL
{% endhighlight %}