# frozen_string_literal: true

require 'hfc'
RSpec.describe HFC do
  let(:hfc) { HFC.new(lookup_paths: [File.join(__dir__, '..', 'config')]) }

  it 'has a version number' do
    expect(HFC::VERSION).not_to be nil
  end

  it { expect(hfc.to_h).to be_a(Hash) }
  it { expect(hfc.deep_merge(this: { is: true })).to have_key(:this) }
  it { expect(hfc.set(:this, :is, value: true)).to have_key(:this) }
  it { expect(hfc.fetch(:asdf)).to eq(nil) }
  it { expect(hfc.clone.object_id).not_to eq(hfc.object_id) }
end
