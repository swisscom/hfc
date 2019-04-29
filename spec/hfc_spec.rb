# frozen_string_literal: true

require 'hfc'
RSpec.describe HFC do

  it 'has a version number' do
    expect(HFC::VERSION).not_to be nil
  end

  let(:hfc) { HFC.new(lookup_paths: [File.join(__dir__, '..', 'config')], config: {this: {is: 0}})}
  it { expect(hfc.to_h).to be_a(Hash) }
  it { expect(hfc.deep_merge(this: { is: true })).to have_key(:this) }
  it { expect(hfc.set(:this, :is, value: true)).to have_key(:this) }
  it { expect(hfc.fetch(:this, :is)).to eq(0) }
  it { expect(hfc.clone.object_id).not_to eq(hfc.object_id) }

  it "deep fetches" do
    hfc.deep_merge(this: { is: true })
    expect(hfc.fetch(:this)).to eq({"is" => true})
    expect(hfc.fetch(:this, :is)).to eq(true)
    expect(hfc[:this, :is]).to eq(true)
  end
end
