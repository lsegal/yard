workflow "Build, Test, and Publish" {
  on = "push"
  resolves = ["Install", "Test", "Package Gem", "On Tag", "Publish Gem", "Create GitHub Release"]
}

action "Install" {
  uses = "./.github/actions/install"
}

action "Test" {
  needs = "Install"
  uses = "./.github/actions/test"
}

action "Package Gem" {
  needs = "Test"
  uses = "./.github/actions/package"
}

action "On Tag" {
  needs = "Package Gem"
  uses = "actions/bin/filter@master"
  args = "tag v*"
}

action "Create GitHub Release" {
  needs = "On Tag"
  uses = "./.github/actions/release"
  secrets = ["RELEASE_TOKEN"]
  env = {
    ARTIFACT = "*.gem"
  }
}

action "Publish Gem" {
  needs = "Create GitHub Release"
  uses = "scarhand/actions-ruby@master"
  args = "push *.gem"
  secrets = ["RUBYGEMS_AUTH_TOKEN"]
}
