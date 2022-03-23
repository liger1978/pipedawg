# frozen_string_literal: true

RSpec.describe Pipedawg::Job::Qualys::Scan do
  context 'when creating a Qualys scan job' do
    let :job do
      described_class.new 'myimage', acceptable_risk: 2, scan_image: 'myimage',
                                     config: { 'local.registry': { username: 'myuser', password: 'mypassword' } }
    end

    it 'correctly logs into destination registry in job script' do
      expect(job.opts[:script]).to include
      'echo "{"local.registry":{"username":"myuser","password":"mypassword"}}" > "${CONFIG}/config.json"'
    end

    it 'correctly pulls image in job script' do
      expect(job.opts[:script]).to include 'docker --config="${CONFIG}" pull "myimage"'
    end

    it 'correctly retags image in job script' do
      expect(job.opts[:script]).to include 'docker image tag "myimage" "${image_target}"'
    end

    it 'correctly gets software list in job script' do
      expect(job.opts[:script]).to include
      'curl -s --location --request GET "https://${QUALYS_GATEWAY}/csapi/v1.2/images/$image_id/software" --header "Authorization: Bearer $token" | jq . > software.json' # rubocop:disable Layout/LineLength
    end

    it 'correctly gets vulnerability list in job script' do
      expect(job.opts[:script]).to include
      'curl -s --location --request GET "https://${QUALYS_GATEWAY}/csapi/v1.2/images/$image_id/vuln" --header "Authorization: Bearer $token" | jq . > vulnerabilities.json' # rubocop:disable Layout/LineLength
    end

    it 'correctly fails the scan if the risk is too high in job script' do
      expect(job.opts[:script]).to include
      'if (($risk > "2")); then echo "Too many vulnerabilities. Severity5: $severity5, Severity4: $severity4" >&2; exit 1; fi' # rubocop:disable Layout/LineLength
    end
  end
end
