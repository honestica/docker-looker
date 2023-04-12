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
        'Entrypoint' => ['tini', '--', '/bin/sh'],
        'ReadonlyRootfs' => true,
        'HostConfig' => {
          'Binds' => [
            "#{File.expand_path __dir__}/page.html:/srv/page.html",
          ]
        }

    if ENV.include?('DOCKER_HOST')
      set :docker_url, ENV['DOCKER_HOST']
    else
      set :docker_url, 'unix:///var/run/docker.sock'
    end
  end

  describe command('whoami') do
    its(:stdout) { should match(/looker/i) }
    its(:exit_status) { should eq 0 }
  end

  describe command('phantomjs --version') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^2\./) }
  end

  # https://community.looker.com/general-looker-administration-35/troubleshooting-common-chromium-errors-20621
  describe command('chromium --version') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/chrom.* 109\.0\.5414./i) }
  end

  describe command('chromium --headless --disable-gpu --print-to-pdf /srv/page.html') do
    its(:exit_status) { should eq 0 }
  end

  describe file('output.pdf') do
    it { should exist }
  end

  describe command(
    <<~CMD
      chromium --headless --remote-debugging-port=9222 --hide-scrollbars --disable-gpu --disable-logging --disable-translate --force-device-scale-factor=1 --disable-extensions --disable-background-networking --safebrowsing-disable-auto-update --disable-sync --metrics-recording-only --disable-default-apps --mute-audio --no-first-run --no-default-browser-check --no-startup-window --disable-plugin-power-saver --disable-popup-blocking &
      sleep 2
      curl -Ssv http://127.0.0.1:9222
    CMD
  ) do
    its(:exit_status) { should eq 0 }
  end


  describe file('/etc/protocols') do
    it { should exist }
  end
end
