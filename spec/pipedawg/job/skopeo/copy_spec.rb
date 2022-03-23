# frozen_string_literal: true

RSpec.describe Pipedawg::Job::Skopeo::Copy do
  context 'when creating a Skopeo copy job' do
    let :job do
      described_class.new 'myimage', logins: { 'local.registry': { username: 'myuser', password: 'mypassword' } },
                                     destinations: [{ copy_image: 'local.registry/myimage:v1.0.0' }],
                                     trusted_ca_cert_source_files: ['/tmp/mycert.crt']
    end

    it 'correctly creates cert directory in job script' do
      expect(job.opts[:script]).to include 'mkdir -p $(dirname "/etc/docker/certs.d/ca.crt")'
    end

    it 'correctly trusts cert in job script' do
      expect(job.opts[:script]).to include 'cat "/tmp/mycert.crt" >> "/etc/docker/certs.d/ca.crt"'
    end

    it 'correctly logs into destination registry in job script' do
      expect(job.opts[:script]).to include
      'echo "" | skopeo login --authfile "${CONFIG}/config.json" --username "" --password-stdin "local.registry"'
    end

    it 'correctly creates staging directory in job script' do
      expect(job.opts[:script]).to include 'mkdir -p "${CI_PROJECT_DIR}/stage"'
    end

    it 'correctly copies image from source registry to staging directory in job script' do
      expect(job.opts[:script]).to include
      'skopeo copy --authfile "${CONFIG}/config.json" docker://myimage "dir://${CI_PROJECT_DIR}/stage"'
    end

    it 'correctly copies image from staging directory to destination registry in job script' do
      expect(job.opts[:script]).to include
      'skopeo copy --authfile "${CONFIG}/config.json" "dir://${CI_PROJECT_DIR}/stage" docker://local.registry/myimage:v1.0.0' # rubocop:disable Layout/LineLength
    end
  end
end
