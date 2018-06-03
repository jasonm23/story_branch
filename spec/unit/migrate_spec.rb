require 'spec_helper'
require 'story_branch/commands/migrate'

RSpec.describe StoryBranch::Commands::Migrate do
  let(:output) { ::StringIO.new }

  describe 'when no configuration is found in any of the possibilities' do
    before do
      ENV['PIVOTAL_API_KEY'] = ''
      ENV['PIVOTAL_PROJECT_ID'] = ''
      FakeFS.with_fresh do
        FileUtils.mkdir_p Dir.home
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)
      end
    end

    it 'should print an informative error message' do
      expected_message = <<-MESSAGE
Old configuration not found.
Trying to start from scratch? Use story_branch add
      MESSAGE

      expect(output.string).to eq expected_message
    end
  end

  describe 'when configuration is all defined in home dir' do
    let(:prompt) { TTY::TestPrompt.new }

    before do
      allow(::TTY::Prompt).to receive(:new).and_return(prompt)
      ENV['PIVOTAL_API_KEY'] = ''
      ENV['PIVOTAL_PROJECT_ID'] = ''
      FakeFS.with_fresh do
        FileUtils.mkdir_p Dir.home
        create_old_file
        prompt.input << "my-test-project\r"
        prompt.input.rewind
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)
      end
    end

    it 'asks for the project name' do
      question = "What should be this project's name\?"
      expect(prompt.output.string).to match(question)
    end

    it 'creates a config file in home folder in the new format' do
      config = TTY::Config.new
      config.append_path(Dir.home)
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch('my-test-project', :api_key)).to eq 'DUMMYVALUE'
      expect(config.fetch('my-test-project', :project_id)).to eq '213976'
    end

    it 'removes the old config file' do
      expect(File.exist?("#{Dir.home}/.story_branch")).to eq false
    end
  end

  describe 'when configuration is all defined in ENV vars' do
    let(:prompt) { TTY::TestPrompt.new }

    before do
      allow(::TTY::Prompt).to receive(:new).and_return(prompt)
      ENV['PIVOTAL_API_KEY'] = 'DUMMYKEY'
      ENV['PIVOTAL_PROJECT_ID'] = '123456'
      FakeFS.with_fresh do
        FileUtils.mkdir_p Dir.home
        prompt.input << "my-test-project\r"
        prompt.input.rewind
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)
      end
    end

    it 'asks for the project name' do
      question = "What should be this project's name\?"
      expect(prompt.output.string).to match(question)
    end

    it 'creates a config file in home folder in the new format' do
      config = TTY::Config.new
      config.append_path(Dir.home)
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch('my-test-project', :api_key)).to eq 'DUMMYKEY'
      expect(config.fetch('my-test-project', :project_id)).to eq '123456'
    end
  end

  describe 'when configuration is shared between ENV vars and config file' do
    let(:prompt) { TTY::TestPrompt.new }

    before do
      allow(::TTY::Prompt).to receive(:new).and_return(prompt)
      ENV['PIVOTAL_API_KEY'] = 'DUMMYKEY'
      ENV['PIVOTAL_PROJECT_ID'] = ''
      FakeFS.with_fresh do
        FileUtils.mkdir_p Dir.home
        prompt.input << "my-test-project\r"
        prompt.input.rewind
        create_old_file('.', false)
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)
      end
    end

    it 'asks for the project name' do
      question = "What should be this project's name\?"
      expect(prompt.output.string).to match(question)
    end

    it 'creates a config file in home folder in the new format' do
      config = TTY::Config.new
      config.append_path(Dir.home)
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch('my-test-project', :api_key)).to eq 'DUMMYKEY'
      expect(config.fetch('my-test-project', :project_id)).to eq '213976'
    end

    it 'creates a config file in the project folder' do
      config = TTY::Config.new
      config.append_path('.')
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch(:project_name)).to eq 'my-test-project'
    end
  end

  describe 'running the migration tool in different existing projects' do
    let(:prompt) { TTY::TestPrompt.new }

    before do
      allow(::TTY::Prompt).to receive(:new).and_return(prompt)
      ENV['PIVOTAL_API_KEY'] = 'DUMMYKEY'
      ENV['PIVOTAL_PROJECT_ID'] = ''
      FakeFS.with_fresh do
        FileUtils.mkdir_p Dir.home
        prompt.input << "my-test-project\rmy-second-project"
        prompt.input.rewind
        create_old_file('.', false)
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)

        # NOTE: Simulate new project folder
        FileUtils.rm './.story_branch.yml'
        create_old_file('.', false)
        command = StoryBranch::Commands::Migrate.new({})
        command.execute(output: output)
      end
    end

    it 'updates the config file in home folder in the new format' do
      config = TTY::Config.new
      config.append_path(Dir.home)
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch('my-test-project', :api_key)).to eq 'DUMMYKEY'
      expect(config.fetch('my-test-project', :project_id)).to eq '213976'
      expect(config.fetch('my-second-project', :api_key)).to eq 'DUMMYKEY'
      expect(config.fetch('my-second-project', :project_id)).to eq '213976'
      config = TTY::Config.new
      config.append_path('.')
      config.filename = '.story_branch'
      expect(config.persisted?).to eq true
      config.read
      expect(config.fetch(:project_name)).to eq 'my-second-project'
    end
  end
end
