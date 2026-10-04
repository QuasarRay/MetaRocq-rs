# frozen_string_literal: true

module Aegis
  class SupervisionController < ApplicationController
    feature_category :source_code_management
    urgency :low

    def show
      @project = Project.find(params[:project_id])
      return access_denied! unless can?(current_user, :read_code, @project)

      @snapshot = ::Aegis::RepositorySnapshot.new(@project).call
    end
  end
end
