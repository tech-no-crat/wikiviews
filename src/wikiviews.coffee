# stats.grok.se will give wikipedia view counts for a single month.
# The exported function makes multiple requests, one for each month
# in the given month range and combines the returned data.
fs = require 'fs'
request = require 'request'

baseURL = "http://stats.grok.se/json/en"

# Pads a number to a given number of leading zeroes
# Hacky: Only works for up to 5 leading zeroes
pad = (num, size) -> ('00000' + num).substr(-size)

# Generates a string of the format "YYYYMM" for a given year/month
monthString = (year, month) -> year.toString() + pad(month.toString(), 2)

# The function to be exported:
run = (article, start, end, resultsCb) ->
  openCalls = 0 # The number of external requests we've made that have not returned yet
  result = {} # Date --> views mapping

  # Makes a request for the given year and month
  # calls the callback with the parsed response
  makeRequest = (year, month, cb) ->
    openCalls += 1

    request "#{baseURL}/#{monthString(year, month)}/#{article}",
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

  # Returns the result to the callback
  returnResult = ->
    resultsCb(result) if typeof resultsCb == "function"

  # Returns the result if openCalls is zero
  # otherwise waits 500ms and tries again
  returnResultIfReady = ->
    if openCalls == 0
      returnResult()
    else
      setTimeout(returnResultIfReady, 500)


  # Find the starting/ending month/year
  startYear = parseInt start.substring(0, 4)
  startMonth = parseInt start.substring(4, 6)
  endYear = parseInt end.substring(0, 4)
  endMonth = parseInt end.substring(4, 6)

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

  returnResultIfReady()

module.exports = run
