# frozen_string_literal: true

module Aegis
  class GithubController < ApplicationController
    feature_category :source_code_management
    urgency :low

    def show
      @project = Project.find(params[:project_id])
      return access_denied! unless can?(current_user, :read_code, @project)

      @state = ::Aegis::GithubBridge::Snapshot.new(@project).call
    end

    def mutate
      project = Project.find(params[:project_id])
      return access_denied! unless can?(current_user, :admin_project, project)

      payload = parse_payload(params[:payload])
      result = ::Aegis::GithubBridge::MutationService.new(project).execute(params[:operation], payload)
      redirect_to aegis_project_github_path(project_id: project.id),
        notice: "GitHub operation #{params[:operation]} completed: #{summarize(result)}"
    rescue JSON::ParserError
      redirect_to aegis_project_github_path(project_id: params[:project_id]),
        alert: 'GitHub operation payload must be valid JSON'
    rescue StandardError => error
      Gitlab::ErrorTracking.track_exception(error, feature: 'aegis_github_bridge_mutation')
      redirect_to aegis_project_github_path(project_id: params[:project_id]),
        alert: "GitHub operation failed: #{error.class.name}"
    end

    private

    def parse_payload(raw)
      return {} if raw.to_s.blank?

      parsed = Gitlab::Json.parse(raw.to_s)
      raise JSON::ParserError, 'payload must be an object' unless parsed.is_a?(Hash)

      parsed
    end

    def summarize(result)
      return 'accepted' if result.nil?
      return result['html_url'] if result.is_a?(Hash) && result['html_url'].present?
      return result['message'] if result.is_a?(Hash) && result['message'].present?

      'accepted'
    end
  end
end
