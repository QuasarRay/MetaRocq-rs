# frozen_string_literal: true

module Mcp
  module Tools
    module Aegis
      class MutateGithubService < Base::CustomService
        extend ::Gitlab::Utils::Override

        def self.namespace_arguments
          { project: :id }
        end

        register_version '0.1.0', {
          toolset: :core,
          description: 'Perform an explicitly allowed GitHub repository operation through the host-admin-enabled Aegis bridge.',
          input_schema: {
            type: 'object',
            properties: {
              id: { type: 'string', description: 'GitLab project ID or full path' },
              operation: {
                type: 'string',
                enum: %w[
                  create_branch create_pull_request merge_pull_request
                  rerun_failed_workflow dispatch_workflow update_repository_settings
                  update_branch_protection update_ruleset publish_commit_status
                ]
              },
              payload: { type: 'object', additionalProperties: true }
            },
            required: %w[id operation payload]
          }
        }

        protected

        def auth_ability
          :admin_project
        end

        def auth_target(params)
          arguments = params[:arguments] || {}
          find_project!(arguments[:id])
        end

        def perform_default(arguments = {})
          project = find_project!(arguments[:id])
          data = ::Aegis::GithubBridge::MutationService.new(project).execute(
            arguments[:operation],
            arguments[:payload]
          )
          normalized = data.respond_to?(:to_h) ? data.to_h.deep_stringify_keys : { 'accepted' => true }
          ::Mcp::Tools::Base::Response.success(
            [{ type: 'text', text: Gitlab::Json.generate(normalized) }],
            normalized
          )
        end
      end
    end
  end
end
