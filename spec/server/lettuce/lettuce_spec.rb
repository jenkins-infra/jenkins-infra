require_relative './../spec_helper'

describe 'lettuce' do
  it_behaves_like "an OSU hosted machine"
  it_behaves_like 'an Apache webserver with SSL'
end
