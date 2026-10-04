# frozen_string_literal: true

module Aegis
  class RepositorySnapshot
    ROADMAP = '.agents/roadmaps/metarocq-bootstrap.json'
    TASKS = '.agents/data/tasks.json'
    MANIFEST = '.agents/data/manifest.json'
    DEPLOYMENT = 'spec/aegis-deployment.json'
    STATUS = 'docs/STATUS.md'
    PATHS = [ROADMAP, TASKS, MANIFEST, DEPLOYMENT, STATUS].freeze

    def initialize(project)
      @project = project
    end

    def call
      roadmap = read_json(ROADMAP)
      task_registry = read_json(TASKS)
      manifest = read_json(MANIFEST)
      deployment = read_json(DEPLOYMENT)
      tasks = records(roadmap['tasks'])

      {
        schema: 1,
        project: { id: project.id, path: project.full_path, ref: ref },
        implementation_gate: roadmap.dig('policy', 'implementation_gate'),
        policy: roadmap['policy'] || {},
        tasks: tasks.map { |task| task_view(task, manifest) },
        registered_principals: records(task_registry).map { |item| item.slice('task', 'principal') },
        persistence: {
          events: manifest['events'],
          heads: hash_or_empty(manifest['heads']),
          claim: manifest['claim']
        },
        aegis_deployment: deployment.slice('repository', 'commit', 'claim'),
        status_markdown: read_text(STATUS),
        claim: 'read-only repository supervision view; formal completion requires independent replay'
      }
    end

    private

    attr_reader :project

    def ref
      project.default_branch.presence || project.repository.root_ref
    end

    def read_text(path)
      project.repository.blob_at(ref, path)&.data.to_s
    end

    def read_json(path)
      data = read_text(path)
      return {} if data.blank?

      parsed = Gitlab::Json.parse(data)
      parsed.is_a?(Hash) || parsed.is_a?(Array) ? parsed : {}
    rescue JSON::ParserError
      { '_error' => "invalid JSON at #{path}" }
    end

    def records(value)
      value.is_a?(Array) ? value.select { |item| item.is_a?(Hash) } : []
    end

    def hash_or_empty(value)
      value.is_a?(Hash) ? value : {}
    end

    def task_view(task, manifest)
      id = task['id']
      observed = hash_or_empty(manifest['heads']).key?(id)
      {
        id: id,
        kind: task['kind'],
        depends_on: Array(task['depends_on']),
        description: task['description'],
        acceptance: hash_or_empty(task['acceptance']),
        blockers: Array(task['blockers']),
        process_evidence_recorded: observed,
        proof_complete: false
      }
    end
  end
end
