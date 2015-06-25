class LabelData

  include JSONModel

  attr_accessor :labels

  def initialize(uris)
    @uris = uris
    @labels = []

    build_label_data
  end

  def build_label_data
    ids = @uris.map {|uri| JSONModel(:top_container).id_for(uri)}
    top_containers = TopContainer.sequel_to_jsonmodel(TopContainer.filter(:id => ids).all).map{|tc| tc.to_hash(:trusted)}
    @labels = URIResolver.resolve_references(top_containers, ['container_locations', 'linked_records'], {})
  end

end
