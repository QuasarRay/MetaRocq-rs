# frozen_string_literal: true

require 'cgi'

module Aegis
  module GithubBridge
    class MutationService
      REPOSITORY_SETTING_KEYS = %w[
        default_branch allow_squash_merge allow_merge_commit allow_rebase_merge
        allow_auto_merge delete_branch_on_merge use_squash_pr_title_as_default
        squash_merge_commit_title squash_merge_commit_message
        merge_commit_title merge_commit_message web_commit_signoff_required
      ].freeze
      PROTECTION_KEYS = %w[
        required_status_checks enforce_admins required_pull_request_reviews restrictions
        required_linear_history allow_force_pushes allow_deletions block_creations
        required_conversation_resolution lock_branch allow_fork_syncing
      ].freeze
      RULESET_KEYS = %w[name target enforcement bypass_actors conditions rules].freeze
      MERGE_METHODS = %w[merge squash rebase].freeze
      SHA = /\A[0-9a-f]{40}\z/i
      BRANCH = %r{\A(?!/)(?!.*\.\.)(?!.*//)(?!.*@\{)(?!.*[~^:?*\[\\])[A-Za-z0-9._/-]+(?<![/.])\z}

      def initialize(project)
        @project = project
        @configuration = Configuration.for(project)
        raise Gitlab::Access::AccessDeniedError, 'GitHub bridge writes are disabled' unless configuration.writable?
      end

      def execute(operation, payload)
        body = payload.is_a?(Hash) ? payload.deep_stringify_keys : {}
        case operation.to_s
        when 'create_branch' then create_branch(body)
        when 'create_pull_request' then create_pull_request(body)
        when 'merge_pull_request' then merge_pull_request(body)
        when 'rerun_failed_workflow' then rerun_failed_workflow(body)
        when 'dispatch_workflow' then dispatch_workflow(body)
        when 'update_repository_settings' then update_repository_settings(body)
        when 'update_branch_protection' then update_branch_protection(body)
        when 'update_ruleset' then update_ruleset(body)
        when 'publish_commit_status' then publish_commit_status(body)
        else
          raise ArgumentError, "unsupported GitHub bridge operation: #{operation}"
        end
      end

      private

      attr_reader :project, :configuration

      def client
        @client ||= Client.new(configuration)
      end

      def create_branch(payload)
        name = branch!(payload.fetch('name'))
        sha = sha!(payload.fetch('sha'))
        client.post('/git/refs', ref: "refs/heads/#{name}", sha: sha)
      end

      def create_pull_request(payload)
        client.post(
          '/pulls',
          title: string!(payload.fetch('title'), 'title'),
          head: branch!(payload.fetch('head')),
          base: branch!(payload.fetch('base')),
          body: payload['body'].to_s,
          draft: payload['draft'] == true
        )
      end

      def merge_pull_request(payload)
        number = positive_integer!(payload.fetch('number'), 'number')
        expected = sha!(payload.fetch('expected_head_sha'))
        method = payload.fetch('merge_method', 'merge').to_s
        raise ArgumentError, 'invalid merge_method' unless MERGE_METHODS.include?(method)

        client.put("/pulls/#{number}/merge", sha: expected, merge_method: method)
      end

      def rerun_failed_workflow(payload)
        run_id = positive_integer!(payload.fetch('run_id'), 'run_id')
        client.post("/actions/runs/#{run_id}/rerun-failed-jobs")
      end

      def dispatch_workflow(payload)
        workflow = CGI.escape(payload.fetch('workflow_id').to_s).gsub('+', '%20')
        ref = branch!(payload.fetch('ref'))
        inputs = payload['inputs'].is_a?(Hash) ? payload['inputs'] : {}
        client.post("/actions/workflows/#{workflow}/dispatches", ref: ref, inputs: inputs)
      end

      def update_repository_settings(payload)
        settings = payload.slice(*REPOSITORY_SETTING_KEYS)
        raise ArgumentError, 'no supported repository settings supplied' if settings.empty?

        client.patch('', settings)
      end

      def update_branch_protection(payload)
        branch = branch!(payload.fetch('branch'))
        protection = payload.fetch('protection')
        raise ArgumentError, 'protection must be an object' unless protection.is_a?(Hash)

        body = protection.deep_stringify_keys.slice(*PROTECTION_KEYS)
        required = %w[required_status_checks enforce_admins required_pull_request_reviews restrictions]
        missing = required - body.keys
        raise ArgumentError, "missing branch protection fields: #{missing.join(', ')}" if missing.any?

        client.put("/branches/#{CGI.escape(branch).gsub('+', '%20')}/protection", body)
      end

      def update_ruleset(payload)
        ruleset_id = positive_integer!(payload.fetch('ruleset_id'), 'ruleset_id')
        ruleset = payload.fetch('ruleset')
        raise ArgumentError, 'ruleset must be an object' unless ruleset.is_a?(Hash)

        body = ruleset.deep_stringify_keys.slice(*RULESET_KEYS)
        required = %w[name target enforcement conditions rules]
        missing = required - body.keys
        raise ArgumentError, "missing ruleset fields: #{missing.join(', ')}" if missing.any?

        client.put("/rulesets/#{ruleset_id}", body)
      end

      def publish_commit_status(payload)
        sha = sha!(payload.fetch('sha'))
        state = payload.fetch('state').to_s
        raise ArgumentError, 'invalid status state' unless %w[error failure pending success].include?(state)

        body = {
          state: state,
          context: string!(payload.fetch('context'), 'context'),
          description: payload['description'].to_s[0, 140],
          target_url: payload['target_url'].to_s.presence
        }.compact
        client.post("/statuses/#{sha}", body)
      end

      def positive_integer!(value, name)
        parsed = Integer(value)
        raise ArgumentError, "#{name} must be positive" unless parsed.positive?

        parsed
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{name} must be a positive integer"
      end

      def sha!(value)
        text = value.to_s
        raise ArgumentError, 'expected exact 40-hex commit SHA' unless text.match?(SHA)

        text
      end

      def branch!(value)
        text = value.to_s
        raise ArgumentError, 'invalid branch name' unless text.match?(BRANCH)

        text
      end

      def string!(value, name)
        text = value.to_s.strip
        raise ArgumentError, "#{name} must not be empty" if text.blank?

        text
      end
    end
  end
end
