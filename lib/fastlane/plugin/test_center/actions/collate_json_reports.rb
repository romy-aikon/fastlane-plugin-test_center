module Fastlane
  module Actions
    class CollateJsonReportsAction < Action
      require 'json'

      def self.run(params)
        report_filepaths = params[:reports]
        if report_filepaths.size == 1
          FileUtils.cp(report_filepaths[0], params[:collated_report])
        else
          base_report_json = JSON.parse(File.read(report_filepaths.shift))
          report_filepaths.each do |report_file|
            report_json = JSON.parse(File.read(report_file))
            merge_reports(base_report_json, report_json)
          end
          File.open(params[:collated_report], 'w') do |f|
            f.write(base_report_json.to_json)
          end
        end
      end

      def self.merge_reports(base_report, other_report)
        base_report.keys.each do |key|
          unless %w(tests_failures tests_summary_messages).include?(key)
            base_report[key].concat(other_report[key])
          end
          base_report["tests_failures"] = other_report["tests_failures"]
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Combines and combines tests from multiple json report files"
      end

      def self.details
        "The first JSON report is used as the base report. Due to the nature of " \
        "xcpretty JSON reports, only the failing test cases are recorded. " \
        "Testcases that failed in previous reports that no longer appear in " \
        "later reports are assumed to have passed in a re-run, thus not appearing " \
        "in the collated report. " \
        "This is done because it is assumed that fragile tests, when " \
        "re-run will often succeed due to less interference from other " \
        "tests and the subsequent JSON reports will have fewer failing tests." \
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :reports,
            env_name: 'COLLATE_JSON_REPORTS_REPORTS',
            description: 'An array of JSON reports to collate. The first report is used as the base into which other reports are merged in',
            optional: false,
            type: Array,
            verify_block: proc do |reports|
              UI.user_error!('No JSON report files found') if reports.empty?
              reports.each do |report|
                UI.user_error!("Error: JSON report not found: '#{report}'") unless File.exist?(report)
              end
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :collated_report,
            env_name: 'COLLATE_JSON_REPORTS_COLLATED_REPORT',
            description: 'The final JSON report file where all testcases will be merged into',
            optional: true,
            default_value: 'result.json',
            type: String
          )
        ]
      end

      def self.example_code
        [
          "
          UI.important(
            'example: ' \\
            'collate the json reports to a temporary file \"result.json\"'
          )
          reports = Dir['../spec/fixtures/report*.json'].map { |relpath| File.absolute_path(relpath) }
          collate_json_reports(
            reports: reports,
            collated_report: File.join(Dir.mktmpdir, 'result.json')
          )
          "
        ]
      end

      def self.authors
        ["lyndsey-ferguson/@lyndseydf"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
