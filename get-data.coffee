fs = require 'fs'
request = require 'request'
config = require './config.json'

# Override some config parameters with command line arguments, if they are there
if process.argv.length > 2
  config.article = process.argv[2]
if process.argv.length > 3
  config.filename = process.argv[3]

openCalls = 0 # The number of external requests we've made that have not returned yet
result = {} # Date --> views mapping

# Pads a number to a given number of leading zeroes
# Hacky: Only works for up to 5 leading zeroes
pad = (num, size) -> ('00000' + num).substr(-size)

# Generates a string of the format "YYYYMM" for a given year/month
monthString = (year, month) -> year.toString() + pad(month.toString(), 2)

# Makes a request for the given year and month
# calls the callback with the parsed response
makeRequest = (year, month, cb) ->
  openCalls += 1

  request "#{config.baseURL}/#{monthString(year, month)}/#{config.article}",
  (err, resp, body) ->
    if err or resp.statusCode != 200
      cb("Request failed, got err #{err} and status #{(!resp)?-1:resp.statusCode}", null)
    else
      try
        parsedResp = JSON.parse(body)
      catch e
        cb("Invalid JSON: #{e}", null)
      cb(null, parsedResp) if parsedResp
    openCalls -= 1

# Writes result to config.filename as a CSV
writeResult = ->
  lines = []
  for date, views of result
    lines.push "#{date}, #{views}"
  fs.writeFile config.filename, lines.join("\n"), (err) ->
    return console.log(err) if err

# Writes result if openCalls is zero
# otherwise waits 500ms and tries again
writeResultIfReady = ->
  if openCalls == 0
    writeResult()
  else
    setTimeout(writeResultIfReady, 500)


# Find the starting/ending month/year
startYear = parseInt config.start.substring(0, 4)
startMonth = parseInt config.start.substring(4, 6)
endYear = parseInt config.end.substring(0, 4)
endMonth = parseInt config.end.substring(4, 6)

month = startMonth; year = startYear;
loop # for all months from the starting to the ending date
  makeRequest year, month, (err, res) ->
    if err
      return console.log "Error in request for #{monthString(year, month)}: #{err}"
    result[date] = views for date, views of res.daily_views
  
  # Coffeescript has no do-while loops, so we are doing this:
  break if month == endMonth and year == endYear
  month += 1
  if month > 12
    month = 1
    year++ 

writeResultIfReady()
