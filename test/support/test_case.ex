defmodule SPARQL.Test.Case do
  use ExUnit.CaseTemplate

  use RDF.Vocabulary.Namespace
  defvocab EX,
    base_iri: "http://example.org/",
    terms: [], strict: false


  using do
    quote do
      import RDF.Sigils

      alias RDF.{Dataset, Graph, Description, IRI}
      alias SPARQL.Query

      alias unquote(__MODULE__).EX
    end
  end

end
