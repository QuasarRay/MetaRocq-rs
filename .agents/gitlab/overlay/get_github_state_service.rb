# frozen_string_literal: true

module Mcp
  module Tools
    module Aegis
      class GetGithubStateService < Base::CustomService
        extend ::Gitlab::Utils::Override

        def self.namespace_arguments
          { project: :id }
        end

        register_version '0.1.0', {
          toolset: :core,
          description: 'Read GitHub repository settings, policies, branches, pull requests, workflow runs, commits and status through the optional Aegis bridge.',
          annotations: { readOnlyHint: true },
          input_schema: {
            type: 'object',
            properties: {
              id: { type: 'string', description: 'GitLab project ID or full path' }
            },
            required: %w[id]
          }
        }

        protected

        def auth_ability
          :read_code
        end

        def auth_target(params)
          arguments = params[:arguments] || {}
          find_project!(arguments[:id])
        end

        def perform_default(arguments = {})
          project = find_project!(arguments[:id])
          data = ::Aegis::GithubBridge::Snapshot.new(project).call
          ::Mcp::Tools::Base::Response.success(
            [{ type: 'text', text: Gitlab::Json.generate(data) }],
            data
          )
        end
      end
    end
  end
end
