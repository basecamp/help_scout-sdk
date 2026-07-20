# frozen_string_literal: true

RSpec.describe HelpScout::API do
  describe '#get' do
    subject { HelpScout.api.get('mailboxes') }

    context 'when the request is rate limited' do
      let(:error) { { error: 'Request was throttled' } }
      let(:headers) { { 'Content-Type' => 'application/json' } }

      before do
        stub_request(:get, api_path('mailboxes'))
          .to_return(status: 429, body: error.to_json, headers: headers)
      end

      it 'raises an API::ThrottleLimitReached error with no retry_after' do
        expect { subject }.to raise_error(HelpScout::API::ThrottleLimitReached, error[:error]) do |exception|
          expect(exception.retry_after).to be_nil
        end
      end

      context 'when the response includes a Retry-After header' do
        let(:headers) { { 'Content-Type' => 'application/json', 'Retry-After' => '30' } }

        it 'raises an API::ThrottleLimitReached error with retry_after in seconds' do
          expect { subject }.to raise_error(HelpScout::API::ThrottleLimitReached, error[:error]) do |exception|
            expect(exception.retry_after).to eq 30
          end
        end
      end

      context 'when the Retry-After header is malformed' do
        let(:headers) { { 'Content-Type' => 'application/json', 'Retry-After' => 'later' } }

        it 'raises an API::ThrottleLimitReached error with no retry_after' do
          expect { subject }.to raise_error(HelpScout::API::ThrottleLimitReached, error[:error]) do |exception|
            expect(exception.retry_after).to be_nil
          end
        end
      end
    end
  end
end
