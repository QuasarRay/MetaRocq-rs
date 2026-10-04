# frozen_string_literal: true

get '/-/aegis/projects/:project_id',
  to: 'aegis/supervision#show',
  as: :aegis_project_supervision

get '/-/aegis/projects/:project_id/github',
  to: 'aegis/github#show',
  as: :aegis_project_github

post '/-/aegis/projects/:project_id/github/actions',
  to: 'aegis/github#mutate',
  as: :aegis_project_github_mutate
