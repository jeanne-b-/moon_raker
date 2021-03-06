require 'spec_helper'
require 'fileutils'

describe MoonRaker::MoonRakerController do

  describe "GET index" do

    it "succeeds on index" do
      get :index

      assert_response :success
    end

    it "succeeds on version details" do
      get :index, :version => "2.0"

      assert_response :success
    end

    it "returns not_found on wrong version" do
      get :index, :version => "wrong_version"

      assert_response :not_found
    end

    it "succeeds on resource details" do
      get :index, :version => "2.0", :resource => "architectures"

      assert_response :success
    end

    it "returns not_found on wrong resource" do
      get :index, :version => "2.0", :resource => "wrong_resource"

      assert_response :not_found
    end

    it "succeeds on method details" do
      get :index, :version => "2.0", :resource => "architectures", :method => "index"

      assert_response :success
    end

    it "returns not_found on wrong method" do
      get :index, :version => "2.0", :resource => "architectures", :method => "wrong_method"

      assert_response :not_found
    end
  end

  describe "reload_controllers" do

    RSpec::Matchers.define :reload_documentation do
      match do |actual|
        expect(MoonRaker).to receive(:reload_documentation)
        get :index
      end

      match_when_negated do |actual|
        expect(MoonRaker).not_to receive(:reload_documentation)
        get :index
      end

      failure_message { "the documentation expected to be reloaded but it was not" }
      failure_message_when_negated { "the documentation expected not to be reloaded but it was" }
    end

    before do
      MoonRaker.configuration.api_controllers_matcher = File.join(Rails.root, "app", "controllers", "**","*.rb")
      if MoonRaker.configuration.send :instance_variable_defined?, "@reload_controllers"
        MoonRaker.configuration.send :remove_instance_variable, "@reload_controllers"
      end
    end

    context "it's not specified explicitly" do
      context "and it's in development environment" do
        before do
          allow(Rails).to receive_messages(:env => double(:development? => true))
        end
        it { is_expected.to reload_documentation }
      end

      context "and it's not development environment" do
        it { is_expected.not_to reload_documentation }
      end
    end


    context "it's explicitly enabled" do
      before do
        MoonRaker.configuration.reload_controllers = true
      end

      context "and it's in development environment" do
        before do
          allow(Rails).to receive_messages(:env => double(:development? => true))
        end
        it { is_expected.to reload_documentation }
      end

      context "and it's not development environment" do
        it { is_expected.to reload_documentation }
      end
    end

    context "it's explicitly enabled" do
      before do
        MoonRaker.configuration.reload_controllers = false
      end

      context "and it's in development environment" do
        before do
          allow(Rails).to receive_messages(:env => double(:development? => true))
        end
        it { is_expected.not_to reload_documentation }
      end

      context "and it's not development environment" do
        it { is_expected.not_to reload_documentation }
      end
    end

    context "api_controllers_matcher is specified" do
      before do
        MoonRaker.configuration.reload_controllers = true
        MoonRaker.configuration.api_controllers_matcher = nil
      end

      it { is_expected.not_to reload_documentation }
    end
  end

  describe "authenticate user" do
    it "authenticate user if an authentication method is setted" do
      test = false
      MoonRaker.configuration.authenticate = Proc.new do
        test = true
      end
      get :index
      expect(test).to eq(true)
    end
  end

  describe "authorize document" do
    it "if an authroize method is set" do
      test = false
      MoonRaker.configuration.authorize = Proc.new do |controller, method, doc|
        test = true
        true
      end
      get :index
      expect(test).to eq(true)
    end
    it "remove all resources" do
      MoonRaker.configuration.authorize = Proc.new do |&args|
        false
      end
      get :index
      expect(assigns(:doc)[:resources]).to eq({})
    end
    it "remove all methods" do
      MoonRaker.configuration.authorize = Proc.new do |controller, method, doc|
        !method
      end
      get :index
      expect(assigns(:doc)[:resources]["concern_resources"][:methods]).to eq([])
      expect(assigns(:doc)[:resources]["twitter_example"][:methods]).to eq([])
      expect(assigns(:doc)[:resources]["users"][:methods]).to eq([])
    end
    it "remove specific method" do
      MoonRaker.configuration.authorize = nil
      get :index

      users_methods = assigns(:doc)[:resources]["users"][:methods].size
      twitter_example_methods = assigns(:doc)[:resources]["twitter_example"][:methods].size

      MoonRaker.configuration.authorize = Proc.new do |controller, method, doc|
        controller == "users" ? method != "index" : true
      end

      get :index

      expect(assigns(:doc)[:resources]["users"][:methods].size).to eq(users_methods - 1)
      expect(assigns(:doc)[:resources]["twitter_example"][:methods].size).to eq(twitter_example_methods)
    end
  end

  describe "documentation cache" do

    let(:cache_dir) { File.join(Rails.root, "tmp", "moon_raker-cache") }

    before do
      FileUtils.rm_r(cache_dir) if File.exists?(cache_dir)
      FileUtils.mkdir_p(File.join(cache_dir, "apidoc", "v1", "resource"))
      File.open(File.join(cache_dir, "apidoc", "v1.html"), "w") { |f| f << "apidoc.html cache v1" }
      File.open(File.join(cache_dir, "apidoc", "v2.html"), "w") { |f| f << "apidoc.html cache v2" }
      File.open(File.join(cache_dir, "apidoc", "v1.json"), "w") { |f| f << "apidoc.json cache" }
      File.open(File.join(cache_dir, "apidoc", "v1", "resource.html"), "w") { |f| f << "resource.html cache" }
      File.open(File.join(cache_dir, "apidoc", "v1", "resource", "method.html"), "w") { |f| f << "method.html cache" }

      MoonRaker.configuration.use_cache = true
      @orig_cache_dir = MoonRaker.configuration.cache_dir
      MoonRaker.configuration.cache_dir = cache_dir
      @orig_version = MoonRaker.configuration.default_version
      MoonRaker.configuration.default_version = 'v1'
    end

    after do
      MoonRaker.configuration.use_cache = false
      MoonRaker.configuration.default_version = @orig_version
      MoonRaker.configuration.cache_dir = @orig_cache_dir
      # FileUtils.rm_r(cache_dir) if File.exists?(cache_dir)
    end

    it "uses the file in cache dir instead of generating the content on runtime" do
      get :index
      expect(response.body).to eq("apidoc.html cache v1")
      get :index, :version => 'v1'
      expect(response.body).to eq("apidoc.html cache v1")
      get :index, :version => 'v2'
      expect(response.body).to eq("apidoc.html cache v2")
      get :index, :version => 'v1', :format => "html"
      expect(response.body).to eq("apidoc.html cache v1")
      get :index, :version => 'v1', :format => "json"
      expect(response.body).to eq("apidoc.json cache")
      get :index, :version => 'v1', :format => "html", :resource => "resource"
      expect(response.body).to eq("resource.html cache")
      get :index, :version => 'v1', :format => "html", :resource => "resource", :method => "method"
      expect(response.body).to eq("method.html cache")
    end

  end
end
