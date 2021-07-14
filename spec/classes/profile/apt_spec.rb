require 'spec_helper'

describe 'profile::apt' do
  it { should create_class('apt').with(
    'update' => {
      'frequency' => 'daily',
    },
  )}
end
