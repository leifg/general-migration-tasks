require 'optparse'
require 'sequel'
require 'sqlite3'
require 'csv'

def inital_setup_table(database, record_type)
  database.create_table?(record_type) do
    String :job_id
    String :action
    String :id
    String :created
    String :success
    String :error_type
    String :error_message
  end
end

def create_columns?(database, table_name, columns)
  missing_columns = columns - database[table_name].columns - [:error]
  database.alter_table(table_name) do
    missing_columns.each do |column|
      add_column column, String
    end
  end
end

def transform_row(row)
  error = row.delete(:error)
  if error
    error_type, error_message = error.split(':', 2)
    row.merge(error_type: error_type, error_message: error_message)
  else
    row
  end
end

def insert(database, record_type, action, job_id, row)
  changed_row = transform_row(row)

  row_to_insert = changed_row.map do |key, value|
    [Sequel.identifier(key), value]
  end.to_h.merge(action: action, job_id: job_id)

  database[record_type].insert(row_to_insert)
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
end.parse!

db_filename = options[:db]
db = Sequel.connect("sqlite://#{db_filename}")

options[:files].each do |file|
  puts "importing file: #{file.inspect}"
  record_type, action, job_id = File
                                 .basename(file, '.csv')
                                 .scan(/(.*)_((?:delete)|(?:insert)|(?:update)|(?:upsert)|(?:query))_(\w+)/)
                                 .flatten

  table_name = Sequel.identifier(record_type.downcase.to_sym)
  inital_setup_table(db, table_name)

  csv_table = CSV.read(
    file,
    headers: true,
    header_converters: :symbol,
    encoding: options[:encoding]
  )

  create_columns?(db, table_name, csv_table.headers)

  csv_table.each do |row|
    insert(db, table_name, action, job_id, row.to_h)
  end
end
