# frozen_string_literal: true

RSpec.describe Pipedawg::Job::Kaniko::Build do
  context 'when creating a Kaniko build job' do
    let :job do
      described_class.new 'myimage', config: { 'local.registry': { username: 'myuser', password: 'mypassword' } },
                                     destinations: ['local.registry/myimage:v1.0.0']
    end

    it 'correctly logs into destination registry in job script' do
      expect(job.opts[:script]).to include
      'echo "{"local.registry":{"username":"myuser","password":"mypassword"}}" > "/kaniko/.docker/config.json"'
    end

    it 'correctly builds and pushes image in job script' do
      expect(job.opts[:script]).to include
      '"/kaniko/executor" --context "${CI_PROJECT_DIR}" --dockerfile "Dockerfile" --destination local.registry/myimage:v1.0.0' # rubocop:disable Layout/LineLength
    end
  end
end
