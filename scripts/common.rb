#!/usr/bin/env ruby

require 'net/http'
require 'json'

class Looker
  def initialize(version, license, email)
    @version = version
    @license = license
    @email = email
    @metadata = nil
  end

  def jar_url
    metadata['url']
  end

  def jar_dependency_url
    metadata['depUrl']
  end

  def full_version
    metadata['version_text'].gsub(/^looker-(.*)\.jar$/, '\1').chomp
  end

  def download(url, destination)
    return if File.exist?(destination) && (File.stat(destination).ctime > Time.now() - 3600)

    f = File.open(destination, 'w')
    f.write(Net::HTTP.get(URI(url)))
    f.close
  end

  private

  def metadata
    @metadata ||= begin
      res = nil
      if File.exist?('response.json') && (File.stat('response.json').ctime > Time.now() - 3600)
        response = File.open('response.json')
        res = JSON.load(response.read)
        response.close
      else
        response = File.open('response.json', 'w')
        req = Net::HTTP.post(
          URI('https://apidownload.looker.com/download'),
          JSON.dump({
            'lic' => @license,
            'email' => @email,
            'latest' => 'specific',
            'specific' => "looker-#{@version}-latest.jar",
          }),
          { 'Content-Type': 'application/json' }
        ).body()
        response.write(req)
        response.close
        res = JSON.load(req)
      end
      res
    end
  end
end
