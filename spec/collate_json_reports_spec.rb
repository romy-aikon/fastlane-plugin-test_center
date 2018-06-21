
require 'json'

json_report_1 = File.open('./spec/fixtures/report.json')
json_report_2 = File.open('./spec/fixtures/report-2.json')

describe Fastlane::Actions::CollateJsonReportsAction do
  before(:each) do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:open).and_call_original
  end

  describe 'it handles invalid data' do
    it 'a failure occurs when non-existent JSON file is specified' do
      fastfile = "lane :test do
        collate_json_reports(
          reports: ['path/to/non_existent_json_report.json'],
          collated_report: 'path/to/report.json'
        )
      end"
      expect { Fastlane::FastFile.new.parse(fastfile).runner.execute(:test) }.to(
        raise_error(FastlaneCore::Interface::FastlaneError) do |error|
          expect(error.message).to match("Error: JSON report not found: 'path/to/non_existent_json_report.json'")
        end
      )
    end
  end

  describe 'it handles valid data' do
    it 'simply copies a :reports value containing one report' do
      fastfile = "lane :test do
        collate_json_reports(
          reports: ['path/to/fake_json_report.json'],
          collated_report: 'path/to/report.json'
        )
      end"
      allow(File).to receive(:exist?).with('path/to/fake_json_report.json').and_return(true)
      allow(File).to receive(:open).with('path/to/fake_json_report.json').and_yield(File.open('./spec/fixtures/report.json'))
      expect(FileUtils).to receive(:cp).with('path/to/fake_json_report.json', 'path/to/report.json')
      Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
    end

    it 'contains only the tests that failed in the last report' do
      fastfile = "lane :test do
        collate_json_reports(
          reports: ['path/to/fake_json_report_1.json', 'path/to/fake_json_report_2.json'],
          collated_report: 'path/to/report.json'
        )
      end"

      allow(File).to receive(:exist?).with('path/to/fake_json_report_1.json').and_return(true)
      allow(File).to receive(:new).with('path/to/fake_json_report_1.json').and_return(json_report_1)
      allow(File).to receive(:exist?).with('path/to/fake_json_report_2.json').and_return(true)
      allow(File).to receive(:new).with('path/to/fake_json_report_2.json').and_return(json_report_2)
      allow(FileUtils).to receive(:mkdir_p)

      report_file = StringIO.new
      expect(File).to receive(:open).with('path/to/report.json', 'w').and_yield(report_file)

      Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
      report_json = JSON.parse(report_file.string)
      expect(report_json['tests_failures'].keys.size).to eq(1)
    end
  end
end
