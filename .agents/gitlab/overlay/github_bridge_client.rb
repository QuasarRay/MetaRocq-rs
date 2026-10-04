# frozen_string_literal: true

require 'cgi'

module Aegis
  module GithubBridge
    class Client
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
        raise ArgumentError, 'GitHub bridge is not enabled' unless configuration.enabled?
      end

      def repository
        get('')
      end

      def branches
        get('/branches', per_page: 100)
      end

      def pull_requests
        get('/pulls', state: 'open', per_page: 100)
      end

      def workflow_runs
        value = get('/actions/runs', per_page: 50)
        value.is_a?(Hash) ? Array(value['workflow_runs']) : []
      end

      def rulesets
        get('/rulesets', includes_parents: true)
      rescue Octokit::NotFound
        []
      end

      def actions_permissions
        get('/actions/permissions')
      rescue Octokit::NotFound
        {}
      end

      def branch_protection(branch)
        get("/branches/#{escape(branch)}/protection")
      rescue Octokit::NotFound
        nil
      end

      def commits
        get('/commits', per_page: 20)
      end

      def combined_status(sha)
        get("/commits/#{escape(sha)}/status")
      rescue Octokit::NotFound
        {}
      end

      def get(suffix, params = {})
        request(:get, suffix, params)
      end

      def post(suffix, params = {})
        request(:post, suffix, params)
      end

      def patch(suffix, params = {})
        request(:patch, suffix, params)
      end

      def put(suffix, params = {})
        request(:put, suffix, params)
      end

      private

      def request(method, suffix, params)
        importer.with_rate_limit do
          normalize(octokit.public_send(method, "#{base_path}#{suffix}", params))
        end
      end

      def importer
        explicit_host = URI.parse(configuration.api_host).host == 'github.com' ? nil : configuration.api_host
        @importer ||= Gitlab::GithubImport::Client.new(
          configuration.token,
          host: explicit_host,
          parallel: true
        )
      end

      def octokit
        importer.octokit
      end

      def base_path
        "/repos/#{configuration.repository}"
      end

      def escape(value)
        CGI.escape(value.to_s).gsub('+', '%20')
      end

      def normalize(value)
        case value
        when Array
          value.map { |item| normalize(item) }
        when Hash
          value.to_h { |key, item| [key.to_s, normalize(item)] }
        else
          return normalize(value.to_h) if value.respond_to?(:to_h) && !value.is_a?(String)

          value
        end
      end
    end
  end
end
