# frozen_string_literal: true

require "uri"
require "net/http"

class DeploymentType < Decidim::Api::Types::BaseObject
  description "Deployment's related properties."

  field :current_commit, GraphQL::Types::String, "The current commit hash for this deployment", null: false
  field :branch, GraphQL::Types::String, "The current branch name for this deployment", null: false
  field :version, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false
  field :up_to_date, GraphQL::Types::Boolean, "Comparison between current_commit and latest_commit", null: false
  field :latest_commit, GraphQL::Types::String, "Latest commit on the remote branch", null: false
  field :locally_modified, GraphQL::Types::Boolean, "Output of git status", null: false
  field :remote, GraphQL::Types::String, "The remote used on this deployment", null: true
  field :repo_name, GraphQL::Types::String, "The repository name used on this deployment", null: true
  field :repo_owner, GraphQL::Types::String, "The repository owner used on this deployment", null: true

  def current_commit
    `git rev-parse HEAD`.strip
  end

  def version
    Decidim.version
  end

  def remote
    `git ls-remote --get-url`.strip
  end

  def branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def up_to_date
    current_commit == latest_commit
  end

  def latest_commit
    url = URI("https://api.github.com/repos/#{repo_owner}/#{repo_name}/commits/#{branch}")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)

    response = https.request(request)
    if response.code == "200"
      JSON.parse(response.read_body)["sha"]
    else
      ""
    end
  end

  def locally_modified
    !`git status --porcelain`.strip.empty?
  end

  def partial_url
    remote.split("/")[-2..]
  end

  def repo_name
    partial_url.last.sub(/(.git)(?!.*\1)/, "")
  end

  def repo_owner
    partial_url.first
  end
end
