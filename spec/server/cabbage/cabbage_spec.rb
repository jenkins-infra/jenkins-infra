require_relative './../spec_helper'

describe 'cabbage' do
  it_behaves_like "a standard Linux machine"
  it_behaves_like "a Jenkins build slave"
end
