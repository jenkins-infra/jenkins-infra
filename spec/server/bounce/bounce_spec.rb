require_relative './../spec_helper'

describe 'bounce' do
  it_behaves_like "a standard Linux machine"

  describe user('ogondza') do
    it { should exist }
  end
end
