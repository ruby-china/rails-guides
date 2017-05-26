$:.unshift __dir__

require "rails_guides/generator"
require "rails_guides/cn" # PLEASE DO NOT FORGET ME
require "active_support/core_ext/object/blank"

env_value = ->(name) { ENV[name].presence }
env_flag  = ->(name) { "1" == env_value[name] }

version = env_value["RAILS_VERSION"]
edge    = `git rev-parse HEAD`.strip unless version

RailsGuides::Generator.new(
  edge:     edge,
  version:  version,
  all:      env_flag["ALL"],
  only:     env_value["ONLY"],
  kindle:   env_flag["KINDLE"],
  language: env_value["GUIDES_LANGUAGE"]
).generate
