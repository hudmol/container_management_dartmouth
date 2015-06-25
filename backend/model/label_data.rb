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
    resolved_top_containers = URIResolver.resolve_references(top_containers, ['container_locations', 'linked_records'], {})
    labels = []
    resolved_top_containers.each do |label|
      label['linked_records'].each do |ao|
        labels << label.merge({'archival_object' => ao}).reject{|k| k == 'linked_records'}
      end
    end
    @labels = labels
  end

end
