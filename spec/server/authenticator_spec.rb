require File.dirname(__FILE__) + '/spec_helper'
require_relative '../../lib/yard/server/authenticator'

describe YARD::Server::Authenticator do

  context '#authorized_server' do

    EXPECTED_USERNAME = 'username'
    EXPECTED_PASSWORD = 'password'
    EXPECTED_REALM    = 'specified realm'

    before(:each) do
      @auth = Authenticator.new(EXPECTED_USERNAME, EXPECTED_PASSWORD, EXPECTED_REALM)
    end

    context 'realm' do

      before(:each) do
        @mock_rack = double('Rack')
      end

      it 'should have the realm' do
        @mock_rack.stub!(:start)
        protected_server = @auth.authorized_server(@mock_rack)
        protected_server.realm.should == EXPECTED_REALM
      end

    end

    context ':credentials_match?' do

      it 'does not when either password or else username does not match expected' do
        [
        # expected password, actual password  , expected user name,actual_user_name,  matches?
          [EXPECTED_PASSWORD, EXPECTED_PASSWORD, EXPECTED_USERNAME, EXPECTED_USERNAME, true],
          [EXPECTED_PASSWORD, nil,               EXPECTED_USERNAME, EXPECTED_USERNAME, false],
          [EXPECTED_PASSWORD, 'passwordx',       EXPECTED_USERNAME, 'usernamex',       false],
          [nil,               EXPECTED_PASSWORD, EXPECTED_USERNAME, EXPECTED_USERNAME, true],
          [EXPECTED_PASSWORD, EXPECTED_PASSWORD, nil,               EXPECTED_USERNAME, true],
          [EXPECTED_PASSWORD, EXPECTED_PASSWORD, EXPECTED_USERNAME, nil,               false],
          [nil,               'passwordx',       EXPECTED_USERNAME, EXPECTED_USERNAME, true],
          [EXPECTED_PASSWORD, EXPECTED_PASSWORD, nil,               'usernamex',       true]
        ].each do |row|
          auth = Authenticator.new(row[2], row[0], 'dummy_realm')
          auth.credentials_match?(row[1], row[3]).should == row[4]
        end
      end

    end

  end

end
