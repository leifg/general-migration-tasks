require 'optparse'
require 'sequel'
require 'sqlite3'
require 'csv'

def setup_table(database, table_name, headers)
  modified_headers = [:row_count] + headers
  database.create_table!(table_name) do
    modified_headers.each do |column|
      String column
    end
  end
end

def insert(database, table_name, row, index)
  modified_row = row.map do |key, value|
    [Sequel.identifier(key), value]
  end.to_h
  database[table_name].insert(modified_row.merge(row_count: index + 1))
end

options = {
  encoding: 'UTF-8',
  col_sep: ','
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
  $stdout.puts("Reading CSV for #{table_name}")
  csv_table = CSV.read(
    file,
    headers: true,
    header_converters: :symbol,
    col_sep: options[:col_sep],
    encoding: options[:encoding]
  )
  $stdout.puts("Importing #{table_name}")
  setup_table(db, table_name, csv_table.headers)
  csv_table.each_with_index do |row, index|
    insert(db, table_name, row, index)
  end
end
