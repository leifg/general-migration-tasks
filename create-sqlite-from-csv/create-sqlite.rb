require "sequel"
require "sqlite3"
require "csv"

def setup_table(database, table_name, headers)
  database.create_table!(table_name) do
    headers.each do |column|
      String column
    end
  end
end

db_filename = ENV["DB_FILE_NAME"]
db = Sequel.connect("sqlite://#{db_filename}")

ARGV.each do |file|
  table_name = File.basename(file,File.extname(file)).to_sym
  csv_table = CSV.read(file, headers: true, header_converters: :symbol)
  setup_table(db, table_name, csv_table.headers)
  $stdout.puts("importing #{table_name}")
  csv_table.each do |row|
    db[table_name].insert(row.to_h)
  end
end
