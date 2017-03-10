require_relative './../spec_helper'

describe 'kubernetes' do
  it_behaves_like "a standard Linux machine"

  describe user('k8s') do
    it { should exist }
  end

end
