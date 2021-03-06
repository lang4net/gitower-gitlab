module Gitlab
  module GithubImport
    class ProjectCreator
      attr_reader :repo, :name, :namespace, :current_user, :session_data

      def initialize(repo, name, namespace, current_user, session_data)
        @repo = repo
        @name = name
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: name,
          path: name,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: visibility_level,
          import_type: "github",
          import_source: repo.full_name,
          import_url: import_url,
          skip_wiki: skip_wiki
        ).execute
      end

      private

      def import_url
        repo.clone_url.sub('https://', "https://#{session_data[:github_access_token]}@")
      end

      def visibility_level
        repo.private ? Gitlab::VisibilityLevel::PRIVATE : ApplicationSetting.current.default_project_visibility
      end

      #
      # If the GitHub project repository has wiki, we should not create the
      # default wiki. Otherwise the GitHub importer will fail because the wiki
      # repository already exist.
      #
      def skip_wiki
        repo.has_wiki?
      end
    end
  end
end
