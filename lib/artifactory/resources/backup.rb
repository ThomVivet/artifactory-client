require 'rexml/document'

module Artifactory
  class Resource::Backup < Resource::Base
    class << self
      #
      # Get a list of all backup jobs in the system.
      #
      # @param [Hash] options
      #   the list of options
      #
      # @option options [Artifactory::Client] :client
      #   the client object to make the request with
      #
      # @return [Array<Resource::Backup>]
      #   the list of backup jobs
      #
      def all(options = {})
        config = Resource::System.configuration(options)
        list_from_config('config/backups/backup', config, options)
      end

      #
      # Find (fetch) a backup job by its key.
      #
      # @example Find a Backup by its key.
      #   backup.find('backup-daily') #=> #<Backup key: 'backup-daily' ...>
      #
      # @param [String] key
      #   the name of the backup job to find
      # @param [Hash] options
      #   the list of options
      #
      # @option options [Artifactory::Client] :client
      #   the client object to make the request with
      #
      # @return [Resource::Backup, nil]
      #   an instance of the backup job that matches the given key, or +nil+
      #   if one does not exist
      #
      def find(key, options = {})
        config = Resource::System.configuration(options)
        find_from_config("config/backups/backup/key[text()='#{key}']", config, options)
      rescue Error::HTTPError => e
        raise unless e.code == 404
        nil
      end

      private

      #
      # List all the child text elements in the Artifactory configuration file
      # of a node matching the specified xpath
      #
      # @param [String] xpath
      #   xpath expression for the parent element whose children are to be listed
      #
      # @param [REXML] config
      #   Artifactory config as an REXML file
      #
      # @param [Hash] options
      #   the list of options
      #
      # @return [~Resource::Base]
      #
      def list_from_config(xpath, config, options = {})
        REXML::XPath.match(config, xpath).map do |r|
          hash = Util.xml_to_hash(r, 'excludedRepositories', false)
          from_hash(hash, options)
        end
      end

      #
      # Find all the sibling text elements in the Artifactory configuration file
      # of a node matching the specified xpath
      #
      # @param [String] xpath
      #   xpath expression for the element whose siblings are to be found
      #
      # @param [REXML] config
      #   Artifactory configuration file as an REXML doc
      #
      # @param [Hash] options
      #   the list of options
      #
      def find_from_config(xpath, config, options = {})
        name_node = REXML::XPath.match(config, xpath)
        return nil if name_node.empty?
        properties = Util.xml_to_hash(name_node[0].parent, 'excludedRepositories', false)
        from_hash(properties, options)
      end
    end

    attribute :key, ->{ raise 'name missing!' }
    attribute :enabled, true
    attribute :dir
    attribute :cron_exp
    attribute :retention_period_hours
    attribute :create_archive
    attribute :excluded_repositories
    attribute :send_mail_on_error
    attribute :exclude_builds
  end
end