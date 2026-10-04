# frozen_string_literal: true

module Aegis
  module GithubBridge
    class Snapshot
      def initialize(project)
        @project = project
        @configuration = Configuration.for(project)
      end

      def call
        state = configuration.public_state.merge(
          available: false,
          web_url: configuration.web_url,
          independence: 'GitLab/Aegis remains authoritative and operable without GitHub'
        )
        return state.merge(reason: 'repository mapping or server credential not configured') unless configuration.enabled?

        repository = client.repository
        default_branch = repository['default_branch']
        commits = client.commits
        head_sha = commits.first.is_a?(Hash) ? commits.first['sha'] : nil

        state.merge(
          available: true,
          repository_settings: repository.slice(
            'id', 'full_name', 'visibility', 'private', 'archived', 'default_branch',
            'allow_merge_commit', 'allow_squash_merge', 'allow_rebase_merge',
            'allow_auto_merge', 'delete_branch_on_merge', 'web_commit_signoff_required',
            'html_url'
          ),
          branches: compact_branches(client.branches),
          branch_protection: default_branch ? client.branch_protection(default_branch) : nil,
          rulesets: client.rulesets,
          actions_permissions: client.actions_permissions,
          workflow_runs: compact_runs(client.workflow_runs),
          pull_requests: compact_pulls(client.pull_requests),
          recent_commits: compact_commits(commits),
          head_status: head_sha ? client.combined_status(head_sha) : {}
        )
      rescue StandardError => error
        Gitlab::ErrorTracking.track_exception(error, project_id: project.id, feature: 'aegis_github_bridge')
        state.merge(
          available: false,
          reason: 'GitHub API unavailable',
          error_class: error.class.name
        )
      end

      private

      attr_reader :project, :configuration

      def client
        @client ||= Client.new(configuration)
      end

      def compact_branches(items)
        Array(items).map do |branch|
          {
            'name' => branch['name'],
            'protected' => branch['protected'],
            'sha' => branch.dig('commit', 'sha')
          }
        end
      end

      def compact_pulls(items)
        Array(items).map do |pull|
          {
            'number' => pull['number'],
            'title' => pull['title'],
            'state' => pull['state'],
            'draft' => pull['draft'],
            'html_url' => pull['html_url'],
            'head_sha' => pull.dig('head', 'sha'),
            'head_ref' => pull.dig('head', 'ref'),
            'base_ref' => pull.dig('base', 'ref')
          }
        end
      end

      def compact_runs(items)
        Array(items).map do |run|
          {
            'id' => run['id'],
            'name' => run['name'],
            'event' => run['event'],
            'status' => run['status'],
            'conclusion' => run['conclusion'],
            'head_sha' => run['head_sha'],
            'html_url' => run['html_url'],
            'run_number' => run['run_number']
          }
        end
      end

      def compact_commits(items)
        Array(items).map do |commit|
          {
            'sha' => commit['sha'],
            'html_url' => commit['html_url'],
            'message' => commit.dig('commit', 'message'),
            'author' => commit.dig('commit', 'author', 'name')
          }
        end
      end
    end
  end
end
