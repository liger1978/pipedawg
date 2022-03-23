# frozen_string_literal: true

RSpec.describe Pipedawg::Job::Helm::Copy do
  context 'when creating a Helm copy job' do
    let :job do
      described_class.new 'kong', url: 'https://charts.konghq.com', version: '2.6.2',
                                  destinations: [url: 'oci://foo.test', user: 'myuser', password: 'mypassword']
    end

    it 'correctly adds source repo in job script' do
      expect(job.opts[:script]).to include '"helm" repo add source "https://charts.konghq.com"'
    end

    it 'correctly pulls chart version from source repo in job script' do
      expect(job.opts[:script]).to include '"helm" pull "source/kong" --version "2.6.2"'
    end

    it 'correctly sets HELM_EXPERIMENTAL_OCI environment variable in job script' do
      expect(job.opts[:script]).to include 'export HELM_EXPERIMENTAL_OCI=1'
    end

    it 'correctly logs into destination registry in job script' do
      expect(job.opts[:script]).to include
      'echo "mypassword" | "helm" registry login --username "myuser" --password-stdin "foo.test"'
    end

    it 'correctly pushes chart to destination registry in job script' do
      expect(job.opts[:script]).to include '"helm" push "kong-2.6.2.tgz" "oci://foo.test"'
    end
  end
end
