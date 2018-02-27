defmodule SPARQL.Query.Result.TSV do
  @moduledoc """
  An implementation of the W3C Recommendation for the SPARQL 1.1 Query Results TSV Formats.

  see <http://www.w3.org/TR/sparql11-results-csv-tsv/>
  """

  use SPARQL.Query.Result.Format

  import RDF.Sigils

  @id           ~I<http://www.w3.org/ns/formats/SPARQL_Results_TSV>
  @name         :tsv
  @extension    "tsv"
  @content_type "text/tab-separated-values"

end