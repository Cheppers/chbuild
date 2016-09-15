# frozen_string_literal: true
require 'docker-api'
require 'erb'

require 'ch_build/bindable_hash'
require 'ch_build/config'

# rubocop:disable Metrics/ClassLength

# CHBuild main module
module CHBuild
  # CHBuild::Controller
  class Controller
    def self.config(path_to_config = nil)
      # rubocop:disable Style/ClassVars
      @@config ||= nil

      unless @@config
        @@config = if path_to_config.nil?
                     CHBuild::Config.new(File.join(Dir.pwd, '.ch-build.yml'))
                   else
                     CHBuild::Config.new(path_to_config)
                   end
      end
      @@config
    end

    def self.image_exist?
      Docker::Image.exist? CHBuild::IMAGE_NAME
    end

    def self.container_exist?
      Docker::Container.get(CHBuild::IMAGE_NAME)
      true
    rescue
      false
    end

    def self.promote
      puts '!!! WIP !!!'
      puts "FQDN: #{CHBuild::Utils.fqdn}"
    end

    def self.build
      template = load_docker_template(
        'base-docker-container',
        php_memory_limit: '128M'
      )

      docker_context = generate_docker_archive(template)

      Docker::Image.build_from_tar(docker_context, t: CHBuild::IMAGE_NAME) do |r|
        r.each_line do |log|
          if (message = JSON.parse(log)) && message.key?('stream')
            yield message['stream'] if block_given?
          end
        end
      end
    end

    def self.run(webroot: nil, initscripts: nil)
      return false unless image_exist?

      bind_volumes = []

      if !webroot.nil? && Dir.exist?(File.expand_path(webroot))
        bind_volumes << "#{webroot}:/www"
      end
      if !initscripts.nil? && Dir.exist?(File.expand_path(initscripts))
        bind_volumes << "#{initscripts}:/initscripts"
      end

      if container_exist?
        Docker::Container.get(CHBuild::IMAGE_NAME).remove(force: true)
      end

      container = Docker::Container.create(
        'name' => CHBuild::Utils.generate_conatiner_name,
        'Image' => CHBuild::IMAGE_NAME,
        'Volumes' => {
          "#{Dir.pwd}/webroot" => {},
          "#{Dir.pwd}/initscripts" => {}
        },
        'ExposedPorts' => {
          '80/tcp' => {}
        },
        'HostConfig' => {
          'PortBindings' => {
            '80/tcp' => [{ 'HostPort' => '8088' }]
          },
          'Binds' => bind_volumes
        }
      )

      container.start
    end

    def self.clean
      delete_container
      delete_image
    end

    def self.delete_container
      if container_exist?
        container = Docker::Container.get CHBuild::IMAGE_NAME
        container.delete(force: true)
      end
    end

    def self.delete_image
      if image_exist?
        image = Docker::Image.get CHBuild::IMAGE_NAME
        image.remove(force: true)
      end
    end

    private_class_method

    def self.load_docker_template(template_name, opts = {})
      opts = CHBuild::DEFAULT_OPTS.merge(opts)

      context = BindableHash.new opts
      ::ERB.new(
        File.read("#{CHBuild::TEMPLATE_DIR}/#{template_name}.erb")
      ).result(context.binding)
    end

    def self.generate_docker_archive(dockerfile_content) # rubocop:disable Metrics/AbcSize
      tar = StringIO.new

      Gem::Package::TarWriter.new(tar) do |writer|
        writer.add_file('Dockerfile', 0644) { |f| f.write(dockerfile_content) }
        writer.add_file('00000_init.sh', 0644) do |f|
          f.write(config.init_script)
        end
        writer.add_file('init.sh', 0644) do |f|
          file_content = File.read("#{CHBuild::TEMPLATE_DIR}/init.sh")
          f.write(file_content)
        end
      end

      compress(tar)
    end

    def self.compress_archive(tar)
      tar.seek(0)

      StringIO.open('', 'r+') do |gz|
        gz.set_encoding('BINARY')
        gz_writer = Zlib::GzipWriter.new(gz)
        gz_writer.write(tar.read)
        tar.close
        gz_writer.finish
        gz.rewind
      end
    end
  end
end
