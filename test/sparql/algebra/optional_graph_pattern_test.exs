defmodule SPARQL.Algebra.OptionalGraphPatternTest do
  use SPARQL.Test.Case

  import SPARQL.Language.Decoder, only: [decode: 1]


  test "group consisting of a basic graph pattern and an optional graph pattern" do
    [
      """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { ?s :p1 ?v1 OPTIONAL {?s :p2 ?v2 } }
      """,
      """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { {?s :p1 ?v1} OPTIONAL {?s :p2 ?v2 } }
      """
    ]
    |> Enum.each(fn query ->
         assert {:ok, %SPARQL.Query{
                  expr: %SPARQL.Algebra.LeftJoin{
                    expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
                    expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                    filters: [%RDF.Literal{value: true}]
                  }
                }} = decode(query)
       end)

    query = """
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT ?name ?mbox
      WHERE  { ?x foaf:name  ?name .
         OPTIONAL { ?x  foaf:mbox  ?mbox }
       }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.Project{
               vars: ~w[name mbox],
               expr: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://xmlns.com/foaf/0.1/name"}, "name"}]},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://xmlns.com/foaf/0.1/mbox"}, "mbox"}]}
               }
             }
           }} = decode(query)
  end

  test "group consisting of a basic graph pattern and two optional graph patterns" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { ?s :p1 ?v1 OPTIONAL {?s :p2 ?v2 } OPTIONAL { ?s :p3 ?v3 } }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                 filters: [%RDF.Literal{value: true}]
               },
               expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p3"}, "v3"}]},
               filters: [%RDF.Literal{value: true}]
             }
           }} = decode(query)

    query = """
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT ?name ?mbox ?hpage
      WHERE  { ?x foaf:name  ?name .
               OPTIONAL { ?x foaf:mbox ?mbox } .
               OPTIONAL { ?x foaf:homepage ?hpage }
             }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.Project{
               vars: ~w[name mbox hpage],
               expr: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.LeftJoin{
                   expr1: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://xmlns.com/foaf/0.1/name"}, "name"}]},
                   expr2: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://xmlns.com/foaf/0.1/mbox"}, "mbox"}]},
                   filters: [%RDF.Literal{value: true}]
                 },
                 expr2: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://xmlns.com/foaf/0.1/homepage"}, "hpage"}]},
                 filters: [%RDF.Literal{value: true}]
               }
             }
           }} = decode(query)
  end

  test "group consisting of a basic graph pattern and an optional graph pattern with a filter" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { ?s :p1 ?v1 OPTIONAL {?s :p2 ?v2 FILTER(?v1<3) } }
      """
    n3 = RDF.integer(3)
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
               expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
               filters: [
                 %SPARQL.Algebra.FunctionCall.Builtin{
                   name: :<,
                   arguments: ["v1", ^n3]
                 }
               ]
             }
           }} = decode(query)

    query = """
      PREFIX  dc:  <http://purl.org/dc/elements/1.1/>
      PREFIX  ns:  <http://example.org/ns#>
      SELECT  ?title ?price
      WHERE   { ?x dc:title ?title .
                OPTIONAL { ?x ns:price ?price . FILTER (?price < 30) }
              }
      """
    n30 = RDF.integer(30)
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.Project{
               vars: ~w[title price],
               expr: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://purl.org/dc/elements/1.1/title"}, "title"}]},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"x", %RDF.IRI{value: "http://example.org/ns#price"}, "price"}]},
                 filters: [
                   %SPARQL.Algebra.FunctionCall.Builtin{
                     name: :<,
                     arguments: ["price", ^n30]
                   }
                 ],
               }
             }
           }} = decode(query)
  end

  test "empty OPTIONAL graph pattern" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { ?s :p1 ?v1 OPTIONAL {} }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
               expr2: %SPARQL.Algebra.BGP{triples: []},
               filters: [%RDF.Literal{value: true}]
             }
           }} = decode(query)
  end

  test "a simple OPTIONAL graph pattern at the beginning" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { OPTIONAL {?s :p2 ?v2 } ?s :p1 ?v1 }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.Join{
               expr1: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: []},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                 filters: [%RDF.Literal{value: true}]
               },
               expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]}
             }
           }} = decode(query)

  end

  test "group consisting of a basic graph pattern, a filter and an optional graph pattern:" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE { ?s :p1 ?v1 FILTER (?v1 < 3 ) OPTIONAL {?s :p2 ?v2} }
      """
    n3 = RDF.integer(3)
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.Filter{
                expr: %SPARQL.Algebra.LeftJoin{
                  expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
                  expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                  filters: [%RDF.Literal{value: true}]
                },
               filters: [
                 %SPARQL.Algebra.FunctionCall.Builtin{
                   name: :<,
                   arguments: ["v1", ^n3]
                 }
               ]
             }
           }} = decode(query)
  end

  test "nested OPTIONAL graph patterns without filters" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE {
        {?s :p1 ?v1}
        OPTIONAL {?s :p2 ?v2 . OPTIONAL {?s :p3 ?v3}} }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
               expr2: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p3"}, "v3"}]},
                 filters: [%RDF.Literal{value: true}]
               },
               filters: [%RDF.Literal{value: true}]
             }
           }} = decode(query)

    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE {
        {?s :p1 ?v1}
        OPTIONAL {?s :p2 ?v2 OPTIONAL {?s :p3 ?v3} OPTIONAL {?s :p4 ?v4}} }
      """
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
               expr2: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.LeftJoin{
                   expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                   expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p3"}, "v3"}]},
                   filters: [%RDF.Literal{value: true}]
                 },
                 expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p4"}, "v4"}]},
                 filters: [%RDF.Literal{value: true}]
               },
               filters: [%RDF.Literal{value: true}]
             }
           }} = decode(query)
  end

  test "nested OPTIONAL graph patterns with filters" do
    query = """
      PREFIX : <http://example.com/>
      SELECT *
      WHERE {
        {?s :p1 ?v1}
        OPTIONAL {?s :p2 ?v2 . OPTIONAL {?s :p3 ?v3 FILTER(?v3<3)}} }
      """
    n3 = RDF.integer(3)
    assert {:ok, %SPARQL.Query{
             expr: %SPARQL.Algebra.LeftJoin{
               expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p1"}, "v1"}]},
               expr2: %SPARQL.Algebra.LeftJoin{
                 expr1: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p2"}, "v2"}]},
                 expr2: %SPARQL.Algebra.BGP{triples: [{"s", %RDF.IRI{value: "http://example.com/p3"}, "v3"}]},
                 filters: [
                   %SPARQL.Algebra.FunctionCall.Builtin{
                     name: :<,
                     arguments: ["v3", ^n3]
                   }
                 ]
               },
               filters: [%RDF.Literal{value: true}]
             }
           }} = decode(query)
  end

end
