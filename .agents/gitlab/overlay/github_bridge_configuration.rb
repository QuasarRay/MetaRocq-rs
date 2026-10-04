# frozen_string_literal: true

module Aegis
  module GithubBridge
    class Configuration
      TOKEN_ENV = 'AEGIS_GITHUB_TOKEN'
      HOST_ENV = 'AEGIS_GITHUB_HOST'
      ALLOWED_HOSTS_ENV = 'AEGIS_GITHUB_ALLOWED_HOSTS'
      MAP_ENV = 'AEGIS_GITHUB_REPOSITORY_MAP'
      AUTO_MAP_ENV = 'AEGIS_GITHUB_AUTO_MAP'
      REPOSITORY = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\z}
      TRUE_VALUES = %w[1 true yes on].freeze

      attr_reader :repository, :host, :mapping_source

      def self.for(project)
        mapping = instance_mapping.fetch(project.full_path, nil)
        if mapping
          repository = mapping.is_a?(String) ? mapping : mapping['repository']
          writable = mapping.is_a?(Hash) && mapping['write'] == true
          return new(repository: repository, writable: writable, mapping_source: 'instance-map')
        end

        if auto_map? && project.full_path.match?(REPOSITORY)
          return new(repository: project.full_path, writable: false, mapping_source: 'auto-map')
        end

        new(repository: nil, writable: false, mapping_source: 'disabled')
      end

      def self.instance_mapping
        raw = ENV.fetch(MAP_ENV, '{}')
        parsed = Gitlab::Json.parse(raw)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end

      def self.auto_map?
        TRUE_VALUES.include?(ENV.fetch(AUTO_MAP_ENV, '').downcase)
      end

      def initialize(repository:, writable:, mapping_source:)
        @repository = repository.to_s.presence
        @writable = writable
        @mapping_source = mapping_source
        @host = ENV.fetch(HOST_ENV, 'https://github.com').sub(%r{/+\z}, '')
        validate!
      end

      def enabled?
        repository.present? && token.present?
      end

      def configured?
        repository.present?
      end

      def writable?
        enabled? && @writable
      end

      def token
        ENV[TOKEN_ENV].to_s.presence
      end

      def web_url
        return unless repository

        "#{host}/#{repository}"
      end

      def api_host
        host
      end

      def public_state
        {
          configured: configured?,
          enabled: enabled?,
          writable: writable?,
          repository: repository,
          host: host,
          mapping_source: mapping_source,
          credential_present: token.present?
        }
      end

      private

      def validate!
        raise ArgumentError, 'invalid GitHub repository mapping' if repository && !repository.match?(REPOSITORY)

        uri = URI.parse(host)
        raise ArgumentError, 'GitHub bridge requires HTTPS' unless uri.scheme == 'https' && uri.host.present?
        raise ArgumentError, 'GitHub bridge host is not allowlisted' unless allowed_hosts.include?(uri.host.downcase)
      rescue URI::InvalidURIError
        raise ArgumentError, 'invalid GitHub bridge host'
      end

      def allowed_hosts
        configured = ENV.fetch(ALLOWED_HOSTS_ENV, '').split(',').map { |item| item.strip.downcase }.reject(&:blank?)
        (['github.com'] + configured).uniq
      end
    end
  end
end
