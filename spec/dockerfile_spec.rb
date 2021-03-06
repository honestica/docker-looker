# frozen_string_literal: true

require 'docker-api'
require 'serverspec'

image = ENV['IMAGE']
repository = ENV['REPOSITORY']
tag = ENV['TAG']

describe 'Dockerfile' do
  before(:all) do
    set :os, family: :debian
    set :backend, :docker
    set :docker_image, "#{repository}/#{image}:#{tag}"
    set :docker_container_create_options,
        'Entrypoint' => ['tini', '--', '/bin/sh']

    if ENV.include?('DOCKER_HOST')
      set :docker_url, ENV['DOCKER_HOST']
    else
      set :docker_url, 'unix:///var/run/docker.sock'
    end
  end

  describe command('chromium --version') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/chrome/i) }
  end
end
