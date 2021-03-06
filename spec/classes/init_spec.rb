require 'spec_helper'

# Some contexts are holdovers from the original tpm module and haven't been
# validated yet.  They are currently being kept for reference during the tpm2
# transition, and may no longer be relevant.
xmessage = 'TODO: validate this spec, then activate or remove it.'

# Contains the tests for modules init and both install modules.
#
shared_examples_for 'tpm2 default' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('tpm2') }
  it { is_expected.to create_class('tpm2::install') }
  it { is_expected.to contain_package('tpm2-tools').with_ensure('installed') }
  it { is_expected.to contain_package('tpm2-tss').with_ensure('installed') }
  it { is_expected.to contain_package('tpm2-abrmd').with_ensure('installed') }
  it { is_expected.to create_class('tpm2::service') }
  it { is_expected.to contain_service('tpm2-abrmd') }
end

describe 'tpm2' do
  on_supported_os.each do |os, os_facts|
    context "tpm2 init on #{os}" do
      let(:facts) do
        os_facts.merge({
          :fqdn => 'myhost.com'
        })
      end

      context 'with default params' do
        if os_facts[:os][:release][:major].to_i < 7
          context 'on os version < 7 ' do
            it { is_expected.to_not compile}
          end
        else
          context 'on  os version => 7' do
            it_behaves_like "tpm2 default"
            it { is_expected.to_not create_class('tpm2::ownership') }
            it { is_expected.to_not contain_systemd__dropin_file('tabrm_service.conf') }
          end
        end
      end

#      context 'with detected TPM1 version TPM', :skip => xmessage do
      context 'with detected TPM1 version TPM' do
        let(:facts) do
          os_facts.merge({
            :tpm_version => 'tpm1'
          })
        end
        if os_facts[:os][:release][:major].to_i < 7
          context 'on os version < 7 ' do
            it { is_expected.to_not compile}
          end
        else
          context 'on  os version => 7' do
            it 'should work damn it' do
#            it { is_expected.to contain_notify('tpm2_with_tpm1').with_message("NOTICE: Host has a tpm1 device; skipping TPM2 resources from module 'tpm2'")}
               is_expected.to create_notify('tpm2_with_tpm1')
             end
          end
        end
      end

      context 'with service options' do
        let(:params) {{
          :tabrm_options => ['-option1', '-option2 X'],
          :tabrm_service => 'tpm2-abrmd-service'
        }}
        let(:hieradata) { 'take_ownership' }

        if os_facts[:os][:release][:major].to_i < 7
          context 'on os version < 7 ' do
            it { is_expected.to_not compile}
          end
        else
          context 'on os version >= 7 ' do
            it { is_expected.to contain_systemd__dropin_file('tabrm_service.conf').with({
              :unit => 'tpm2-abrmd-service.service',
              :notify => 'Service[tpm2-abrmd-service]'
            })}
            it { is_expected.to contain_systemd__dropin_file('tabrm_service.conf').with_content(<<-EOM.gsub(/^\s+/,'')
              # This file managed by Puppet
              [Service]
              ExecStart=
              ExecStart=/usr/sbin/tpm2-abrmd-service -option1 -option2 X
              EOM
            )}
          end
        end
      end

      context 'with take_ownership true' do
        let(:params) {{
          :take_ownership => true
        }}

        if os_facts[:os][:release][:major].to_i < 7
          context 'on os version < 7 ' do
            it { is_expected.to_not compile}
          end
        else
          context 'on os version >= 7 ' do
            it_behaves_like "tpm2 default"
            it { is_expected.to contain_class('tpm2::ownership') }
          end
        end
      # take_ownership true
      end
      #TPM2.0
    end
  end
end
