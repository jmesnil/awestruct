require 'sass/callbacks'
require 'compass/app_integration'
require 'compass/configuration'
require 'compass/logger'
require 'compass/actions'
require 'compass/commands/base'
require 'compass/commands/registry'
require 'compass/commands/create_project'
require 'compass/installers/bare_installer'

module Compass::AppIntegration::StandAlone
end

class Compass::AppIntegration::StandAlone::Installer
  def write_configuration_files(config_file = nil)
    # no!
  end
  def finalize(opts={})
    puts <<-END.gsub(/^ {6}/, '')

      Now you're awestruct!

      To generate your site continuous during development, simply run:

        awestruct -d

      and visit your site at

        http://localhost:4242/

    END
  end
end

module Awestruct
  module CLI
    class Manifest

      attr_reader :parent
      attr_reader :steps

      def initialize(parent=nil,&block)
        @parent = parent
        @steps = []
        instance_eval &block if block
      end

      def mkdir(path)
        steps << MkDir.new( path )
      end

      def copy_file(path, input_path)
        steps << CopyFile.new( path, input_path )
      end
      
      def touch_file(path)
        steps << TouchFile.new(path)
      end

      def install_compass(framework)
        steps << InstallCompass.new(framework)
      end

      def perform(dir)
        parent.perform(dir) if parent
        steps.each do |step|
          begin
            step.perform( dir )
          rescue => e
            puts e
            puts e.backtrace
          end
        end
      end

      def unperform(dir)
        steps.each do |step|
          begin
            step.unperform( dir )
          rescue => e
            puts e
            puts e.backtrace
          end
        end
      end

      ##
      ##
      ##
      ##

      class MkDir
        def initialize(path)
          @path = path
        end

        def perform(dir)
          p = File.join( dir, @path ) 
          if ( File.exist?( p ) )
            $stderr.puts "Exists: #{p}"
            return
          end
          if ( ! File.directory?( File.dirname( p ) ) )
            $stderr.puts "Does not exist: #{File.dirname(p)}"
            return
          end
          $stderr.puts "Create directory: #{p}"
          FileUtils.mkdir( p )
        end

        def unperform(dir)
          p = File.join( dir, @path ) 
          if ( ! File.exist?( p ) )
            $stderr.puts "Does not exist: #{p}"
            return
          end
          if ( ! File.directory?( p ) )
            $stderr.puts "Not a directory: #{p}"
            return
          end
          if ( Dir.entries( p ) != 2 )
            $stderr.puts "Not empty: #{p}"
            return
          end
          $stderr.puts "Remove: #{p}"
          FileUtils.rmdir( p )
        end
      end
      
      class TouchFile
        def initialize(path)
          @path = path
        end
        
        def perform(dir)
          FileUtils.touch(File.join(dir, @path))
        end
        
        def unperform(dir)
          #nothing
        end
      end

      class CopyFile
        def initialize(path, input_path)
          @path       = path
          @input_path = input_path
        end

        def perform(dir )
          p = File.join( dir, @path )
          if ( File.exist?( p ) )
            $stderr.puts "Exists: #{p}"
            return
          end
          if ( ! File.directory?( File.dirname( p ) ) )
            $stderr.puts "No directory: #{File.dirname( p )}"
            return
          end
          $stderr.puts "Create file: #{p}"
          File.open( p, 'w' ){|f| f.write( File.read( @input_path ) ) }
        end

        def unperform(dir)
          # nothing
        end

        def notunperform(dir)
          p = File.join( @dir, p )
          if ( ! File.exist?( p ) )
            $stderr.puts "Does not exist: #{p}"
            return
          end
          $stderr.puts "Remove: #{p}"
          FileUtils.rm( p )
        end

      end

      class InstallCompass
        def initialize(framework='compass')
          @framework = framework
        end

        def perform(dir)
          Compass.configuration.sass_dir    = 'stylesheets'
          Compass.configuration.css_dir     = '_site/stylesheets'
          Compass.configuration.images_dir  = 'images'

          cmd = Compass::Commands::CreateProject.new( dir, {
                  :framework=>@framework,
                  :project_type=>:stand_alone,
                  :css_dir=>'_site/stylesheets',
                  :sass_dir=>'stylesheets',
                  :images_dir=>'images',
                  :javascripts_dir=>'javascripts',
                } )
          cmd.perform
        end

        def unperform(dir)
          # nothing
        end
      end

    end
  end
end
