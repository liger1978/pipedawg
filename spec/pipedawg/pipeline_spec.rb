# frozen_string_literal: true

RSpec.describe Pipedawg::Pipeline do
  context 'when creating a pipeline' do
    let :kaniko_build_job do
      Pipedawg::Job::Kaniko::Build.new 'kaniko',
                                       config: { 'local.registry': { username: 'myuser', password: 'mypassword' } },
                                       destinations: ['local.registry/myimage:v1.0.0']
    end
    let :skopeo_copy_job do
      Pipedawg::Job::Skopeo::Copy.new 'skopeo',
                                      copy_image: 'local.registry/myimage:v1.0.0',
                                      logins: { 'local.registry': { username: 'myuser', password: 'mypassword' } },
                                      destinations: [{ copy_image: 'local.registry2/myimage:v1.0.0' }],
                                      trusted_ca_cert_source_files: ['/tmp/mycert.crt'], needs: ['kaniko']
    end

    let :pipeline do
      described_class.new 'pipeline', jobs: [kaniko_build_job, skopeo_copy_job]
    end

    before do
      pipeline.update
    end

    it 'correctly creates pipeline stages' do
      expect(pipeline.opts[:stages]).to eq %w[1 2]
    end
  end
end
