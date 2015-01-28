require 'spec_helper'
require_relative 'factories'

describe 'Yale Container Profile model' do

  it "can be created from a JSON module" do
    cp = ContainerProfile.create_from_json(build(:json_container_profile, :name => "Big black bag"),
                                         :repo_id => $repo_id)

    ContainerProfile[cp[:id]].name.should eq("Big black bag")
  end


  it "enforces name uniqueness within a repository" do
      create(:json_container_profile, :name => "1234")

      expect {
        create(:json_container_profile, :name => "1234")
      }.to raise_error(ValidationException)
  end


  it "doesn't enforce name uniqueness between repositories" do
    repo1 = make_test_repo("REPO1")
    repo2 = make_test_repo("REPO2")

    expect {
      [repo1, repo2].each do |repo_id|
        ContainerProfile.create_from_json(build(:json_container_profile, {:name => "Gary"}), :repo_id => repo_id)
      end
    }.to_not raise_error
  end


  it "can delete a container profile that has been linked to records" do
    container_profile = create(:json_container_profile)
    box = create(:json_top_container,
                 :container_profile => {'ref' => container_profile.uri})

    ContainerProfile[container_profile.id].delete

    TopContainer.to_jsonmodel(box.id)['container_profile'].should be_nil
  end


  it "requires depth to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "123abc", :width => "10", :height => "10")
    }.to raise_error(ValidationException)
  end


  it "requires width to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "10", :width => "123.001", :height => "10")
    }.to raise_error(ValidationException)
  end


  it "requires height to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "10", :width => "10", :height => "-10")
    }.to raise_error(ValidationException)
  end
end
