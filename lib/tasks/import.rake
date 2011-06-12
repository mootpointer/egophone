
namespace :egophone do
  
  task :reset => :environment do
    Person.destroy_all
    Message.destroy_all
  end

  namespace :dbs do
    desc 'Import all data from given DB path'
    task :import, [:db_path] => :environment do |t, args|
      Rake::Task["rake:egophone:people:import"].invoke("#{args.db_path}/AddressBook/AddressBook.sqlitedb")
      Rake::Task["rake:egophone:messages:import"].invoke("#{args.db_path}/SMS/sms.db")
    end
  end


  namespace :people do
    desc 'Import all people from the given db'
    task :import, [:db_path] => :environment do |t, args|
      puts "Importing People..."
      db = SQLite3::Database.new(args.db_path)
      db.execute("SELECT First,Last,value FROM ABPerson INNER JOIN ABMultiValue ON record_id = ROWID WHERE property = 3") do |row|
        person = Person.find_or_initialize_by(name:"#{row[0]} #{row[1]}")
        person.phone_numbers << row[2]
        person.save!
      end
    end
  end
  namespace :messages do
    
    desc 'Import all messages from the given db'
    task :import, [:db_path] => :environment do |t, args|
      puts 'Importing Messages...'
      db = SQLite3::Database.new(args.db_path)
      db.execute("SELECT address,date,text,country,flags from message WHERE flags in (2,3)") do |row|
        direction = {2 => :in, 3 => :out}
        if row[0]
          m = Message.new(:phone => row[0], 
                         :sent => Time.at(row[1]).to_datetime, 
                         :direction => direction[row[4]], 
                         :country => row[3],
                         :text => row[2])
          m.normalize
          person = Person.where(phone_numbers: m.phone).first || Person.create(:phone_numbers => [row[0]], :name => m.phone)
          person.messages << m
        end
      end
    end
  end
end
