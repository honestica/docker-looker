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

  def clear_cache
    @metadata = nil
    File.delete('response.json') if File.exist?('response.json')
    File.delete('looker.jar') if File.exist?('looker.jar')
    File.delete('looker-dependencies.jar') if File.exist?('looker-dependencies.jar')
  end

  def jar_url
    validate_metadata
    metadata['url']
  end

  def jar_dependency_url
    validate_metadata
    metadata['depUrl']
  end

  def full_version
    validate_metadata
    metadata['version_text'].gsub(/^looker-(.*)\.jar$/, '\1').chomp
  end

  def download_jar
    download(jar_url, 'looker.jar')
  end

  def download_jar_dependency
    download(jar_dependency_url, 'looker-dependencies.jar')
  end

  private

  def download(url, destination)
    return if File.exist?(destination) && (File.stat(destination).ctime > Time.now() - 86_400)

    f = File.open(destination, 'w')
    f.write(Net::HTTP.get(URI(url)))
    f.close
  end

  def metadata
    @metadata ||= begin
      res = nil
      if File.exist?('response.json') && (File.stat('response.json').ctime > Time.now() - 86_400)
        response = File.open('response.json')
        res = JSON.load(response.read)
        response.close
      else
        response = File.open('response.json', 'w')
        uri = URI('https://apidownload.looker.com/download')
        req = Net::HTTP.post(
          uri,
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
        raise "Invalid metadata response" if res.nil? || res.empty?
      end
      res
    end
  end

  def validate_metadata
    expected_keys = %w[url depUrl version_text]
    expected_keys.each do |key|
      raise "Invalid metadata, missing #{key}" unless metadata.key?(key)
    end
  end
end
