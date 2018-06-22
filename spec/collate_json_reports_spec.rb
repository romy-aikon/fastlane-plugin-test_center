
require 'json'

json_report_1 = File.open('./spec/fixtures/report.json')
json_report_2 = File.open('./spec/fixtures/report-2.json')

describe Fastlane::Actions::CollateJsonReportsAction do
  before(:each) do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:open).and_call_original
    json_report_1.rewind
    json_report_2.rewind
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
      allow(File).to receive(:read).with('path/to/fake_json_report_1.json').and_return(json_report_1.read)
      allow(File).to receive(:exist?).with('path/to/fake_json_report_2.json').and_return(true)
      report_2 = json_report_2.read
      json_2 = JSON.parse(report_2)
      allow(File).to receive(:read).with('path/to/fake_json_report_2.json').and_return(report_2)
      allow(FileUtils).to receive(:mkdir_p)

      collated_report_file = StringIO.new
      expect(File).to receive(:open).with('path/to/report.json', 'w').and_yield(collated_report_file)

      Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
      report_json = JSON.parse(collated_report_file.string)
      expect(report_json['tests_failures']).to eq(json_2['tests_failures'])
    end

    it 'warnings from both report files are collated' do
      fastfile = "lane :test do
        collate_json_reports(
          reports: ['path/to/fake_json_report_1.json', 'path/to/fake_json_report_2.json'],
          collated_report: 'path/to/report.json'
        )
      end"

      allow(File).to receive(:exist?).with('path/to/fake_json_report_1.json').and_return(true)
      allow(File).to receive(:read).with('path/to/fake_json_report_1.json').and_return(json_report_1.read)
      allow(File).to receive(:exist?).with('path/to/fake_json_report_2.json').and_return(true)
      allow(File).to receive(:read).with('path/to/fake_json_report_2.json').and_return(json_report_2.read)
      allow(FileUtils).to receive(:mkdir_p)

      collated_report_file = StringIO.new
      expect(File).to receive(:open).with('path/to/report.json', 'w').and_yield(collated_report_file)

      Fastlane::FastFile.new.parse(fastfile).runner.execute(:test)
      report_json = JSON.parse(collated_report_file.string)
      expect(report_json["warnings"]).to eq(
        [
          "not all that glitters is gold!",
          "there is a chance of snow tomorrow",
          "trust and verify"
        ]
      )
    end
  end
end
