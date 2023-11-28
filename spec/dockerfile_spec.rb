# frozen_string_literal: true

require 'docker-api'
require 'json'
require 'net/http'
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
        'CapDrop' => ['ALL'],
        'Privileged' => false,
        'ReadonlyRootfs' => true,
        'WorkingDir' => '/home/looker',
        'HostConfig' => {
          'Binds' => [
            "#{File.expand_path __dir__}/page.html:/srv/page.html",
            "looker-test:/home/looker:rw",
          ],
          'GroupAdd' => ['2000'],
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
    its(:stdout) { should match(/chrom.* 109\./i) }
  end

  describe command('chromium --headless --disable-gpu --print-to-pdf /srv/page.html') do
    its(:exit_status) { should eq 0 }
    describe file('output.pdf') do
      it { should exist }
    end
    describe command('head -1 output.pdf') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/PDF/) }
    end
  end

  describe command(
    <<~CMD
      chromium --headless --remote-debugging-port=9222 --hide-scrollbars --disable-gpu --disable-logging --disable-translate --force-device-scale-factor=1 --disable-extensions --disable-background-networking --safebrowsing-disable-auto-update --disable-sync --metrics-recording-only --disable-default-apps --mute-audio --no-first-run --no-default-browser-check --no-startup-window --disable-plugin-power-saver --disable-popup-blocking &
      sleep 2
    CMD
  ) do
    its(:exit_status) { should eq 0 }
    describe command('curl -Ssv http://127.0.0.1:9222') do
      its(:exit_status) { should eq 0 }
    end.after do
      # https://chromedevtools.github.io/devtools-protocol/
      version = command('curl -Ss http://127.0.0.1:9222/json/version').stdout_as_json
      expect(version['Browser']).to match(/HeadlessChrome/)

      new_page = command('curl -Ss -XPUT http://127.0.0.1:9222/json/new?https://www.lifen.fr/').stdout_as_json
      expect(new_page).to include('url')
      expect(new_page).to include('devtoolsFrontendUrl')
      expect(new_page).to include('webSocketDebuggerUrl')
      expect(new_page['url']).to eq('https://www.lifen.fr/')
      expect(new_page['devtoolsFrontendUrl']).to match(%r{/devtools/inspector\.html\?ws=127\.0\.0\.1:9222/devtools/page})
      expect(new_page['webSocketDebuggerUrl']).to match(%r{ws://127\.0\.0\.1:9222/devtools/page/})

      # We should now test: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF 🙏
    end
  end

  describe file('/etc/protocols') do
    it { should exist }
  end

  describe command(
    <<~SHELL
      ln -fs $LOOKER_DIR/looker.jar /home/looker \
      && ln -fs /opt/looker/looker-dependencies.jar /home/looker \
      && java $JAVAJVMARGS $JAVAARGS -jar $LOOKER_DIR/looker.jar version
    SHELL
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^23\.10\./) }
    its(:stderr) { should_not match(/fatal|error|exception/i) }
  end
end
