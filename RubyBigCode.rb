# Processing Russian Troll data from fivethirtyeight.com
require 'csv'

# There are non-UTF8 characters. This seems to make it so that we can read
# all of the files. I have no idea what this does with characters it can't read.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

def count_troll_types(filename)
  # read the text of the whole file
  csv_text = File.read(filename)
  # now parse the file, assuming it has a header row at the top
  csv = CSV.parse(csv_text, :headers => true)

  # These are the header categories
  # You can get more information about each category if you scroll
  # down to the README.md here:
  # https://github.com/fivethirtyeight/russian-troll-tweets
  '''
  external_author_id
  author
  content
  region
  language
  publish_date
  harvested_date
  following
  followers
  updates
  post_type
  account_type
  new_june_2018
  retweet
  account_category
  '''

  # map from categories to the number of tweets in category
  categories = Hash.new
  # go through each row of the csv file
  csv.each do |row|
    # convert the row to a hash
    # the keys of the hash will be the headers from the csv file
    hash = row.to_hash
    # this is a trick to make sure that this key exists in a hash
    # so that the next line which adds 1 will never fail
    if !categories.include? hash['account_category']
      categories[hash['account_category']] = 0
    end
    # This cannot fail because if the key hadn't existed,
    # then the previous if will have created it
    categories[hash['account_category']] += 1
  end
  # now print the key/value pairs
  categories.each do |key, value|
    puts "#{key} occurs #{value} times"
  end
end

def ten_most_tweeted_days(filename)  #BASIC QUESTION #1
  csv_text = File.read(filename)
  csv = CSV.parse(csv_text, :headers => true)
  categories = Hash.new
  csv.each do |row|
    hash = row.to_hash
    #only capture the actual date. By splitting on spaces and taking first
    #index, we are cutting the time off.
    hash['publish_date'] = hash['publish_date'].split[0]
    if !categories.include? hash['publish_date']
      categories[hash['publish_date']] = 0
    end
    categories[hash['publish_date']] += 1 #count num tweets on each unique day
  end
  most_tweeted = []
  num_tweets = []
  10.times do |hash| #get the 10 most common
    day, tweets = categories.max_by{|k,v| v} #found from stack overflow to return key, value based on value
    most_tweeted << day #probably not best way, but a way  to store day and num tweets
    num_tweets << tweets
    categories.delete(day) #delete so we can get second most common
  end
  puts "The 10 days in which the most tweets were sent were:"
  10.times do |day| #output the results
    puts "#{most_tweeted[day]}, #{num_tweets[day]} tweets were made that day."
  end
end

def most_tweeted_hour(filename)
  csv_text = File.read(filename)
  csv = CSV.parse(csv_text, :headers => true)
  categories = Hash.new
  csv.each do |row|
    hash = row.to_hash #going through each row, and adding new interesting values as keys to categories
    #get the hour, delete colon if it exists. Since hour could be one or two digits, we ensure just numbers
    hash['publish_date'] = hash['publish_date'].split[1].chars[0..1].join.delete(":")
    if !categories.include? hash['publish_date'] #really only checking hour now
      categories[hash['publish_date']] = 0       #add the row's value as a key.
      # The hash of the row uses the headers as keys, but categories uses the values as keys
    end
    categories[hash['publish_date']] += 1 #increment the value assigned to the key. For example, the date
  end
  #get the highest value from hash, which means the most tweets were in that
  #hour, since each tweet in the specified hour is how we increment the value.
  hour = categories.key(categories.values.max)
  puts "The hour with the most tweets was: #{hour}:00"
end

def most_common_word(filename)
  csv_text = File.read(filename)
  csv = CSV.parse(csv_text, :headers => true)
  categories = Hash.new
  csv.each do |row|
    hash = row.to_hash
    text = hash['content'].split #want to look at each word in the content
    text.each do |word| #for each word in the content
      if !categories.include? word #add the word if not already. Not looking at hash this time.
        categories[word] = 0
      end
      categories[word] += 1 #increment the number of times we have seen the word
    end
  end
  #returning the key with the highest value. Each instance of the most_common_word
  #increases the value, so we get most common word
  word, num = categories.max_by{|k,v| v}
  puts "The most used word of the tweets was \"#{word}\". It occurs #{num} times."
end
'''
HOW MANY ADVANCED QUESTIONS ARE WE SUPPOSED TO ANSWER
'''
#Wanted to figure out if the time of day influenced when different types of accounts tweeted
def common_time_by_account_type(filename)
  csv_text = File.read(filename)   #just reading the file like starter code
  csv = CSV.parse(csv_text, :headers => true)
  categories = Hash.new
  account_types = []
  csv.each do |row|
    hash = row.to_hash
    #get the hour things were published
    hash['publish_date'] = hash['publish_date'].split[1].chars[0..1].join.delete(":")
    if !categories.include? hash['account_category'] #for each account type
      #key is an array, create new one. So store the respective hour that the
      #tweet was published for each account type. Added to an array
      categories[hash['account_category']] = []
      #store the types of accounts we found, because we go through this later
      #but wouldn't know what accounts to look for. Storing the key for later lookup
      account_types << hash['account_category']
    end
    categories[hash['account_category']] << hash['publish_date'] #add the time
  end
  account_types.each do |type| #for each account type, return most common hour in array
    hours = categories[type] #get the contens, the array of hours, from the hash
    #method found from stack overflow to get the most common object in an array
    freq = hours.inject(Hash.new(0)) { |k,v| k[v] += 1; k }
    common_hour = hours.max_by { |v| freq[v] } #max_by again, finding max val from hash
    puts "#{type} accounts tweeted most at #{common_hour}:00." #output
  end
end

def most_common_category_by_month(filename)
  csv_text = File.read(filename)   #just reading the file like starter code
  csv = CSV.parse(csv_text, :headers => true)
  categories = Hash.new
  csv.each do |row|
    hash = row.to_hash
    #get the month and year something was tweeted
    month = hash['publish_date'].split[0].split("/")[0] #month tweeted
    year = hash['publish_date'].split[0].split("/")[2]  #year most_tweeted
    hash['publish_date'] = month + "/" + year #update publish date
    if !categories.include? hash['publish_date'] #if no tweets found on this publish date yet, add to hash
      categories[hash['publish_date']] = {} #the value of the date will be a map of category type to count
    end
    if !categories[hash['publish_date']].include? hash['account_category'] #only add to the value hash if not already
      categories[hash['publish_date']][hash['account_category']] = 0
    end
    categories[hash['publish_date']][hash['account_category']] += 1 #increment
  end
  #GO THROUGH EACH DATE AND GET MOST COMMON account_category
  categories.each do |k, v| #for every month
    cat, num = v.max_by{|key, val| val} #finding most common account category for that month
    puts "In the month of #{k}, #{cat} account types tweeted the most, tweeting #{num} times."
  end
end


count_troll_types("tweets.csv")
ten_most_tweeted_days("tweets.csv")
most_tweeted_hour("tweets.csv")
most_common_word("tweets.csv")
common_time_by_account_type("tweets.csv")
most_common_category_by_month("tweets.csv")