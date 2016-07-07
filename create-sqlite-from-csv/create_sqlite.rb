require 'optparse'
require 'sequel'
require 'sqlite3'
require 'csv'

def setup_table(database, table_name, headers)
  database.create_table!(table_name) do
    headers.each do |column|
      String column
    end
  end
end

options = {
  encoding: 'UTF-8',
  col_sep: ',',
}
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-dDatabase', '--db=db', 'output DB File') do |v|
    options[:db] = v
  end

  opts.on('-fFiles', '--files=files', 'input CSV files') do |v|
    options[:files] = Dir["#{v}/*.csv"]
  end

  opts.on('-eEncoding', '--encoding=encoding', 'encoding of CSV files') do |v|
    options[:encoding] = v
  end

  opts.on('-cColSep', '--col_sep=col_sep', 'column separator') do |v|
    options[:col_sep] = v
  end
end.parse!

db_filename = options[:db]
db = Sequel.connect("sqlite://#{db_filename}")
#
options[:files].each do |file|
  table_name = File.basename(file, File.extname(file)).to_sym
  csv_table = CSV.read(
    file,
    headers: true,
    header_converters: :symbol,
    col_sep: options[:col_sep],
    encoding: options[:encoding]
  )
  setup_table(db, table_name, csv_table.headers)
  $stdout.puts("importing #{table_name}")
  csv_table.each do |row|
    db[table_name].insert(row.to_h)
  end
end
